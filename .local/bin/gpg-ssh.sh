#!/bin/bash
set -e

# Prompt for name and email
read -p "Enter name: " NAME
read -p "Enter email: " EMAIL

# Ensure gpg-agent is set up for SSH
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
touch ~/.gnupg/gpg-agent.conf  # Ensure gpg-agent.conf file exists
grep -q "enable-ssh-support" ~/.gnupg/gpg-agent.conf 2>/dev/null || echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf

# Get the fingerprint of an existing key for the provided email, if any
FPR=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}' | head -n1 || true)

if [ -z "$FPR" ]; then
    echo "No existing key for $EMAIL, creating a new GPG key..."
    gpg --quick-generate-key "$NAME <$EMAIL>" ed25519 cert 0
    FPR=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}' | head -n1)
fi

echo "Using fingerprint: $FPR"

# Add an authentication subkey (2 years expiry)
gpg --quick-add-key "$FPR" ed25519 auth 2y

# Get keygrip of the authentication subkey
AUTH_KEYGRIP=$(gpg -K --with-keygrip "$FPR" | awk '/Keygrip/ {print $3}' | tail -n1)

# Whitelist the keygrip in sshcontrol
echo "$AUTH_KEYGRIP" >> ~/.gnupg/sshcontrol

# Restart the gpg-agent to apply changes
gpgconf --kill gpg-agent

# Export SSH public key for GitHub
PUBKEY=$(gpg --export-ssh-key "$FPR")

echo
echo "=== SSH PUBLIC KEY (add this to GitHub) ==="
echo "$PUBKEY"
echo "=========================================="
echo
echo "Tip: Add the following to your shell config (~/.bashrc or ~/.zshrc):"
echo 'export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"'

