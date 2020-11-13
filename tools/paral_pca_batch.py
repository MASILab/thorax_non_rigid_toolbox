import argparse
import numpy as np
import nibabel as nib
from data_io import DataFolder, ScanWrapper
import os
from paral import AbstractParallelRoutine
from utils import get_logger

logger = get_logger('PCA')


def main():
    parser = argparse.ArgumentParser(description='Run preprocess on in data folder')
    parser.add_argument('--in-folder', type=str,
                        help='Folder of input data', required=True)
    parser.add_argument('--out-folder', type=str,
                        help='Output location for preprocessed images', required=True)
    parser.add_argument('--average-img', type=str,
                        help='Use this average image to impute the missing voxels in targets')
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)
    average_img_obj = ScanWrapper(args.average_img)
    preprocess_obj = PreprocessAverageImputation(
        in_folder_obj,
        out_folder_obj,
        average_img_obj,
        args.num_process
    )
    preprocess_obj.run_parallel()


if __name__ == '__main__':
    main()