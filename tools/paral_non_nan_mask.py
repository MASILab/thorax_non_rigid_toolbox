import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np


logger = get_logger('Non nan region mask')


class NonNanRegionMask(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_mask_folder_obj,
                 num_process, if_inverse=False):
        super().__init__(in_folder_obj, num_process)
        self._out_mask_folder_obj = out_mask_folder_obj
        self._if_reverse = if_inverse

    def _run_single_scan(self, idx):
        in_img = ScanWrapper(self._in_data_folder.get_file_path(idx))
        out_path = self._out_mask_folder_obj.get_file_path(idx)

        in_img_data = in_img.get_data()
        non_nan_mask = (in_img_data == in_img_data).astype(int)

        if self._if_reverse:
            non_nan_mask = 1 - non_nan_mask

        in_img.save_scan_same_space(out_path, non_nan_mask)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--inverse-label', action='store_true')
    parser.add_argument('--out-mask-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_mask_folder_obj = DataFolder(args.out_mask_folder, args.file_list_txt)

    logger.info(f'Get non-nan mask in folder from {args.in_folder}')

    exe_obj = NonNanRegionMask(in_folder_obj,
                               out_mask_folder_obj,
                               args.num_process, args.inverse_label)

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
