#!/bin/bash

SINGULARITY_PATH=/scratch/xuk9/singularity/thorax_combine.img
IN_DATA_FOLDER=/home/xuk9/Data/SPORE/data_flat
PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_LIST=${PROJ_ROOT}/data/file_list

set -o xtrace
singularity exec \
            -B ${IN_DATA_FOLDER}:/data_root \
            -B ${PROJ_ROOT}:/proj_root \
            ${SINGULARITY_PATH} preprocess_combine_pipeline
set +o xtrace

# Create the sbatch job file.
SBATCH_JOB_SH=${PROJ_ROOT}/sbatch_job.sh
LOG_FOLDER=${PROJ_ROOT}/log
mkdir -p ${LOG_FOLDER}

NUM_SCANS=$(cat ${FILE_LIST} | wc -l )
ARRAY_UPPER_BOUND=$((${NUM_SCANS}-1))

> ${SBATCH_JOB_SH}
echo "#!/bin/bash

#SBATCH -J deeds_vlsp
#SBATCH --mail-user=kaiwen.xu@vanderbilt.edu
#SBATCH --mail-type=FAIL
#SBATCH --cpus-per-task=5
#SBATCH --nodes=1
#SBATCH --time=1:00:00
#SBATCH --mem=25G
#SBATCH -o ${LOG_FOLDER}/scan_%A_%a.out
#SBATCH -e ${LOG_FOLDER}/scan_%A_%a.err
#SBATCH --array=0-${ARRAY_UPPER_BOUND}

mapfile -t cmds < ${FILE_LIST}
SCAN_NAME=\${cmds[\$SLURM_ARRAY_TASK_ID]}

set -o xtrace
singularity exec -B ${IN_DATA_FOLDER}:/data_root -B ${PROJ_ROOT}:/proj_root ${SINGULARITY_PATH} run_combine_pipeline \${SCAN_NAME}
set +o xtrace
" >> ${SBATCH_JOB_SH}

# Run sbatch
sbatch ${SBATCH_JOB_SH}
