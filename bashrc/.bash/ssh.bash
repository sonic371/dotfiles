# ============================================================================
# SSH AGENT SETUP (on-demand)
# ============================================================================
# Start the SSH agent and load keys only when needed.
# Run `ssh-init` on first use after reboot.
if command -v keychain >/dev/null 2>&1; then
    # If keychain already has a running agent, source its env vars silently.
    # Otherwise do nothing — run `ssh-init` to start it.
    if [ -z "$SSH_AUTH_SOCK" ] && [ -f "$HOME/.keychain/$HOSTNAME-sh" ]; then
        source "$HOME/.keychain/$HOSTNAME-sh" 2>/dev/null || true
        # If the sourced agent is actually dead, clean up
        if [ -n "$SSH_AGENT_PID" ] && ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            unset SSH_AUTH_SOCK SSH_AGENT_PID
        fi
    fi
fi

# On-demand function to start the agent and load keys
ssh-init() {
    if command -v keychain >/dev/null 2>&1; then
        eval "$(keychain --eval --quiet id_ed25519)"
        echo "SSH agent started and key loaded"
    else
        echo "keychain not installed" >&2
        return 1
    fi
}
