#!/bin/bash

PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SBATCH_JOB_SH=${PROJ_ROOT}/sbatch_job.sh

# Run sbatch
sbatch ${SBATCH_JOB_SH}
