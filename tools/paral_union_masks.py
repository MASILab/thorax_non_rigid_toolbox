import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np


logger = get_logger('Apply Mask')


class Union2Masks(AbstractParallelRoutine):
    def __init__(self,
                 in_folder1_obj,
                 in_folder2_obj,
                 out_folder_obj,
                 num_process):
        super().__init__(in_folder1_obj, num_process)
        self._in_folder2_obj = in_folder2_obj
        self._out_folder_obj = out_folder_obj

    def _run_single_scan(self, idx):
        mask1 = ScanWrapper(self._in_data_folder.get_file_path(idx))
        mask2 = ScanWrapper(self._in_folder2_obj.get_file_path(idx))

        mask_union = np.zeros(mask1.get_data().shape, dtype=int)
        mask_union[(mask1.get_data() == 1) | (mask2.get_data() == 1)] = 1

        out_path = self._out_folder_obj.get_file_path(idx)
        mask1.save_scan_same_space(out_path, mask_union)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-mask-folder1', type=str)
    parser.add_argument('--in-mask-folder2', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder1_obj = DataFolder(args.in_mask_folder1, args.file_list_txt)
    in_folder2_obj = DataFolder(args.in_mask_folder2, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    exe_obj = Union2Masks(in_folder1_obj, in_folder2_obj, out_folder_obj, args.num_process)

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
