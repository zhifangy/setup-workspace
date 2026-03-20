#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/freesurfer")"
FREESURFER_VERSION=${FREESURFER_VERSION:-8.2.0}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then
    # backup license.txt from existed FreeSurfer folder
    if [ -f ${INSTALL_PREFIX}/license.txt ]; then
        echo "Backup FreeSurfer license from existed installation ..."
        cp ${INSTALL_PREFIX}/license.txt $(eval "echo ${INSTALL_ROOT_PREFIX}")/license.txt
    fi
    echo "Cleanup old FreeSurfer installation ..."
    rm -rf ${INSTALL_PREFIX}
fi

# Install
echo "Installing FreeSurfer from offical website..."
mkdir -p ${INSTALL_PREFIX}


if [ "$OS_TYPE" == "macos" ]; then
wget -qO "${INSTALL_PREFIX}/freesurfer-macOS-darwin_arm64-${FREESURFER_VERSION}.pkg" \
    "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${FREESURFER_VERSION}/freesurfer-macOS-darwin_arm64-${FREESURFER_VERSION}.pkg"
# unpack pkg to a tmp directory
mkdir -p ${INSTALL_PREFIX}/fs_install
7zz e ${INSTALL_PREFIX}/freesurfer-macOS-darwin_arm64-${FREESURFER_VERSION}.pkg freesurfer.pkg/Payload -so | \
    gunzip -dc | \
    (cd ${INSTALL_PREFIX}/fs_install && cpio -idm)
mv ${INSTALL_PREFIX}/fs_install/freesurfer/${FREESURFER_VERSION}/* ${INSTALL_PREFIX}
# clean up
rm -r ${INSTALL_PREFIX}/fs_install
rm ${INSTALL_PREFIX}/freesurfer-macOS-darwin_arm64-${FREESURFER_VERSION}.pkg
# put app to /Applications folder
if [[ -d /Applications/Freeview.app || -L /Applications/Freeview.app ]]; then rm /Applications/Freeview.app; fi
ln -s ${INSTALL_PREFIX}/Freeview.app /Applications/Freeview.app


elif [ "$OS_TYPE" == "rhel8" ]; then
wget -qO "${INSTALL_PREFIX}/freesurfer-Rocky8-${FREESURFER_VERSION}.x86_64.rpm" \
    "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${FREESURFER_VERSION}/freesurfer-Rocky8-${FREESURFER_VERSION}-1.x86_64.rpm"
# unpack rpm contents to a tmp directory
mkdir -p /tmp/fs_install
rpm2cpio ${INSTALL_PREFIX}/freesurfer-Rocky8-${FREESURFER_VERSION}.x86_64.rpm | cpio -idm -D /tmp/fs_install
mv /tmp/fs_install/usr/local/freesurfer/${FREESURFER_VERSION}-1/* ${INSTALL_PREFIX}
# clean up
rm -r /tmp/fs_install
rm ${INSTALL_PREFIX}/freesurfer-Rocky8-${FREESURFER_VERSION}.x86_64.rpm

fi

# Move previous license.txt to new FreeSurfer folder
if [ -f $(eval "echo ${INSTALL_ROOT_PREFIX}")/license.txt ]; then
    echo "Move previous FreeSurfer license to new installation ..."
    mv $(eval "echo ${INSTALL_ROOT_PREFIX}")/license.txt ${INSTALL_PREFIX}/license.txt
else
    echo "Use default personal FreeSurfer license ..."
    base64 --decode <<<  emhpZmFuZy55ZS5mZ2htQGdtYWlsLmNvbQozMDgyNwogKkNBanR5YkNZNDByTQogRlM5dmVNeDhnbnVxUQo= > ${INSTALL_PREFIX}/license.txt
fi

# Add following lines into .zshrc
echo "
Add following line to .zshrc
This should be put after FSL setups.

# FreeSurfer
export FREESURFER_HOME=\"${INSTALL_ROOT_PREFIX}/freesurfer\"
export \\
    OS=$(uname -s) \\
    FS_OVERRIDE=0 \\
    FSFAST_HOME=\${FREESURFER_HOME}/fsfast \\
    SUBJECTS_DIR=\${FREESURFER_HOME}/subjects \\
    FUNCTIONALS_DIR=\${FREESURFER_HOME}/sessions \\
    MINC_BIN_DIR=\${FREESURFER_HOME}/mni/bin \\
    MNI_DIR=\${FREESURFER_HOME}/mni \\
    MINC_LIB_DIR=\${FREESURFER_HOME}/mni/lib \\
    MNI_DATAPATH=\${FREESURFER_HOME}/mni/data \\
    FSL_DIR=\${FSLDIR} \\
    LOCAL_DIR=\${FREESURFER_HOME}/local \\
    FSF_OUTPUT_FORMAT=nii.gz \\
    FMRI_ANALYSIS_DIR=\${FREESURFER_HOME}/fsfast \\
    MNI_PERL5LIB=\${FREESURFER_HOME}/mni/Library/Perl/Updates/5.12.3 \\
    PERL5LIB=\${FREESURFER_HOME}/mni/Library/Perl/Updates/5.12.3 \\
    FSL_BIN=\${FSLDIR}/share/fsl/bin \\
    FREESURFER=\${FREESURFER_HOME} \\
    FIX_VERTEX_AREA= \\
    FS_LICENSE=\${FREESURFER_HOME}/license.txt \\
    FREESURFER_HOME_FSPYTHON=\${FREESURFER_HOME}
export PATH=\"\${FREESURFER_HOME}/bin:\${FSFAST_HOME}/bin:\${FREESURFER_HOME}/tktools:\${MINC_BIN_DIR}:\${PATH}\"
"
