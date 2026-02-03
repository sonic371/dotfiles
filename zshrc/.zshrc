#!/usr/bin/env zsh
# Main ZSH configuration file
# Sources all modular configuration files from ~/.zsh/

# ============================================================================
# SOURCE MODULAR CONFIGURATION FILES
# ============================================================================
# A list of configuration files to source, in order.
zsh_config_files=(
  env.zsh
  plugins.zsh
  aliases.zsh
  functions.zsh
  options.zsh
  dotfiles.zsh
  ssh.zsh
  key-bindings.zsh
  swap-ralt.zsh
)

# Source each configuration file if it exists.
for file in "${zsh_config_files[@]}"; do
  if [[ -f "$HOME/.zsh/$file" ]]; then
    source "$HOME/.zsh/$file"
  fi
done
