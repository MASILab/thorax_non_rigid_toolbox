#!/bin/bash

##################################################
# 3/17/2020 - Kaiwen
# Create the gender separate 100 data set.
##################################################

CONFIG_FILE=$(readlink -f $1)
source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/atlas_built_functions.sh

SPLIT_DATA_ROOT=${ATLAS_OUT_ROOT}/data

for gender_flag in ${MALE_FLAG} ${FEMALE_FLAG}
do
  OUT_GENDER_DATA_FOLDER=${SPLIT_DATA_ROOT}/${gender_flag}
  FILE_LIST=${DATA_ROOT}/data/file_list/${gender_flag}_50.txt
  mkdir -p ${OUT_GENDER_DATA_FOLDER}
  create_lns_file_list \
    ${IN_DATA_FOLDER} \
    ${FILE_LIST} \
    ${OUT_GENDER_DATA_FOLDER}
done