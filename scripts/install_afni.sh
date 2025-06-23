#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/afni")"
R_LIBS="${R_LIBS:-$(eval "echo ${INSTALL_ROOT_PREFIX}/renv")}"
N_CPUS=${N_CPUS:-8}
if [ "$OS_TYPE" == "macos" ]; then
    PKG_VERSION=macos_13_ARM
    BUILD_DIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/afni_build")"
elif [ "$OS_TYPE" == "rhel8" ]; then
    PKG_VERSION=linux_rocky_8
    SYSTOOLS_DIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/systools")"
fi
export PATH="${INSTALL_PREFIX}:${PATH}"

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old AFNI installation..." && rm -rf ${INSTALL_PREFIX}; fi
if [ -d ${BUILD_DIR} ]; then echo "Cleanup old AFNI build directory..." && rm -rf ${BUILD_DIR}; fi
if [ -d ~/.afni/help ]; then echo "Cleanup old AFNI help files ..." && rm -rf ~/.afni/help; fi
if [ -f ~/.afnirc ]; then echo "Cleanup old AFNI rc files ..." && rm ~/.afnirc; fi
if [ -f ~/.sumarc ]; then echo "Cleanup old SUMA rc files ..." && rm ~/.sumarc; fi

# Install R dependencies
Rscript -e "
options(Ncpus=${N_CPUS})
# Install packages
deps <- c('afex', 'phia', 'snow', 'nlme', 'lmerTest', 'gamm4', 'data.table', 'paran', 'psych', 'corrplot', 'metafor')
missing_pkgs <- setdiff(deps, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  pak::pkg_install(missing_pkgs, lib=\"${R_LIBS}\");
}
# Cleanup cache
pak::cache_clean()
"


if [ "$OS_TYPE" == "macos" ]; then
# Install system dependencies via homebrew
# see https://github.com/afni/afni/blob/master/src/other_builds/OS_notes.macos_12_ARM_a_admin_pt1.zsh
deps_formula=(
    "libpng" "jpeg" "expat" "freetype" "fontconfig" "openmotif" "libomp" "gsl" "glib" "pkgconf" \
    "gcc" "libiconv" "autoconf" "libxt" "mesa" "mesa-glu" "libxpm"
)
deps_cask=("xquartz")
# get installed packages
installed_formulas=$(brew list --formula --full-name)
installed_casks=$(brew list --cask --full-name)
# find the missing packages
missing_formulas=()
missing_casks=()
for p in "${deps_formula[@]}"; do
    if ! echo "${installed_formulas}" | grep -q "^${p}\(@.*\)*$"; then
        missing_formulas[${#missing_formulas[@]}]="${p}"
    fi
done
for p in "${deps_cask[@]}"; do
    if ! echo "${installed_casks}" | grep -q "^${p}\(@.*\)*$"; then
        missing_casks[${#missing_casks[@]}]="${p}"
    fi
done
# install missing packages if any
if [ "${#missing_formulas[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_formulas[*]} ..."
    brew install "${missing_formulas[@]}"
fi
if [ "${#missing_casks[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_casks[*]} ..."
    brew install --cask "${missing_casks[@]}"
fi

# Install AFNI
echo "Installing AFNI from source code (building for apple aarch64)..."
curl -s https://afni.nimh.nih.gov/pub/dist/bin/misc/@update.afni.binaries | \
    tcsh -s - -no_recur -package anyos_text_atlas -bindir ${INSTALL_PREFIX}
build_afni.py -abin ${INSTALL_PREFIX} -build_root ${BUILD_DIR} -package ${PKG_VERSION} -do_backup no
# post installation setup
cp ${INSTALL_PREFIX}/AFNI.afnirc ${HOME}/.afnirc
suma -update_env
apsearch -update_all_afni_help
afni_system_check.py -check_all

# Cleanup
if [ -f .R.Rout ]; then rm .R.Rout; fi
rm -rf ${BUILD_DIR}

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# AFNI
export AFNI_DIR=\"${INSTALL_ROOT_PREFIX}/afni\"
export PATH=\"\${AFNI_DIR}:\${PATH}\"
# command completion
if [ -f \${HOME}/.afni/help/all_progs.COMP.zsh ]; then source \${HOME}/.afni/help/all_progs.COMP.zsh; fi
# look for shared libraries under flat_namespace
export DYLD_LIBRARY_PATH=\"\${DYLD_LIBRARY_PATH}:/opt/X11/lib/flat_namespace\"
# do not log commands
export AFNI_DONT_LOGFILE=YES
"


elif [ "$OS_TYPE" == "rhel8" ]; then
# Install dependency package into systools environment
deps_pkgs=(
    "openmotif" "gsl" "netpbm" "libjpeg-turbo" "libpng" "libglu" "xorg-libxpm" \
    "xorg-libxi" "glib2-conda-x86_64" "mesa-libglw-devel-cos7-x86_64" "xorg-x11-server-xvfb-conda-x86_64"
)
installed_pkgs=$(yq ".envs.${SYSTOOLS_ENV}.dependencies | keys | .[]" ${PIXI_HOME}/manifests/pixi-global.toml)
missing_pkgs=()
for p in "${deps_pkgs[@]}"; do
    if ! echo "${installed_pkgs}" | grep -q "^${p}$"; then
        missing_pkgs[${#missing_pkgs[@]}]="${p}"
    fi
done
if [ ${#missing_pkgs[@]} -ne 0 ]; then
    echo "Installing missing dependencies: ${missing_pkgs[*]} ..."
    pixi global install -e systools "${missing_pkgs[@]}"
    pixi clean cache -y
fi
# install openssl 1.0.2 for Xvfb
mkdir -p ${INSTALL_PREFIX}/deps/openssl_build
wget -O - https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2u/openssl-1.0.2u.tar.gz \
    | tar -xz --strip-components=1 -C "${INSTALL_PREFIX}/deps/openssl_build"
OLD_DIR=$(pwd) && cd ${INSTALL_PREFIX}/deps/openssl_build
./config --prefix=${INSTALL_PREFIX}/deps/OpenSSL_1_0_2u \
    --openssldir=${INSTALL_PREFIX}/deps/OpenSSL_1_0_2u shared zlib-dynamic > /dev/null
make -s -j 4 > /dev/null && make -s install > /dev/null
cd ${OLD_DIR}
rm -rf ${INSTALL_PREFIX}/deps/openssl_build
# symlink OpenSSL libraries for LD_LIBRARY_PATH
mkdir -p ${INSTALL_PREFIX}/deps/lib
ln -s ${INSTALL_PREFIX}/deps/lib/OpenSSL_1_0_2u/lib/libcrypto.so.1.0.0 ${INSTALL_PREFIX}/deps/lib/libcrypto.so.10
ln -s ${INSTALL_PREFIX}/deps/lib/OpenSSL_1_0_2u/lib/libssl.so.1.0.0 ${INSTALL_PREFIX}/deps/lib/libssl.so.10
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${INSTALL_PREFIX}/deps/lib"
# symlink Xvfb binary
mkdir -p ${INSTALL_PREFIX}/deps/bin
ln -s ${SYSTOOLS_DIR}/x86_64-conda-linux-gnu/sysroot/usr/bin/Xvfb ${INSTALL_PREFIX}/deps/bin/Xvfb
ln -s ${SYSTOOLS_DIR}/x86_64-conda-linux-gnu/sysroot/usr/bin/xvfb-run ${INSTALL_PREFIX}/deps/bin/xvfb-run
export PATH="${PATH}:${INSTALL_PREFIX}/deps/bin"

# Install AFNI
echo "Installing AFNI from offical binary package..."
curl -s https://afni.nimh.nih.gov/pub/dist/bin/misc/@update.afni.binaries | \
    tcsh -s - -no_recur -package ${PKG_VERSION} -bindir ${INSTALL_PREFIX}
# post installation setup
cp ${INSTALL_PREFIX}/AFNI.afnirc ${HOME}/.afnirc
suma -update_env
apsearch -update_all_afni_help
afni_system_check.py -check_all

# Cleanup
if [ -f .R.Rout ]; then rm .R.Rout; fi

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# AFNI
export AFNI_DIR=\"${INSTALL_ROOT_PREFIX}/afni\"
export PATH=\"\${AFNI_DIR}:\${PATH}:\${AFNI_DIR}/deps/bin\"
# command completion
if [ -f \${HOME}/.afni/help/all_progs.COMP.zsh ]; then source \${HOME}/.afni/help/all_progs.COMP.zsh; fi
# add deps directory in LD_LIBRARY_PATH
export LD_LIBRARY_PATH=\"\${LD_LIBRARY_PATH}:\${AFNI_DIR}/deps/lib\"
# do not log commands
export AFNI_DONT_LOGFILE=YES
"
fi
