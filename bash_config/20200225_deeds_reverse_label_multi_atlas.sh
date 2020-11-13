###################### Change Log ################
# 2/25/2020 - Kaiwen
# Working on the registration of vertebra.
# Preprocess pipeline for non-rigid registration
##################################################

PROJ_NAME=20200225_deeds_reverse_label_multi_atlas

# Runtime enviroment
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
AFFINE_SRC_ROOT=/home-nfs2/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxRegistration
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

# Data
DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200225_deeds_reverse_label_multi_atlas
OUT_ROOT=${DATA_ROOT}

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_deedsBCV_paral
REG_ARGS="\"\""

IMAGE_ATLAS=${DATA_ROOT}/atlas/atlas.nii.gz
IMAGE_LABEL=${DATA_ROOT}/atlas/rib_and_spine.nii.gz

NUM_PROCESSES=32