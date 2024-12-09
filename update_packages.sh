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
            micromamba update -a -p ${SYSTOOLS_DIR} && micromamba clean -yaq
        fi
        ;;
    "omz"|"oh-my-zsh")
        zsh -ic "upgrade_oh_my_zsh_all"
        ;;
    "pyenv")
        uv pip install -r ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml -U --extra full
        uv cache clean
        ;;
    "pyenv-dryrun")
        uv pip install -r ${SCRIPT_ROOT_PREFIX}/misc/pyproject.toml -U --dry-run --extra full
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
        update_fsl_release
        ;;
    "fsleyes")
        micromamba update fsleyes -p "$(eval "echo ${INSTALL_ROOT_PREFIX}/fsleyes/env")" -c conda-forge
        ;;
    "ants")
        micromamba update ants -p "$(eval "echo ${INSTALL_ROOT_PREFIX}/ants/env")" -c conda-forge
        ;;
    "dcm2niix")
        micromamba update dcm2niix -p "$(eval "echo ${INSTALL_ROOT_PREFIX}/dcm2niix/env")" -c conda-forge
        ;;
    *)
        echo "Invalid installation option."
        exit 1
        ;;
esac
