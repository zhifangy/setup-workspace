#!/bin/bash

if [ -z ${SETUP_ROOT} ]
then
    source envs
fi

# Create default conda enviornment on Mac
echo "Current conda: $(which conda)"

# Add conda-forge channel
conda config --add channels conda-forge
conda config --add channels pytorch
conda config --set channel_priority strict

# Environment name
ENV_PREFIX=${SETUP_ROOT}/pyenv
echo "Enviromenmet location: ${ENV_PREFIX}"

# Create environment
conda create -p ${ENV_PREFIX} -y python=3.8

# Activate environment
source $(conda info --base)/etc/profile.d/conda.sh
conda activate ${ENV_PREFIX}

# Install packages using conda
conda install -yq \
    numpy \
    pandas \
    scipy \
    statsmodels \
    scikit-learn \
    scikit-image \
    xgboost \
    ipython \
    jupyterlab \
    jupyter-lsp \
    python-language-server \
    xeus-python \
    matplotlib \
    seaborn \
    plotly \
    plotly-orca \
    bokeh \
    graphviz \
    vtk \
    mayavi \
    ffmpeg \
    ipywidgets \
    'nodejs>=10' \
    spyder \
    mpi4py \
    h5py \
    feather-format \
    cython \
    pybind11 \
    flake8 \
    autopep8 \
    black \
    yapf \
    pytest \
    jupyterlab_code_formatter \
    jupytext \
    nbdime \
    qgrid \
    pyjanitor \
    python-dotenv \
    pyprojroot \
    memory_profiler \
    threadpoolctl \
    cookiecutter \
    pytorch \
    torchvision \
    nilearn \
    nipype \
    mne \
    fsleyes \
    pydicom \
    umap-learn \
    gensim \
    pyrsistent \
    pint \
    py4j \
    s3fs \
    ipyvolume \
    datalad

# Install package through pip
pip install --no-cache-dir \
    pyls-black \
    rpy2 \
    radian \
    pymer4 \
    sklearn-lmer \
    bigmpi4py \
    pymanopt \
    theano \
    dcmstack \
    pybids \
    heudiconv \
    bidscoin \
    antspyx \
    pymvpa2 \
    visualqc \
    neuropythy \
    hypertools \
    fse \
    ppca && \
# Brainiak depends on nitime, which can't be complied under python 3.8 (nitime v0.8.1)
# For now, we just ignore nitime. This only affects the brsa algorithm
# Also, brainiak depends on tensorflow for matnormal package
# Again, we just ignore it here
pip install brainiak --no-deps --no-cache-dir && \

# Install jupyterlab extensions
jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter labextension install @krassowski/jupyterlab-lsp
jupyter labextension install @jupyterlab/debugger
jupyter labextension install @ryantam626/jupyterlab_code_formatter
jupyter serverextension enable --py jupyterlab_code_formatter
jupyter labextension install qgrid2
jupyter labextension install jupyterlab-plotly
jupyter labextension install plotlywidget
jupyter labextension install jupyterlab-jupytext
jupyter labextension install ipyvolume
jupyter labextension install jupyter-threejs

# Cleanup
conda clean -apy
jupyter lab clean

echo "Installation completed!"