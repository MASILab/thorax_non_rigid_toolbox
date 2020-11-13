function non_rigid_niftyreg_folder {
  LOCAL_FOLDER_MOVING=$1
  LOCAL_IMAGE_ATLAS=$2
  LOCAL_FOLDER_OUT_ROOT=$3

  echo
  echo "####################################"
  echo "Nonrigid registration using NIFTYREG"
  echo
  echo "Moving image folder is ${LOCAL_FOLDER_MOVING}"
  echo "Atlas ${LOCAL_IMAGE_ATLAS}"
  echo "Output root folder ${LOCAL_FOLDER_OUT_ROOT}"
  echo

  target_image_folder=${LOCAL_FOLDER_MOVING}
  atlas_image=${LOCAL_IMAGE_ATLAS}

  reg_folder=${LOCAL_FOLDER_OUT_ROOT}
  omat_folder=${reg_folder}/omat
  trans_folder=${reg_folder}/trans
  affine_folder=${reg_folder}/affine
  non_rigid_folder=${reg_folder}/non_rigid
  mkdir -p ${reg_folder}
  mkdir -p ${omat_folder}
  mkdir -p ${trans_folder}
  mkdir -p ${affine_folder}
  mkdir -p ${non_rigid_folder}

  for file_path in "$target_image_folder"/*.nii.gz
  do
    start=`date +%s`

    file_base_name="$(basename -- $file_path)"
    out_file_path=${reg_folder}/${file_base_name}

    fixed_img=${atlas_image}
    moving_img=${file_path}
    omat_txt=${omat_folder}/${file_base_name}
    out_img=${non_rigid_folder}/${file_base_name}
    reg_tool_root=${REG_TOOL_ROOT}
    reg_method=deformable_niftyreg
    trans=${trans_folder}/${file_base_name}
    out_affine=${affine_folder}/${file_base_name}
#    reg_args_non_rigid="\"-ln_7_-omp_${NUM_PROCESSES}_--rLwTh_-100_--rUpTh_1000_--fLwTh_-100_--fUpTh_1000\""
#    reg_args_affine="\"-ln_5_-omp_${NUM_PROCESSES}_-refLowThr_0_-refUpThr_1000_-floLowThr_0_-refUpThr_1000\""
    reg_args_non_rigid="\"-ln_7_-omp_${NUM_PROCESSES}\""
    reg_args_affine="\"-ln_5_-omp_${NUM_PROCESSES}\""

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/reg_thorax_non_rigid.py \
      --fixed ${fixed_img} \
      --moving ${moving_img} \
      --omat ${omat_txt} \
      --reg_tool_root ${reg_tool_root} \
      --reg_method ${reg_method} \
      --reg_args_non_rigid ${reg_args_non_rigid} \
      --reg_args_affine ${reg_args_affine} \
      --trans ${trans} \
      --out ${out_img} \
      --out_affine ${out_affine}
    set +o xtrace

    end=`date +%s`

    runtime=$((end-start))

    echo "Registration complete. ${file_base_name}"
    echo "Complete! Total ${runtime} (s)"
  done

  echo ""
}