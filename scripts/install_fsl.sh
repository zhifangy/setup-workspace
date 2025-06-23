#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/fsl")"
FSL_VERSION=${FSL_VERSION:-6.0.7.18}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old FSL installation..." && rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing FSL from offical website..."
mkdir -p ${INSTALL_PREFIX}
wget -q https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py -P ${INSTALL_PREFIX}
chmod +x ${INSTALL_PREFIX}/fslinstaller.py
${INSTALL_PREFIX}/fslinstaller.py -V ${FSL_VERSION} -d ${INSTALL_PREFIX} -o --no_env --skip_registration

# Use newer version of MSM
if [ "$OS_TYPE" == "macos" ]; then
    wget -q https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_mac_v3 -O ${INSTALL_PREFIX}/share/fsl/bin/msm
elif [ "$OS_TYPE" == "rhel8" ]; then
    wget -q https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_centos_v3 -O ${INSTALL_PREFIX}/share/fsl/bin/msm
fi
chmod 755 ${INSTALL_PREFIX}/share/fsl/bin/msm

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# FSL
export FSLDIR=\"${INSTALL_ROOT_PREFIX}/fsl\"
export \\
    FSLOUTPUTTYPE=NIFTI_GZ \\
    FSLMULTIFILEQUIT=TRUE \\
    FSLTCLSH=\${FSLDIR}/bin/fsltclsh \\
    FSLWISH=\${FSLDIR}/bin/fslwish \\
    FSLGECUDAQ=cuda.q \\
    FSLLOCKDIR= \\
    FSLMACHINELIST= \\
    FSLREMOTECALL= \\
    FSL_LOAD_NIFTI_EXTENSIONS=0 \\
    FSL_SKIP_GLOBAL=0
export PATH=\"\${FSLDIR}/share/fsl/bin:\${PATH}\"
"
