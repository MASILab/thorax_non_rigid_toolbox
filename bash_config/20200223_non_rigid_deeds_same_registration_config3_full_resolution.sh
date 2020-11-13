###################### Change Log ################
# 2/2/2020 - Kaiwen
# Preprocess pipeline for non-rigid registration
# 1. Resample to iso
# 2. Generate lung mask with kaggle.
# 3. Reset origin to lung mask center, both lung mask image and original image.
##################################################

PROJ_NAME=20200218_non_rigid_deeds_same_registration_config

# Runtime enviroment
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

# Data
DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200218_deeds_forward_pipeline
OUT_ROOT=${DATA_ROOT}

# Preprocessing
SPACING_X=0.8828125
SPACING_Y=0.8828125
SPACING_Z=0.8
DIM_X=500
DIM_Y=500
DIM_Z=500

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_deedsBCV_paral
REG_ARGS="\"-l_3_-G_8x7x6_-L_8x7x6_-Q_5x4x3\""

IMAGE_ATLAS=${DATA_ROOT}/atlas_full_resolution/atlas.nii.gz
IMAGE_LABEL=${DATA_ROOT}/atlas_full_resolution/rib_and_spine.nii.gz

NUM_PROCESSES=32