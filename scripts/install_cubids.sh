#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/cubids")"


# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then echo "Cleanup old CuBIDS installation..." && rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing CuBIDS ..."
pixi init ${INSTALL_PREFIX} && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "python=3.12.*" && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml "deno>=2.9" && \
pixi add --manifest-path ${INSTALL_PREFIX}/pixi.toml --pypi "cubids>=1.2" && \
pixi install --manifest-path ${INSTALL_PREFIX}/pixi.toml

# Create wrapper script
# CuBIDS calls `deno` by name to run the BIDS validator (jsr:@bids/validator). The wrapper makes sure
# the deno from this environment is used instead of any other deno in PATH, and keeps the deno cache
# (including the downloaded validator) inside the installation directory.
mkdir -p ${INSTALL_PREFIX}/bin
cat > ${INSTALL_PREFIX}/bin/cubids << 'EOF'
#!/bin/bash
# Resolve the installation directory, following symlinks to this script
ROOT="$(cd "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
ENV_BIN="${ROOT}/.pixi/envs/default/bin"
if [ ! -x "${ENV_BIN}/deno" ] || [ ! -x "${ENV_BIN}/cubids" ]; then
    echo "Error: CuBIDS environment is incomplete in ${ROOT}." >&2
    exit 1
fi
export PATH="${ENV_BIN}:${PATH}"
export DENO_DIR="${ROOT}/deno"
exec "${ENV_BIN}/cubids" "$@"
EOF
chmod 755 ${INSTALL_PREFIX}/bin/cubids

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# CuBIDS
export PATH=\"${INSTALL_ROOT_PREFIX}/cubids/bin:\${PATH}\"
"
