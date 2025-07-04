#!/bin/bash
set -e

# Init environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/scripts/utils.sh" && init_setup
# Set environment variables
N_CPUS=${N_CPUS:-8}

case "$1" in
    "systools")
        if [ "$OS_TYPE" == "macos" ]; then
            brew upgrade && brew cleanup
        elif [ "$OS_TYPE" == "rhel8" ]; then
            pixi global update systools
        fi
        ;;
    "omz"|"oh-my-zsh")
        zsh -ic "upgrade_oh_my_zsh_all"
        ;;
    "pyenv")
        pixi update --manifest-path ${PY_LIBS}/pyproject.toml --environment default
        ;;
    "pyenv-dryrun")
        pixi update --manifest-path ${PY_LIBS}/pyproject.toml --environment default --dry-run
        ;;
    "renv")
        Rscript -e "
        options(Ncpus=${N_CPUS})
        old_pkgs <- old.packages(lib.loc=Sys.getenv('R_LIBS'), repos=Sys.getenv('CRAN'))
        if (!is.null(old_pkgs)) {
            pak::meta_update();
            pak::pkg_install(rownames(old_pkgs), lib=\"${R_LIBS}\", upgrade=TRUE);
            pak::cache_clean()
        } else {
            cat('No package needs to be updated.\n');
        }
        "
        ;;
    "renv-dryrun")
        Rscript -e "
        old_pkgs <- old.packages(lib.loc=Sys.getenv('R_LIBS'), repos=Sys.getenv('CRAN'))
        if (!is.null(old_pkgs)) {
            print(old_pkgs)
        } else {
            cat('No package needs to be updated.\n');
        }
        "
        ;;
    "texlive")
        tlmgr update --self --all
        ;;
    "fsl")
        ${FSLDIR}/bin/update_fsl_release
        ;;
    "dcm2niix")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/dcm2niix/pixi.toml")
        ;;
    "ants")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/ants/pixi.toml")
        ;;
    "tedana")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/tedana/pixi.toml")
        ;;
    "fsleyes")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/fsleyes/pixi.toml")
        ;;
    *)
        echo "Invalid installation option."
        exit 1
        ;;
esac
