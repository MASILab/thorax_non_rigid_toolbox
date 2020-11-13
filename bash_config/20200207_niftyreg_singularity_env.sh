###################### Change Log ################
# 2/7/2020 - Kaiwen
# NIFTYREG configuration for singularity.
##################################################

#PROJ_NAME=20200206_niftyreg_singularity

# Runtime enviroment
SRC_ROOT=/src/ThoraxNonRigid
PYTHON_ENV=/opt/conda/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
REG_TOOL_ROOT=${NIFYREG_ROOT}

# Data
OUT_ROOT=/temp

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=441
DIM_Y=441
DIM_Z=400

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_niftyreg
IMAGE_ATLAS=${SRC_ROOT}/data/atlas.nii.gz
IMAGE_LABEL=${SRC_ROOT}/data/label_lung_only.nii.gz

# Running environment
NUM_PROCESSES=16