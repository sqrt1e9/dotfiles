#!/bin/bash
set -e

read -p "Enter name: " NAME
read -p "Enter email: " EMAIL

# Ensure gpg-agent is set up for ssh
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
grep -q "enable-ssh-support" ~/.gnupg/gpg-agent.conf 2>/dev/null || echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf

# Get fingerprint of existing key for this email, if any
FPR=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}' | head -n1 || true)

if [ -z "$FPR" ]; then
    echo "No existing key for $EMAIL, creating new GPG key..."
    gpg --quick-generate-key "$NAME <$EMAIL>" ed25519 cert 0
    FPR=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}' | head -n1)
fi

echo "Using fingerprint: $FPR"

# Add auth subkey (2 years expiry)
gpg --quick-add-key "$FPR" ed25519 auth 2y

# Get keygrip of the auth subkey
AUTH_KEYGRIP=$(gpg -K --with-keygrip "$FPR" | awk '/Keygrip/ {print $3}' | tail -n1)

# Whitelist in sshcontrol
echo "$AUTH_KEYGRIP" >> ~/.gnupg/sshcontrol

# Restart agent
gpgconf --kill gpg-agent

# Export SSH public key
PUBKEY=$(gpg --export-ssh-key "$FPR")

echo
echo "=== SSH PUBLIC KEY (add this to GitHub) ==="
echo "$PUBKEY"
echo "=========================================="
echo
echo "Tip: add this to your shell config (~/.bashrc or ~/.zshrc):"
echo 'export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"'

