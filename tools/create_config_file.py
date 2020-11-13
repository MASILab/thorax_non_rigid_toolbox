import argparse

def generate_config_file(bash_config_path, num_processes):
    print(f'Generate configuration file {bash_config_path}')
    print(f'Num of processes: {num_processes}')
    with open(bash_config_path, 'w') as rsh:
        rsh.write(f'''

# Runtime enviroment
SRC_ROOT=/src/ThoraxNonRigid
PYTHON_ENV=/opt/conda/envs/python37/bin/python

# Tools
TOOL_ROOT=${{SRC_ROOT}}/packages
DCM_2_NII_TOOL=${{TOOL_ROOT}}/dcm2niix
C3D_ROOT=${{TOOL_ROOT}}/c3d
NIFYREG_ROOT=${{TOOL_ROOT}}/niftyreg/bin
REG_TOOL_ROOT=${{NIFYREG_ROOT}}

# Data
OUT_ROOT=/temp
#mkdir -p ${{OUT_ROOT}}

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=441
DIM_Y=441
DIM_Z=400

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_niftyreg
IMAGE_ATLAS=/atlas/atlas.nii.gz
IMAGE_LABEL=/atlas/label_lung_only.nii.gz

# Running environment
NUM_PROCESSES={num_processes}

        ''')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--config-path', type=str)
    parser.add_argument('--num-processes', type=int)

    args = parser.parse_args()
    generate_config_file(args.config_path, args.num_processes)
