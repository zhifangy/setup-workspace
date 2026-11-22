#!/bin/bash
set -e

# Init environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/scripts/utils.sh" && init_setup
# Set environment variables
N_CPUS=${N_CPUS:-8}

case "$1" in
    "systools")
        if [ "$OS_TYPE" == "macos" ]; then
            brew upgrade --greedy && brew cleanup
        elif [ "$OS_TYPE" == "rhel8" ]; then
            pixi global update systools
        fi
        ;;
    "omz"|"oh-my-zsh")
        zsh -ic "upgrade_oh_my_zsh_all"
        ;;
    "pyenv")
        pixi update --manifest-path ${PY_LIBS} --environment default && \
        pixi install --manifest-path ${PY_LIBS} --environment default
        ;;
    "pyenv-dryrun")
        pixi update --manifest-path ${PY_LIBS} --environment default --dry-run
        ;;
    "renv")
        Rscript -e "
        options(Ncpus=${N_CPUS})
        options(repos=c(CRAN=Sys.getenv('CRAN'), CRAN_SOURCE=Sys.getenv('CRAN_SOURCE')))
        old_pkgs <- old.packages(lib.loc=Sys.getenv('R_LIBS'), repos=Sys.getenv('CRAN'))
        if (!is.null(old_pkgs)) {
            pkgs <- rownames(old_pkgs)
            # rebuild packages that pak installed from source (e.g., 'pkg?source') from source again
            plat <- installed.packages(lib.loc=Sys.getenv('R_LIBS'), fields='RemotePkgPlatform')[pkgs, 'RemotePkgPlatform']
            pkgs[plat %in% 'source'] <- paste0(pkgs[plat %in% 'source'], '?source')
            pak::meta_update();
            pak::pkg_install(pkgs, lib=\"${R_LIBS}\", upgrade=TRUE);
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
    "ants")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/ants/pixi.toml") ants && \
        pixi install --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/ants/pixi.toml")
        ;;
    "tedana")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/tedana/pixi.toml") tedana && \
        pixi install --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/tedana/pixi.toml")
        ;;
    "cubids")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/cubids/pixi.toml") cubids deno && \
        pixi install --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/cubids/pixi.toml")
        ;;
    "fsleyes")
        pixi update --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/fsleyes/pixi.toml") fsleyes && \
        pixi install --manifest-path $(eval "echo ${INSTALL_ROOT_PREFIX}/fsleyes/pixi.toml")
        ;;
    *)
        echo "Invalid installation option."
        exit 1
        ;;
esac
