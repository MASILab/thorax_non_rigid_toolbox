#!/bin/bash

#SRC_NON_RIGID=/home/xuk9/src/Thorax_non_rigid_combine
#SRC_AFFINE=/home/xuk9/src/Thorax_affine_combine
#DATA_ROOT=/scratch/xuk9/nifti/SPORE/data_flat
#PROJ_ROOT=/scratch/xuk9/nifti/SPORE/reg_pipeline
#BIN_PATH=/home/xuk9/src/Thorax_non_rigid_combine/simg/bin
#SINGULARITY_PATH=/scratch/xuk9/singularity/thorax_combine_20201022.img

SRC_NON_RIGID=/nfs/masi/xuk9/src/Thorax_non_rigid_combine
SRC_AFFINE=/nfs/masi/xuk9/src/Thorax_affine_combine
DATA_ROOT=/nfs/masi/xuk9/SPORE/data/data_flat
#PROJ_ROOT=/nfs/masi/xuk9/SPORE/clustering/registration/20201125_corrField_fix_round_fov/male
PROJ_ROOT=/nfs/masi/xuk9/SPORE/clustering/registration/20200512_corrField/male
BIN_PATH=/nfs/masi/xuk9/src/Thorax_non_rigid_combine/simg/bin
SINGULARITY_PATH=/nfs/masi/xuk9/singularity/thorax_combine/thorax_combine_20201022.img

set -o xtrace
singularity exec --contain \
    -B ${BIN_PATH}:/bin_external \
    -B ${DATA_ROOT}:/data_root \
    -B ${PROJ_ROOT}:/proj_root \
    -B ${SRC_AFFINE}:/src/Thorax_affine_combine \
    -B ${SRC_NON_RIGID}:/src/Thorax_non_rigid_combine \
    ${SINGULARITY_PATH} evaluation_pipeline.sh non_rigid
set +o xtrace


