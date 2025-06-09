#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/workbench")"
WORKBENCH_VERSION=${WORKBENCH_VERSION:-v2.1.0}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing Workbench from humanconnectome.org..."
mkdir -p ${INSTALL_PREFIX}


if [ "$OS_TYPE" == "macos" ]; then
wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-macub-${WORKBENCH_VERSION}.zip \
    -P ${INSTALL_PREFIX}
unzip -q -d ${INSTALL_PREFIX} ${INSTALL_PREFIX}/workbench-macub-${WORKBENCH_VERSION}.zip
mv ${INSTALL_PREFIX}/workbench/* ${INSTALL_PREFIX}

# Put app to /Applications folder
if [[ -d /Applications/Workbench.app || -L /Applications/Workbench.app ]]; then rm /Applications/Workbench.app; fi
ln -s ${INSTALL_PREFIX}/macosxub_apps/wb_view.app /Applications/Workbench.app

# Cleanup
rm ${INSTALL_PREFIX}/workbench-macub-${WORKBENCH_VERSION}.zip
rm -r ${INSTALL_PREFIX}/workbench

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# HCP Workbench
export PATH=\"${INSTALL_ROOT_PREFIX}/workbench/bin_macosxub:\${PATH}\"
"


elif [ "$OS_TYPE" == "rhel8" ]; then
wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-rh_linux64-${WORKBENCH_VERSION}.zip \
    -P ${INSTALL_PREFIX}
unzip -q -o -d ${INSTALL_PREFIX}/tmp ${INSTALL_PREFIX}/workbench-rh_linux64-${WORKBENCH_VERSION}.zip
mv ${INSTALL_PREFIX}/tmp/workbench/* ${INSTALL_PREFIX}

# Cleanup
rm ${INSTALL_PREFIX}/workbench-rh_linux64-${WORKBENCH_VERSION}.zip
rm -r ${INSTALL_PREFIX}/tmp

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# HCP Workbench
export PATH=\"${INSTALL_ROOT_PREFIX}/workbench/bin_rh_linux64:\${PATH}\"
"
fi
