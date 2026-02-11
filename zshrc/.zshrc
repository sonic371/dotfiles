#!/usr/bin/env zsh
# Main ZSH configuration file
# Sources all modular configuration files from ~/.zsh/

# ============================================================================
# SOURCE MODULAR CONFIGURATION FILES
# ============================================================================
# A list of configuration files to source, in order.
zsh_config_files=(
  env.zsh
  oh-my-zsh.zsh
  fzf-integration.zsh
  zoxide-integration.zsh
  aliases.zsh
  functions.zsh
  options.zsh
  dotfiles.zsh
  ssh.zsh
  swap-ralt.zsh
)

# Source each configuration file if it exists.
for file in "${zsh_config_files[@]}"; do
  if [[ -f "$HOME/.zsh/$file" ]]; then
    source "$HOME/.zsh/$file"
  fi
done
