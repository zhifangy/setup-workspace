#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup


if [ "$OS_TYPE" == "macos" ]; then
# Install Homebrew
if [ -x "/opt/homebrew/bin/brew" ]; then
    echo "Homebrew is already installed."
    # check if /opt/homebrew/bin is in the PATH
    if ! echo "$PATH" | grep -q "/opt/homebrew/bin"; then
        echo "However, /opt/homebrew/bin is not in the \$PATH."
        echo "Temporarily adding it to \$PATH. Please modify the shell profile file to make it persistent."
        PATH="/opt/homebrew/bin:${PATH}"
    fi
else
    echo "Homebrew is not installed. Installing Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages
# private tap
brew tap rundel/quarto-cli
# install yq for parsing yaml format
brew list --formula yq &> /dev/null || brew install yq
# formula packages
dep_formulas=($(yq '.dependencies.formulas[]' ${SCRIPT_ROOT_PREFIX}/misc/systools_macos.yml))
# cask packages
dep_casks=($(yq '.dependencies.casks[]' ${SCRIPT_ROOT_PREFIX}/misc/systools_macos.yml))
# get installed packages
installed_formulas=$(brew list --formula --full-name)
installed_casks=$(brew list --cask --full-name)
# find the missing packages
missing_formulas=()
missing_casks=()
for p in "${dep_formulas[@]}"; do
    if ! echo "${installed_formulas}" | grep -q "^${p}\(@.*\)*$"; then
        missing_formulas[${#missing_formulas[@]}]="${p}"
    fi
done
for p in "${dep_casks[@]}"; do
    if ! echo "${installed_casks}" | grep -q "^${p}\(@.*\)*$"; then
        missing_casks[${#missing_casks[@]}]="${p}"
    fi
done
# install missing packages if any
if [ "${#missing_formulas[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_formulas[*]} ..."
    brew install "${missing_formulas[@]}"
fi
if [ "${#missing_casks[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_casks[*]} ..."
    brew install --cask "${missing_casks[@]}"
fi

# Cleanup
brew cleanup

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# Homebrew
eval \"\$(/opt/homebrew/bin/brew shellenv)\"
FPATH=\"\$(brew --prefix)/share/zsh/site-functions:\${FPATH}\"

# Starship
eval \"\$(starship init zsh)\"

# bat
export BAT_THEME=\"Dracula\"

# fzf
# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# The fuck
eval \"\$(thefuck --alias)\"

# Alias
# lsd
alias ll=\"lsd -l\"
alias la=\"lsd -a\"
alias lla=\"lsd -la\"
alias lt=\"lsd --tree\"
alias llsize=\"lsd -l --total-size\"
# fzf
alias preview=\"fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'\"
"


elif [ "$OS_TYPE" == "rhel8" ]; then
# Set environment variables
export PIXI_HOME="$(eval "echo ${INSTALL_ROOT_PREFIX}/pixi")"
export \
    PIXI_CACHE_DIR="${PIXI_HOME}/cache" \
    PIXI_NO_PATH_UPDATE=1
SYSTOOLS_DIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/pixi/envs/systools")"

# Install Pixi
if [ -x "${PIXI_HOME}/bin/pixi" ]; then
    echo "Pixi is already installed. Try self-update ..."
    pixi self-update --no-release-note
    # check if ${PIXI_HOME}/bin is in the PATH
    if ! echo "$PATH" | grep -q "${PIXI_HOME}/bin"; then
        echo "However, ${PIXI_HOME}/bin is not in the \$PATH."
        echo "Temporarily adding it to \$PATH. Please modify the shell profile file to make it persistent."
        PATH="${PIXI_HOME}/bin:${PATH}"
    fi
else
    echo "Installing Pixi ..."
    curl -fsSL https://pixi.sh/install.sh | bash
    PATH="${MAMBA_ROOT_PREFIX}/bin:${PATH}"
fi

# Cleanup old installation
if [ -d ${SYSTOOLS_DIR} ]; then
    echo "Cleanup old environment ${SYSTOOLS_DIR}..."
    rm -rf ${SYSTOOLS_DIR}
fi

# Read package list
# temporarily install yq for parsing yaml format
pixi global install go-yq
mapfile -t pkgs < <(yq -r '.dependencies[]' ${SCRIPT_ROOT_PREFIX}/misc/systools_rhel8.yml)
# Read channel list
mapfile -t tmp < <(yq -r '.channels[]' ${SCRIPT_ROOT_PREFIX}/misc/systools_rhel8.yml)
channels=()
for channel in "${tmp[@]}"; do
    # Add the '-c' flag as one element...
    channels+=("-c")
    channels+=("$channel")
done
# remove yq to avoid conflict with systools environment
pixi global uninstall go-yq

# Create systools environment
echo "System tools enviromenmet location: ${SYSTOOLS_DIR}"
pixi global install -e systools ${pkgs[@]} ${channels[@]}
# copy activate and deactivate script
cp ${SCRIPT_ROOT_PREFIX}/scripts/activate_systools.sh ${SYSTOOLS_DIR}/.
cp ${SCRIPT_ROOT_PREFIX}/scripts/deactivate_systools.sh ${SYSTOOLS_DIR}/.

# Cleanup
pixi clean cache -y

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# Pixi
export PIXI_HOME=\"${INSTALL_ROOT_PREFIX}/pixi\"
export PIXI_CACHE_DIR=\"\${PIXI_HOME}/cache\"
export PATH=\"\${PIXI_HOME}/bin:\${PATH}\"
eval \"\$(pixi completion --shell zsh)\"

# Systools
export SYSTOOLS_ENV=\"systools\"
export SYSTOOLS_DIR=\"${INSTALL_ROOT_PREFIX}/pixi/envs/\${SYSTOOLS_ENV}\"

# Compiler configuration
source \${SYSTOOLS_DIR}/activate_systools.sh
export LD_LIBRARY_PATH=\"\${SYSTOOLS_DIR}/lib:\${SYSTOOLS_DIR}/x86_64-conda-linux-gnu/sysroot/usr/lib64:\${LD_LIBRARY_PATH}\"
export PKG_CONFIG_PATH=\"\${SYSTOOLS_DIR}/lib/pkgconfig:\${PKG_CONFIG_PATH}\"

# bat
export BAT_THEME=\"Dracula\"

# fzf
# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Direnv
eval \"\$(direnv hook zsh)\"

# UV
export UV_ROOT_DIR=\"${INSTALL_ROOT_PREFIX}/uv\"
export \\
    UV_PYTHON_INSTALL_DIR=\"\${UV_ROOT_DIR}/python\" \\
    UV_TOOL_DIR=\"\${UV_ROOT_DIR}/tool\" \\
    UV_CACHE_DIR=\"\${UV_ROOT_DIR}/cache\"
# autocompletion
eval \"\$(uv generate-shell-completion zsh)\"

# Alias
# lsd
alias ll=\"lsd -l\"
alias la=\"lsd -a\"
alias lla=\"lsd -la\"
alias lt=\"lsd --tree\"
alias llsize=\"lsd -l --total-size\"
# fzf
alias preview=\"fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'\"
"
fi
