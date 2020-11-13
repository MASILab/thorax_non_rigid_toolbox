###################### Change Log ################
# 2/6/2020 - Kaiwen
# NIFTYREG pipeline for singularity
##################################################

PROJ_NAME=20200206_niftyreg_singularity

# Runtime enviroment
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
REG_TOOL_ROOT=${NIFYREG_ROOT}

# Data
#DATA_ROOT=/nfs/masi/xuk9/SPORE
#IN_ROOT=${DATA_ROOT}/registration/nonrigid_deedsBCV/demo_cases
#IN_DATASET_TYPE=flat
OUT_ROOT=/nfs/masi/xuk9/SPORE/registration/nonrigid_niftyreg/20200206_niftyreg_singularity
#mkdir -p ${OUT_ROOT}

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=441
DIM_Y=441
DIM_Z=400
#STD_SPACE_NII=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/nonrigid_deedsBCV/20200130_atlas_to_image/atlas/atlas_iso.nii.gz
#IDENTITY_MAT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/nonrigid_deedsBCV/standard_space.txt

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_niftyreg
IMAGE_ATLAS=${OUT_ROOT}/atlas.nii.gz
IMAGE_LABEL=${OUT_ROOT}/label.nii.gz

# Running environment
NUM_PROCESSES=16