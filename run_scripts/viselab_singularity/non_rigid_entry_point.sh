#!/bin/bash

# The entry point for singularity call. Put this in project root folder.
# Need to add thsi folder to /.singularity.d/env/95-apps.sh

RUN_COMMAND="$(basename -- $1)"
#RUN_COMMAND="_non_rigid_corrField_3_step.sh"

PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DATA_ROOT=${PROJ_ROOT}/../..

SINGULARITY_PATH=${MY_NFS_DATA_ROOT}/singularity/thorax_combine/conda_base

set -o xtrace
singularity exec \
            -B ${PROJ_ROOT}:/proj_root \
            -B ${DATA_ROOT}:/data_root \
            ${SINGULARITY_PATH} ${RUN_COMMAND}
set +o xtrace

echo "Done."
