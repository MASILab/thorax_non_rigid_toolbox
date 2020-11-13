###################### Change Log ################
# 2/2/2020 - Kaiwen
# Preprocess pipeline for non-rigid registration
# 1. Resample to iso
# 2. Generate lung mask with kaggle.
# 3. Reset origin to lung mask center, both lung mask image and original image.
##################################################

PROJ_NAME=20200205_non_rigid_deeds_assess_source_stable

# Runtime enviroment
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
IS_USE_SLURM=false
NUM_JOBS=1

# Tools
FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin
C3D_ROOT=/home/local/VANDERBILT/xuk9/src/c3d/bin
NIFYREG_ROOT=/home-nfs2/local/VANDERBILT/xuk9/local/niftyreg/bin
DEEDS_ROOT=/home/local/VANDERBILT/xuk9/local/deedsBCV

REG_TOOL_ROOT=${DEEDS_ROOT}

# Data
DATA_ROOT=/nfs/masi/xuk9/SPORE
IN_ROOT=${DATA_ROOT}/registration/nonrigid_deedsBCV/demo_cases
IN_DATASET_TYPE=flat
OUT_ROOT=${DATA_ROOT}/registration/nonrigid_deedsBCV/${PROJ_NAME}
mkdir -p ${OUT_ROOT}

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=441
DIM_Y=441
DIM_Z=400
STD_SPACE_NII=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/nonrigid_deedsBCV/20200130_atlas_to_image/atlas/atlas_iso.nii.gz
#IDENTITY_MAT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/nonrigid_deedsBCV/standard_space.txt

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_deedsBCV
REG_ARGS="\"-l_1_-G_16_-L_16_-Q_5\""
LABEL_IMAGE=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200131_image_to_image_with_label/labels_iso_int.nii.gz

# Folders
MAT_OUT=${OUT_ROOT}/omat
REG_OUT=${OUT_ROOT}/reg
PREPROCESS_OUT=${OUT_ROOT}/preprocess
INTERP_OUT=${OUT_ROOT}/interp
SLURM_DIR=${OUT_ROOT}/slurm
LOG_DIR=${OUT_ROOT}/log
TEMP_DIR=${OUT_ROOT}/temp
FIXED_IMAGE_DIR=${OUT_ROOT}/fixed_image
STATIC_OUT=${OUT_ROOT}/out
COMPLETE_TASK_DIR=${OUT_ROOT}/complete
COMPLETE_PREPROCESS_DIR=${COMPLETE_TASK_DIR}/preprocess
COMPLETE_REGISTRATION_DIR=${COMPLETE_TASK_DIR}/registration
COMPLETE_INTERPOLATION_DIR=${COMPLETE_TASK_DIR}/interpolation

FIXED_IMAGE=${FIXED_IMAGE_DIR}/fixed_image.nii.gz

OUTPUT_AVERAGE=${STATIC_OUT}/${PROJ_NAME}_average.nii.gz
OUTPUT_VARIANCE=${STATIC_OUT}/${PROJ_NAME}_variance.nii.gz