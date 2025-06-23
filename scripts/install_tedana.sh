#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/tedana")"


# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing tedata ..."
pixi init ${INSTALL_PREFIX} && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "python=3.12.*" && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml --pypi "tedana>=25.0" && \
pixi install --manifest-path ${INSTALL_PREFIX}/pixi.toml

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
ln -s ${INSTALL_PREFIX}/.pixi/envs/default/bin/tedana ${INSTALL_PREFIX}/bin/tedana
ln -s ${INSTALL_PREFIX}/.pixi/envs/default/bin/ica_reclassify ${INSTALL_PREFIX}/bin/ica_reclassify
ln -s ${INSTALL_PREFIX}/.pixi/envs/default/bin/t2smap ${INSTALL_PREFIX}/bin/t2smap

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# Tedana
export PATH=\"${INSTALL_ROOT_PREFIX}/tedana/bin:\${PATH}\"
"
