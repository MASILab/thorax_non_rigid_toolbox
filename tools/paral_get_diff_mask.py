import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np


logger = get_logger('Apply Mask')


class GetDiffMask(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 ref_mask_obj,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self._out_folder_obj = out_folder_obj
        self._ref_mask_obj = ref_mask_obj

    def _run_single_scan(self, idx):
        in_mask = ScanWrapper(self._in_data_folder.get_file_path(idx))
        mask_diff = np.zeros(in_mask.get_shape(), dtype=int)
        mask_diff[in_mask.get_data() != self._ref_mask_obj.get_data()] = 1
        out_path = self._out_folder_obj.get_file_path(idx)
        self._ref_mask_obj.save_scan_same_space(out_path, mask_diff)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-mask-folder', type=str)
    parser.add_argument('--in-ref-mask', type=str, default=None)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_mask_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    ref_mask_obj = ScanWrapper(args.in_ref_mask)

    exe_obj = GetDiffMask(in_folder_obj, out_folder_obj, ref_mask_obj, args.num_process)

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
