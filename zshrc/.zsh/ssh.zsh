# ============================================================================
# SSH AGENT SETUP
# ============================================================================
if command -v keychain >/dev/null 2>&1; then
    # Only start keychain if no SSH agent is already running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(keychain --eval --quiet id_ed25519)"
    fi
fi
