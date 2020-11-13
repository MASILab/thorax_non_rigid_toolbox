#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

AUTO_FINE_TUNE_ROOT=${PROJ_ROOT}/fine_tune_root

set -o xtrace
${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/generate_corrField_fine_tune_envs.py \
  --fine-tune-case-root ${AUTO_FINE_TUNE_ROOT}
set +o xtrace