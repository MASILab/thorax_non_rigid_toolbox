import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import os
import numpy as np


logger = get_logger('ReplaceNaN')


class ParaReplaceNan(AbstractParallelRoutine):
    def __init__(self,
                 in_ori_folder_obj,
                 out_folder_obj,
                 replace_val,
                 num_process
                 ):
        super().__init__(in_ori_folder_obj, num_process)
        self._out_folder = out_folder_obj
        self._replace_val = replace_val

    def _run_single_scan(self, idx):
        in_ori_path = self._in_data_folder.get_file_path(idx)
        out_path = self._out_folder.get_file_path(idx)

        im_obj = ScanWrapper(in_ori_path)
        im_data = im_obj.get_data()

        logger.info(f'Replace nan to valude {self._replace_val}')

        new_im_data = np.nan_to_num(im_data, nan=self._replace_val)
        im_obj.save_scan_same_space(out_path, new_im_data)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-ori-folder', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--val', type=float)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_ori_folder_obj = DataFolder(args.in_ori_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    exe_obj = ParaReplaceNan(
        in_ori_folder_obj,
        out_folder_obj,
        args.val,
        args.num_process
    )
    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
