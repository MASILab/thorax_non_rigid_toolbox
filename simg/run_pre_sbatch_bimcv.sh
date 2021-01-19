#!/bin/bash

# SINGULARITY_PATH=/nfs/masi/xuk9/singularity/thorax_combine/conda_base
SINGULARITY_PATH=/scratch/xuk9/singularity/thorax_combine_20201022.img
IN_DATA_FOLDER=/scratch/xuk9/nifti/BIMCV/data/ct
PROJ_ROOT=/scratch/xuk9/nifti/BIMCV/reg_pipeline
FILE_LIST=${PROJ_ROOT}/data/file_list
BATCH_SIZE=1

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
N_BATCH=$((${NUM_SCANS}/${BATCH_SIZE}))
ARRAY_UPPER_BOUND=$((${N_BATCH}-1))

BIN_EXTERNAL=/home/xuk9/src/Thorax_non_rigid_combine/simg/bin
SRC_AFFINE=/home/xuk9/src/Thorax_affine_combine
SRC_NON_RIGID=/home/xuk9/src/Thorax_non_rigid_combine

> ${SBATCH_JOB_SH}
echo "#!/bin/bash

#SBATCH -J per_scan_corrField_pipeline
#SBATCH --mail-user=kaiwen.xu@vanderbilt.edu
#SBATCH --mail-type=FAIL
#SBATCH --cpus-per-task=3
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --mem=60G
#SBATCH -o ${LOG_FOLDER}/scan_%A_%a.out
#SBATCH --array=0-${ARRAY_UPPER_BOUND}

echo \"SERVER_ID: \${HOSTNAME}\"

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
  singularity exec --contain -B ${BIN_EXTERNAL}:/bin_external -B ${IN_DATA_FOLDER}:/data_root -B ${PROJ_ROOT}:/proj_root -B ${SRC_AFFINE}:/src/Thorax_affine_combine -B ${SRC_NON_RIGID}:/src/Thorax_non_rigid_combine ${SINGULARITY_PATH} run_combine_pipeline.sh \${SCAN_NAME}
  set +o xtrace
done

" >> ${SBATCH_JOB_SH}
