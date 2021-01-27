import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import os
dir_path = os.path.dirname(os.path.realpath(__file__))


logger = get_logger('Resample using c3d')


c3d_path = os.path.join(dir_path, '../packages/c3d/c3d')


class C3DResample(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 dim_list,
                 inter,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self.out_folder_obj = out_folder_obj
        self.dim_list = dim_list
        self.inter = inter

    def _run_single_scan(self, idx):
        in_img_path = self._in_data_folder.get_file_path(idx)
        out_path = self.out_folder_obj.get_file_path(idx)

        cmd_str = f'{c3d_path} -int {self.inter} {in_img_path} -resample-mm {self.dim_list[0]}x{self.dim_list[1]}x{self.dim_list[2]}mm -o {out_path}'
        logger.info(cmd_str)
        os.system(cmd_str)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--inter', type=int, default=3)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--dim', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    dim_list = args.dim.split('x')
    logger.info(f'Resample image to dimension {dim_list[0]}x{dim_list[1]}x{dim_list[2]}')

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    exe_obj = C3DResample(in_folder_obj,
                          out_folder_obj,
                          dim_list,
                          args.inter,
                          args.num_process)

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
