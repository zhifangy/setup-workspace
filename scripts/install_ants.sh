#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/ants")"


# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old ANTs installation..." && rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing ants ..."
pixi init ${INSTALL_PREFIX} && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "ants>=2.6.2" && \
pixi install --manifest-path ${INSTALL_PREFIX}/pixi.toml

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
FILE_LIST=$(grep -v "_path" $(ls ${INSTALL_PREFIX}/.pixi/envs/default/conda-meta/ants*) | grep -o "bin/.*[A-Z|a-z|0-9]")
while IFS='' read -r p; do
    ln -s ${INSTALL_PREFIX}/.pixi/envs/default/${p} ${INSTALL_PREFIX}/${p}
done < <(printf '%s\n' "$FILE_LIST")

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# ANTs
export ANTSPATH=\"${INSTALL_ROOT_PREFIX}/ants/bin\"
export PATH=\"\${ANTSPATH}:\${PATH}\"
"
