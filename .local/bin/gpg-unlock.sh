GPG_STATUS=$(echo "test" | gpg --detach-sign --armor --status-fd 1 2>/dev/null | grep "^\[GNUPG:SIG_CREATED]")

if [ -z "$GPG_STATUS" ]; then
    gpg --decrypt --passphrase-fd 0 < /dev/null > /dev/null 2>/dev/null
fi
