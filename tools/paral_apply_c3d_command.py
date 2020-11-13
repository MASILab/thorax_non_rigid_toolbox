import argparse
from data_io import DataFolder
from utils import get_logger
from paral import AbstractParallelRoutine
import os


logger = get_logger('Paral C3D')


class ParalC3DCommand(AbstractParallelRoutine):
    def __init__(self,
                 in_ori_folder_obj,
                 out_folder_obj,
                 c3d_path,
                 command_str,
                 num_process):
        super().__init__(in_ori_folder_obj, num_process)
        self._out_folder = out_folder_obj
        self._c3d_path = c3d_path
        self._command_str = command_str

    def _run_single_scan(self, idx):
        in_ori_path = self._in_data_folder.get_file_path(idx)
        out_path = self._out_folder.get_file_path(idx)

        c3d_cmd = f'{self._c3d_path} {in_ori_path} {self._command_str} -o {out_path}'
        logger.info(c3d_cmd)
        os.system(c3d_cmd)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-ori-folder', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--c3d-path', type=str)
    parser.add_argument('--command-str', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_ori_folder_obj = DataFolder(args.in_ori_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    exe_obj = ParalC3DCommand(
        in_ori_folder_obj,
        out_folder_obj,
        args.c3d_path,
        args.command_str,
        args.num_process
    )
    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
