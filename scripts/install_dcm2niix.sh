#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/dcm2niix")"


# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old Dcm2niix installation..." && rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing dcm2niix ..."
pixi init ${INSTALL_PREFIX} && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "dcm2niix>=1.0.20250506" && \
pixi install --manifest-path ${INSTALL_PREFIX}/pixi.toml

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
FILE_LIST=$(grep -v "_path" $(ls ${INSTALL_PREFIX}/.pixi/envs/default/conda-meta/dcm2niix*) | grep -o "bin/.*[A-Z|a-z|0-9]")
while IFS='' read -r p; do
    ln -s ${INSTALL_PREFIX}/.pixi/envs/default/${p} ${INSTALL_PREFIX}/${p}
done < <(printf '%s\n' "$FILE_LIST")

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# Dcm2niix
export PATH=\"${INSTALL_ROOT_PREFIX}/dcm2niix/bin:\${PATH}\"
"
