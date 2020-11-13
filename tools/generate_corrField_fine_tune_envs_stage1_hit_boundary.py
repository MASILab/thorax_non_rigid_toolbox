import os
import argparse
import numpy as np
from utils import get_logger, mkdir_p

logger = get_logger('EnvGenerator')


def get_config_string(search_radius, kp_disp, reg, sim_size):
    search_radius_opt_str = f'{search_radius}x{search_radius//2}'
    kp_disp_opt_str = f'{kp_disp}x{kp_disp//2}'
    reg_opt_str = f'{reg}'
    sim_size_opt_str = f'{sim_size}x{(sim_size*2)//3}'
    return f'''\
# Runtime enviroment
SRC_ROOT=/src/Thorax_non_rigid_combine
PYTHON_ENV=/opt/conda/envs/python37/bin/python
IF_REMOVE_TEMP_FILES=false
N_JOBS=1

# Method
METHOD_FUNCTION_SH=functions_corrField_non_rigid_3_low_res.sh

# Tools
TOOL_ROOT=${{SRC_ROOT}}/packages
C3D_ROOT=${{TOOL_ROOT}}/c3d
NIFYREG_ROOT=${{TOOL_ROOT}}/niftyreg/bin
corrField_ROOT=${{TOOL_ROOT}}/corrField

# corrField configuration
corrField_config_step1="-L {search_radius_opt_str} -a {reg_opt_str} -N {kp_disp_opt_str} -R {sim_size_opt_str}"
effective_etch_step1="26"
corrField_config_step2="-L 10x5 -a 1 -N 10x5 -R 6x4"
effective_etch_step2="16"
corrField_config_step3="-L 5x3 -a 0.5"
effective_etch_step3="16"

# Data
# MOVING_FOLDER=/proj_root/output/affine/interp/ori
MOVING_FOLDER=/data_root/output/affine/interp/ori
FILE_LIST_TXT=/data_root/data/file_list_5
# FILE_LIST_TXT=/proj_root/missing_list
OUT_DATA_FOLDER=/proj_root
MASK_FOLDER=/data_root/output/affine/interp
REFERENCE_FOLDER=/data_root/output_low_res/reference
FIXED_IMG=${{REFERENCE_FOLDER}}/non_rigid.nii.gz
IDENTITY_MAT=${{REFERENCE_FOLDER}}/idendity_matrix.txt

OUTPUT_ROOT_FOLDER=${{OUT_DATA_FOLDER}}/output
OUTPUT_INTERP_FOLDER=${{OUT_DATA_FOLDER}}/interp
OUTPUT_JAC_DET_FOLDER=${{OUT_DATA_FOLDER}}/jac_det
OUTPUT_LOG=/proj_root/log

set -o xtrace
mkdir -p ${{OUTPUT_ROOT_FOLDER}}
mkdir -p ${{OUTPUT_INTERP_FOLDER}}
mkdir -p ${{OUTPUT_JAC_DET_FOLDER}}
mkdir -p ${{OUTPUT_LOG}}
set +o xtrace
'''


def generate_test_env(fine_tune_case_root):
    # range_search_radius = np.arange(10, 31, 5, dtype=int)
    # range_kp_disp = np.arange(6, 15, 2, dtype=int)
    # range_reg = np.arange(0.4, 1.7, 0.3, dtype=float)
    # range_sim_size = np.arange(3, 10, 3, dtype=int)

    range_search_radius = np.arange(10, 51, 5, dtype=int)
    range_kp_disp = np.arange(6, 15, 2, dtype=int)
    range_reg = np.arange(0.4, 2.3, 0.3, dtype=float)
    range_sim_size = np.arange(3, 10, 3, dtype=int)

    # Stage_1
    # test_idx_range_search_radius = range(0, 5)
    # test_idx_range_kp_disp = range(0, 5)
    # test_idx_range_reg = range(0, 5)
    # test_idx_range_sim_size = range(0, 3)

    # Stage_1_2, seed optimal 2
    test_idx_range_search_radius = range(0, 9)
    test_idx_range_kp_disp = range(1, 2)
    test_idx_range_reg = range(2, 3)
    test_idx_range_sim_size = range(1, 2)

    # Stage_1_3, seed optimal 1
    # test_idx_range_search_radius = range(3, 8)
    # test_idx_range_kp_disp = range(1, 5)
    # test_idx_range_reg = range(4, 7)
    # test_idx_range_sim_size = range(2, 3)

    # config_str = get_config_string(
    #     range_search_radius[0],
    #     range_kp_disp[1],
    #     range_reg[2],
    #     range_sim_size[0])
    #
    # print(config_str)

    # logger.info(f'{range_search_radius}')
    # logger.info(f'{range_kp_disp}')
    # logger.info(f'{range_reg}')
    # logger.info(f'{range_sim_size}')

    logger.info(f'Test range:')
    logger.info(f'{[range_search_radius[idx] for idx in test_idx_range_search_radius]}')
    logger.info(f'{[range_kp_disp[idx] for idx in test_idx_range_kp_disp]}')
    logger.info(f'{[range_reg[idx] for idx in test_idx_range_reg]}')
    logger.info(f'{[range_sim_size[idx] for idx in test_idx_range_sim_size]}')

    for idx_search_radius in test_idx_range_search_radius:
        for idx_kp_disp in test_idx_range_kp_disp:
            for idx_reg in test_idx_range_reg:
                for idx_sim_size in test_idx_range_sim_size:
                    case_folder = os.path.join(fine_tune_case_root,
                                               f'step1_{idx_search_radius}_{idx_kp_disp}_{idx_reg}_{idx_sim_size}')
                    mkdir_p(case_folder)
                    config_path = os.path.join(case_folder, 'config.sh')
                    config_str = get_config_string(
                        range_search_radius[idx_search_radius],
                        range_kp_disp[idx_kp_disp],
                        round(range_reg[idx_reg], 2),
                        range_sim_size[idx_sim_size]
                    )
                    with open(config_path, "w") as config_file:
                        config_file.write(config_str)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--fine-tune-case-root', type=str)
    args = parser.parse_args()

    generate_test_env(args.fine_tune_case_root)