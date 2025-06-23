#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/fsleyes")"


# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old FSLeyes installation..." && rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing fsleyes ..."
pixi init ${INSTALL_PREFIX} && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "fsleyes>=1.15" && \
pixi install --manifest-path ${INSTALL_PREFIX}/pixi.toml

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
FILE_LIST=$(grep -v "_path" $(ls ${INSTALL_PREFIX}/.pixi/envs/default/conda-meta/fsleyes*) | grep -o "bin/.*[A-Z|a-z|0-9]")
while IFS='' read -r p; do
    ln -s ${INSTALL_PREFIX}/.pixi/envs/default/${p} ${INSTALL_PREFIX}/${p}
done < <(printf '%s\n' "$FILE_LIST")

if [ "$OS_TYPE" == "macos" ]; then
    # Put app to /Applications folder
    echo "Creating symlink for FSLeyes.app in /Applications ..."
    if [[ -d /Applications/FSLeyes.app || -L /Applications/FSLeyes.app ]]; then rm /Applications/FSLeyes.app; fi
    ln -s ${INSTALL_PREFIX}/.pixi/envs/default/share/fsleyes/FSLeyes.app /Applications/FSLeyes.app
fi

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# FSLeyes
export PATH=\"${INSTALL_ROOT_PREFIX}/fsleyes/bin:\${PATH}\"
# Note: to use this version of fsleyes
# above lines should be put after FSL related lines
"
