###################### Change Log ################
# 3/21 - Kaiwen
# Combined pipeline for niftyreg affine + deeds non-rigid
##################################################

PROJ_NAME=20200320_gender_sep_atlas

# Runtime enviroment
NON_RIGID_SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
AFFINE_SRC_ROOT=/home-nfs2/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxAffine_for_non_rigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Data
DATA_ROOT=/nfs/masi/xuk9/SPORE
PROJ_ROOT=${DATA_ROOT}/registration/non_rigid_atlas/${PROJ_NAME}
IN_DATA_FOLDER=${DATA_ROOT}/data/data_flat

# Tools
TOOL_ROOT=${NON_RIGID_SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin

# References
REFERENCE_FOLDER=${PROJ_ROOT}/data/reference
ROI_MASK_IMG=${REFERENCE_FOLDER}/roi_mask.nii.gz
IDD_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt