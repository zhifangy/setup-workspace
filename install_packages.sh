#!/bin/bash
set -e

# Init environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/scripts/utils.sh" && init_setup
# Set environment variables
N_CPUS=${N_CPUS:-8}

case "$1" in
    "systools")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_system_packages.sh
        ;;
    "omz"|"oh-my-zsh")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_oh_my_zsh.sh
        ;;
    "texlive")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_texlive.sh
        ;;
    "r")
        if [ "$OS_TYPE" == "macos" ]; then
            bash ${SCRIPT_ROOT_PREFIX}/scripts/install_r_cran.sh
        elif [ "$OS_TYPE" == "rhel8" ]; then
            bash ${SCRIPT_ROOT_PREFIX}/scripts/install_r_source.sh
        fi
        ;;
    "pyenv")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_python_environment.sh
        ;;
    "renv")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_r_environment.sh
        ;;
    "freesurfer")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_freesurfer.sh
        ;;
    "afni")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_afni.sh
        ;;
    "fsl")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_fsl.sh
        ;;
    "other")
        pixi global install ants
        pixi global install fsleyes
        pixi global install dcm2niix
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_mricrogl.sh
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_surfice.sh
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_itksnap.sh
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_workbench.sh
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_convert3d.sh
        ;;
    "dcm2niix")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_dcm2niix.sh
        ;;
    "ants")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_ants.sh
        ;;
    "tedana")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_tedana.sh
        ;;
    "fsleyes")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_fsleyes.sh
        ;;
    "mricrogl")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_mricrogl.sh
        ;;
    "surfice")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_surfice.sh
        ;;
    "itksnap")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_itksnap.sh
        ;;
    "workbench")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_workbench.sh
        ;;
    "convert3d")
        bash ${SCRIPT_ROOT_PREFIX}/scripts/install_convert3d.sh
        ;;
    *)
        echo "Unsupported installation option."
        exit 1
        ;;
esac
