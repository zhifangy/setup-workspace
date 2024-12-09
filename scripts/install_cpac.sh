#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/c-pac")"
CPAC_VERSION=${CPAC_VERSION:-release-v1.8.7-fMRIPrep-LTS}
# apptainer
export APPTAINER_TMPDIR="/tmp"
export APPTAINER_CACHEDIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/apptainer")"
# clear enviroment variables that may interference build process
export SINGULARITY_BIND=
export APPTAINER_BIND=

# Check OS
if [ "$OS_TYPE" == "macos" ]; then
    >&2 echo "Unsupported OS or architecture."
    exit 1
fi
# Check apptainer
# Check Micromamba installation
command -v apptainer &> /dev/null || { echo "Error: Apptainer is not installed or not included in the PATH." >&2; exit 1; }

# Cleanup old images
OLD_IMG=($(ls ${INSTALL_PREFIX}/c-pac_*.sif 2>/dev/null || true))
if [ ${#OLD_IMG[@]} -gt 0 ]; then
    echo "Found the following old images in ${INSTALL_PREFIX}:"
    # List the files with indices
    for i in "${!OLD_IMG[@]}"; do
        echo "$((i + 1)). ${OLD_IMG[i]}"
    done

    # Prompt the user for a choice
    echo "What would you like to do?"
    echo "1. Delete all files"
    echo "2. Delete specific file(s)"
    echo "3. Skip"
    read -p "Enter your choice (1/2/3): " CHOICE

    case $CHOICE in
        1)
            # Delete all files
            for f in "${OLD_IMG[@]}"; do
                rm "$f"
                echo "Deleted: $f"
            done
            ;;
        2)
            # Ask for specific file(s) to delete
            read -p "Enter the numbers of the files to delete (e.g., 1 3): " NUMS
            for num in $NUMS; do
                if [[ $num =~ ^[0-9]+$ ]] && [ $num -le ${#OLD_IMG[@]} ]; then
                    rm "${OLD_IMG[$((num - 1))]}"
                    echo "Deleted: ${OLD_IMG[$((num - 1))]}"
                else
                    echo "Invalid choice: $num"
                fi
            done
            ;;
        3)
            echo "Skipping deletion."
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
fi

# Build image
mkdir -p ${INSTALL_PREFIX}
IMG_PREFIX="${INSTALL_PREFIX}/c-pac_$(echo ${CPAC_VERSION} | sed 's/release-//g').sif"
apptainer build ${IMG_PREFIX} docker://fcpindi/c-pac:${CPAC_VERSION}

# Cleanup
apptainer cache clean -f

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# c-pac
export PATH=\"${INSTALL_ROOT_PREFIX}/c-pac:\${PATH}\"
"
