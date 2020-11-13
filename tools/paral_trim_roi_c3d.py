import argparse
import numpy as np
import nibabel as nib
from data_io import DataFolder, ScanWrapper
import os
from paral import AbstractParallelRoutine
from utils import get_logger

logger = get_logger('Average Imputation')


class PreprocessTrimROI(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 c3d_path,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self._out_folder_obj = out_folder_obj
        self._c3d_path = c3d_path

    def _run_single_scan(self, idx):
        in_file_path = self._in_data_folder.get_file_path(idx)
        out_file_path = self._out_folder_obj.get_file_path(idx)

        cmd_str = f'{self._c3d_path} -verbose {in_file_path} -trim 0vox -o {out_file_path}'
        logger.info(cmd_str)
        os.system(cmd_str)


def main():
    parser = argparse.ArgumentParser(description='Run preprocess on in data folder')
    parser.add_argument('--in-folder', type=str,
                        help='Folder of input data', required=True)
    parser.add_argument('--out-folder', type=str,
                        help='Output location for preprocessed images', required=True)
    parser.add_argument('--c3d-path', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)
    preprocess_obj = PreprocessTrimROI(
        in_folder_obj,
        out_folder_obj,
        args.c3d_path,
        args.num_process
    )
    preprocess_obj.run_parallel()


if __name__ == '__main__':
    main()