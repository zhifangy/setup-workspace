#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/workbench")"
WORKBENCH_VERSION=${WORKBENCH_VERSION:-2.2.1}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing Workbench from humanconnectome.org..."
mkdir -p ${INSTALL_PREFIX}


if [ "$OS_TYPE" == "macos" ]; then
wget -q https://www.humanconnectome.org/storage/app/media/workbench/ConnectomeWorkbench.v${WORKBENCH_VERSION}.dmg \
    -P ${INSTALL_PREFIX}
7zz x ${INSTALL_PREFIX}/ConnectomeWorkbench.v${WORKBENCH_VERSION}.dmg -o"${INSTALL_PREFIX}/" > /dev/null

# Put app to /Applications folder
if [[ -d /Applications/ConnectomeWorkbench.app || -L /Applications/ConnectomeWorkbench.app ]]; then rm /Applications/ConnectomeWorkbench.app; fi
ln -s ${INSTALL_PREFIX}/ConnectomeWorkbench.app /Applications/ConnectomeWorkbench.app

# Cleanup
rm ${INSTALL_PREFIX}/ConnectomeWorkbench.v${WORKBENCH_VERSION}.dmg

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# HCP Workbench
export PATH=\"${INSTALL_ROOT_PREFIX}/workbench/ConnectomeWorkbench.app/Contents/usr/bin:\${PATH}\"
"


elif [ "$OS_TYPE" == "rhel8" ]; then
wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-rh_linux64-v${WORKBENCH_VERSION}.zip \
    -P ${INSTALL_PREFIX}
unzip -q -o -d ${INSTALL_PREFIX}/tmp ${INSTALL_PREFIX}/workbench-rh_linux64-v${WORKBENCH_VERSION}.zip
mv ${INSTALL_PREFIX}/tmp/workbench/* ${INSTALL_PREFIX}

# Cleanup
rm ${INSTALL_PREFIX}/workbench-rh_linux64-v${WORKBENCH_VERSION}.zip
rm -r ${INSTALL_PREFIX}/tmp

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# HCP Workbench
export PATH=\"${INSTALL_ROOT_PREFIX}/workbench/bin_rh_linux64:\${PATH}\"
"
fi
