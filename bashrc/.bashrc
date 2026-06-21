#!/usr/bin/env bash
# Main Bash configuration file
# Sources all modular configuration files from ~/.bash/

# ============================================================================
# SOURCE MODULAR CONFIGURATION FILES
# ============================================================================
# A list of configuration files to source, in order.
bash_config_files=(
  env.bash
  paths.bash
  fzf-integration.bash
  zoxide-integration.bash
  aliases.bash
  functions.bash
  options.bash
  vi-mode.bash
  prompt.bash
  dotfiles.bash
  ssh.bash
)

# Source each configuration file if it exists.
# We assume they are in ~/.bash/ if sourced from home, 
# but for the dotfiles repo we use the local path.
BASH_CONF_DIR="${BASH_SOURCE%/*}/.bash"

for file in "${bash_config_files[@]}"; do
  if [[ -f "$BASH_CONF_DIR/$file" ]]; then
    source "$BASH_CONF_DIR/$file"
  fi
done

