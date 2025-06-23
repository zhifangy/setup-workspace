#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/itksnap")"
ITKSNAP_VERSION=${ITKSNAP_VERSION:-4.2.2}
ITKSNAP_DATE=${ITKSNAP_DATE:-20241202}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing ITK-SNAP from SourceForge..."
mkdir -p ${INSTALL_PREFIX}


if [ "$OS_TYPE" == "macos" ]; then
wget -q https://sourceforge.net/projects/itk-snap/files/itk-snap/${ITKSNAP_VERSION}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg \
    -P ${INSTALL_PREFIX}
7zz x ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg -o"${INSTALL_PREFIX}/" \
    itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64/ITK-SNAP.app > /dev/null
mv ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64/ITK-SNAP.app ${INSTALL_PREFIX}/ITK-SNAP.app

# Put app to /Applications folder
if [[ -d /Applications/ITK-SNAP.app || -L /Applications/ITK-SNAP.app ]]; then rm /Applications/ITK-SNAP.app; fi
ln -s ${INSTALL_PREFIX}/ITK-SNAP.app /Applications/ITK-SNAP.app

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
bin_list=("greedy" "greedy_template_average" "itksnap" "itksnap-wt" "multi_chunk_greedy")
for p in "${bin_list[@]}"; do
    ln -s ${INSTALL_PREFIX}/ITK-SNAP.app/Contents/bin/${p} ${INSTALL_PREFIX}/bin/${p}
done

# Cleanup
rm ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg
rm -r ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64


elif [ "$OS_TYPE" == "rhel8" ]; then
wget -q https://downloads.sourceforge.net/project/itk-snap/itk-snap/${ITKSNAP_VERSION}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Linux-x86_64.tar.gz \
    -P ${INSTALL_PREFIX}
tar -xzf ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Linux-x86_64.tar.gz -C ${INSTALL_PREFIX} --no-same-owner --no-same-permissions
mv ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Linux-x86_64/* ${INSTALL_PREFIX}
# fix libQt*.so files
# see https://github.com/microsoft/WSL/issues/3023#issuecomment-372933586
find ${INSTALL_PREFIX} -name 'libQt*.so*' | xargs strip --remove-section=.note.ABI-tag

# Cleanup
rm ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Linux-x86_64.tar.gz
rm -r ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Linux-x86_64
fi

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# ITKSNAP
export PATH=\"${INSTALL_ROOT_PREFIX}/itksnap/bin:\${PATH}\"
"
