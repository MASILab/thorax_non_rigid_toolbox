#!/bin/bash

SCAN_NAME="$(basename -- $1)"

echo "SERVER_ID: ${HOSTNAME}"

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh
source /src/Thorax_non_rigid_combine/tools/functions_affine_deformable_singularity.sh

process_affine_scan /proj_root/output/affine/config.sh ${SCAN_NAME}
process_non_rigid_scan /proj_root/output/non_rigid/config.sh ${SCAN_NAME}