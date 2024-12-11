#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
export MAMBA_ROOT_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/micromamba")"
export \
    CONDA_ENVS_DIRS="${MAMBA_ROOT_PREFIX}/envs" \
    CONDA_PKGS_DIRS="${MAMBA_ROOT_PREFIX}/pkgs" \
    CONDA_CHANNELS="conda-forge,HCC"
export UV_ROOT_DIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/uv")"
export \
    UV_PYTHON_INSTALL_DIR="${UV_ROOT_DIR}/python" \
    UV_TOOL_DIR="${UV_ROOT_DIR}/tool" \
    UV_CACHE_DIR="${UV_ROOT_DIR}/cache"
export PY_LIBS="$(eval "echo ${INSTALL_ROOT_PREFIX}/pyenv")"
export PYTHON_VERSION="3.12"


if [ "$OS_TYPE" == "macos" ]; then
# Install packages
formula_packages=("micromamba" "uv" "ruff")
for package in "${formula_packages[@]}"; do
    brew list --formula "${package}" &> /dev/null || brew install "${package}"
done


elif [ "$OS_TYPE" == "rhel8" ]; then
# Check Micromamba installation
command -v micromamba &> /dev/null || { echo "Error: Mircomamba is not installed or not included in the PATH." >&2; exit 1; }
# Check uv installation
command -v uv &> /dev/null || { echo "Error: uv is not installed or not included in the PATH." >&2; exit 1; }
# Check if R is installed and in the PATH
if ( ! echo "$PATH" | tr ':' '\n' | grep -q "$(eval "echo ${INSTALL_ROOT_PREFIX}/r/bin")" ) || ( ! command -v R &> /dev/null ); then
    echo "ERROR: R is not installed or presents in the PATH (required by rpy2)."
    exit 1
fi
fi

# Install uv-managed python
uv python install ${PYTHON_VERSION}

eval "$(micromamba shell hook --shell bash --root-prefix ${MAMBA_ROOT_PREFIX})"
# Cleanup old python environment
if [ $(micromamba env list | grep -c ${PY_LIBS}) -ne 0 ]; then
    echo "Cleanup old environment ${PY_LIBS}..."
    micromamba env remove -p ${PY_LIBS} -yq
elif [ -d ${PY_LIBS} ]; then
    echo "Cleanup old environment ${PY_LIBS}..."
    rm -rf ${PY_LIBS}
fi

# Create python environment
micromamba create -yq -p ${PY_LIBS} && micromamba activate ${PY_LIBS}
# create venv (PEP 405 compliant) via UV in the environment directory
uv venv --allow-existing --seed --python ${PYTHON_VERSION} ${PY_LIBS}

# Install packages in venv via UV
uv pip install -r ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml --extra full
# special treatment for brainstat
uv pip install -r ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml --extra brainstat_deps
uv pip install -r ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml --extra brainstat_nodeps --no-deps

# Cleanup
micromamba clean -yaq
uv cache clean

# Add following lines into .zshrc
if [ "$OS_TYPE" == "macos" ]; then
echo "
Add following lines to .zshrc:

# Micromamba
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE=\"\$(brew --prefix micromamba)/bin/micromamba\";
export MAMBA_ROOT_PREFIX=\"${INSTALL_ROOT_PREFIX}/micromamba\";
__mamba_setup=\"\$(\"\$MAMBA_EXE\" shell hook --shell zsh --root-prefix \"\$MAMBA_ROOT_PREFIX\" 2> /dev/null)\"
if [ \$? -eq 0 ]; then
    eval \"\$__mamba_setup\"
else
    alias micromamba=\"\$MAMBA_EXE\"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
# configuration
export \\
    CONDA_ENVS_DIRS=\"\${MAMBA_ROOT_PREFIX}/envs\" \\
    CONDA_PKGS_DIRS=\"\${MAMBA_ROOT_PREFIX}/pkgs\" \\
    CONDA_CHANNELS=\"conda-forge,HCC\"

# UV
export UV_ROOT_DIR=\"${INSTALL_ROOT_PREFIX}/uv\"
export \\
    UV_PYTHON_INSTALL_DIR=\"\${UV_ROOT_DIR}/python\" \\
    UV_TOOL_DIR=\"\${UV_ROOT_DIR}/tool\" \\
    UV_CACHE_DIR=\"\${UV_ROOT_DIR}/cache\"

# Python environment
export PY_LIBS=\"${INSTALL_ROOT_PREFIX}/pyenv\"
micromamba activate \$PY_LIBS

Execute following lines:
source ~/.zshrc
"

elif [ "$OS_TYPE" == "rhel8" ]; then
echo "
Add following lines to .zshrc:

# Python environment
export PY_LIBS=\"${INSTALL_ROOT_PREFIX}/pyenv\"
micromamba activate \$PY_LIBS

Execute following lines:
source ~/.zshrc
"
fi
