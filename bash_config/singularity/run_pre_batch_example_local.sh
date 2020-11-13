#!/bin/bash

SINGULARITY_PATH=/nfs/masi/xuk9/singularity/thorax_combine/conda_base
IN_DATA_FOLDER=/nfs/masi/xuk9/SPORE/data/data_flat
PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_LIST=${PROJ_ROOT}/data/file_list
BATCH_SIZE=3

set -o xtrace
singularity exec \
            -B ${IN_DATA_FOLDER}:/data_root \
            -B ${PROJ_ROOT}:/proj_root \
            ${SINGULARITY_PATH} preprocess_combine_pipeline
set +o xtrace

# echo "echo \"SERVER_ID: \${HOSTNAME}\"" >> ${PROJ_ROOT}/run_combine_pipeline.sh

# Create the sbatch job file.
SBATCH_JOB_SH=${PROJ_ROOT}/sbatch_job.sh
LOG_FOLDER=${PROJ_ROOT}/log
mkdir -p ${LOG_FOLDER}

NUM_SCANS=$(cat ${FILE_LIST} | wc -l )
N_BATCH=$((${NUM_SCANS}/${BATCH_SIZE}))
ARRAY_UPPER_BOUND=$((${N_BATCH}))

> ${SBATCH_JOB_SH}
echo "#!/bin/bash

#SBATCH -J deeds_vlsp
#SBATCH --mail-user=kaiwen.xu@vanderbilt.edu
#SBATCH --mail-type=FAIL
#SBATCH --cpus-per-task=3
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --mem=25G
#SBATCH -o ${LOG_FOLDER}/scan_%A_%a.out
#SBATCH -e ${LOG_FOLDER}/scan_%A_%a.err
#SBATCH --array=0-${ARRAY_UPPER_BOUND}

mapfile -t cmds < ${FILE_LIST}
SEQ_LOW=\$((\${SLURM_ARRAY_TASK_ID}*${BATCH_SIZE}))
SEQ_UP=\$(((\${SLURM_ARRAY_TASK_ID}+1)*${BATCH_SIZE}-1))

if ["\${SEQ_UP}" -gt "$((${NUM_SCANS}-1))"]
then
  SEQ_UP=$((${NUM_SCANS}-1))
fi

for i in \$(seq \${SEQ_LOW} \${SEQ_UP})
do
  SCAN_NAME=\${cmds[\$i]}

  set -o xtrace
  singularity exec --contain --writable -B ${IN_DATA_FOLDER}:/data_root -B ${PROJ_ROOT}:/proj_root ${SINGULARITY_PATH} run_combine_pipeline \${SCAN_NAME}
  set +o xtrace
done

" >> ${SBATCH_JOB_SH}
