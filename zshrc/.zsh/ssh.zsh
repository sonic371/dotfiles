# ============================================================================
# SSH AGENT SETUP
# ============================================================================
if command -v keychain >/dev/null 2>&1; then
    # Tell keychain which keys to manage
    keychain --quiet ~/.ssh/id_ed25519

    # Source keychain environment variables
    # Keychain writes these into ~/.keychain/$HOST-sh
    if [ -f "$HOME/.keychain/$HOST-sh" ]; then
        source "$HOME/.keychain/$HOST-sh"
    fi
fi
