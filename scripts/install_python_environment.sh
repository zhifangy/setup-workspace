#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
export PY_LIBS="$(eval "echo ${INSTALL_ROOT_PREFIX}/pyenv")"


# Check Pixi installation
command -v pixi &> /dev/null || { echo "Error: Pixi is not installed or not included in the PATH." >&2; exit 1; }

# Cleanup old python environment
if [ -d ${PY_LIBS} ]; then
    echo "Cleanup old environment ${PY_LIBS}..."
    rm -rf ${PY_LIBS}
fi

# Create python environment
mkdir -p ${PY_LIBS} && cp ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml ${PY_LIBS}/.
(cd ${PY_LIBS} && pixi install)

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# Python environment
export PY_LIBS=\"${INSTALL_ROOT_PREFIX}/pyenv\"
# emulate pixi activate
export PIXI_PROJECT_ROOT=\"\${PY_LIBS}\"
export PIXI_PROJECT_MANIFEST=\"\${PY_LIBS}/pyproject.toml\"
export CONDA_PREFIX="\${PY_LIBS}/.pixi/envs/default"
export CONDA_DEFAULT_ENV="pyenv"
export CONDA_PROMPT_MODIFIER="pyenv"
# add to PATH
export PATH=\"\${CONDA_PREFIX}/bin:\${PATH}\"

Execute following lines:
source ~/.zshrc
"
