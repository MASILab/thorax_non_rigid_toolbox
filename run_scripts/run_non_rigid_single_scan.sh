#!/bin/bash

CONFIG_FILE=$(readlink -f $1)
SCAN_NAME=$2
#METHOD_FUNCTION_SH="$3"

source ${CONFIG_FILE}

source ${SRC_ROOT}/tools/${METHOD_FUNCTION_SH}

scan_name_base="$(basename -- $SCAN_NAME)"

start=`date +%s`

run_process_one_scan ${scan_name_base}
recreate_trans_field ${scan_name_base}
run_interp_scan ${scan_name_base}

if [ "$IF_REMOVE_TEMP_FILES" = true ]; then
  rm_temp_files ${scan_name_base}
fi

end=`date +%s`
runtime=$((end-start))
echo "Complete! Total ${runtime} (s)"