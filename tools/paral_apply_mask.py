import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np


logger = get_logger('Apply Mask')


class ApplyMask(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 ambient_val,
                 num_process,
                 in_mask_folder_obj=None,
                 in_mask_file_obj=None):
        super().__init__(in_folder_obj, num_process)
        self._in_mask_folder_obj = in_mask_folder_obj
        self._out_folder_obj = out_folder_obj
        self._ambient_val = ambient_val
        self._in_mask_file_obj = in_mask_file_obj

    def _run_single_scan(self, idx):
        in_img = ScanWrapper(self._in_data_folder.get_file_path(idx))
        in_mask = None
        if self._in_mask_folder_obj is not None:
            in_mask = ScanWrapper(self._in_mask_folder_obj.get_file_path(idx))
        if self._in_mask_file_obj is not None:
            in_mask = self._in_mask_file_obj
        out_path = self._out_folder_obj.get_file_path(idx)

        in_img_data = in_img.get_data()
        in_mask_data = in_mask.get_data()

        new_img_data = np.full(in_img.get_shape(), self._ambient_val)

        np.copyto(new_img_data, in_img_data, where=in_mask_data > 0)

        in_img.save_scan_same_space(out_path, new_img_data)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--in-mask-folder', type=str, default=None)
    parser.add_argument('--in-mask-file', type=str, default=None)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--ambient-val', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    in_mask_folder_obj = None
    in_mask_file_obj = None
    if args.in_mask_folder is not None:
        logger.info(f'Create in_mask_folder_obj with {args.in_mask_folder}')
        in_mask_folder_obj = DataFolder(args.in_mask_folder, args.file_list_txt)
        logger.info(f'Apply mask in folder {args.in_mask_folder} to {args.in_folder}')
    if args.in_mask_file is not None:
        logger.info(f'Create in_mask_file_obj with {args.in_mask_file}')
        in_mask_file_obj = ScanWrapper(args.in_mask_file)

    ambient_val = None
    ambient_val_str = args.ambient_val
    if ambient_val_str is 'nan':
        ambient_val = np.nan
    else:
        ambient_val = float(args.ambient_val)

    exe_obj = ApplyMask(in_folder_obj,
                        out_folder_obj,
                        ambient_val,
                        args.num_process,
                        in_mask_folder_obj=in_mask_folder_obj,
                        in_mask_file_obj=in_mask_file_obj)

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
