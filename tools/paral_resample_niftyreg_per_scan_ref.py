import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import os


logger = get_logger('Resample')


dir_path = os.path.dirname(os.path.realpath(__file__))
reg_resample_path = os.path.join(dir_path, '../packages/niftyreg/bin/reg_resample')


class ParalResampleNiftyReg(AbstractParallelRoutine):
    def __init__(self,
                 in_ori_folder_obj,
                 in_ref_folder_obj,
                 out_folder_obj,
                 nifty_reg_path,
                 int_order,
                 num_process,
                 pad_val='NaN'
                 ):
        super().__init__(in_ori_folder_obj, num_process)
        self._in_ref_folder = in_ref_folder_obj
        self._out_folder = out_folder_obj
        self._niftyreg_path = nifty_reg_path
        self._int_order = int_order
        self._pad_val = pad_val

    def _run_single_scan(self, idx):
        in_ori_path = self._in_data_folder.get_file_path(idx)
        out_path = self._out_folder.get_file_path(idx)
        in_ref_img_path = self._in_ref_folder.get_file_path(idx)

        resample_cmd = f'{self._niftyreg_path} -pad {self._pad_val} -inter {self._int_order} -ref {in_ref_img_path} -flo {in_ori_path} -res {out_path}'
        logger.info(resample_cmd)
        os.system(resample_cmd)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-ori-folder', type=str)
    parser.add_argument('--in-ref-folder', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--niftyreg-path', type=str, default=reg_resample_path)
    parser.add_argument('--int-order', type=int, default=3)
    parser.add_argument('--pad-val', type=str, default='NaN')
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_ori_folder_obj = DataFolder(args.in_ori_folder, args.file_list_txt)
    in_ref_folder_obj = DataFolder(args.in_ref_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)

    exe_obj = ParalResampleNiftyReg(
        in_ori_folder_obj,
        in_ref_folder_obj,
        out_folder_obj,
        args.niftyreg_path,
        args.int_order,
        args.num_process,
        args.pad_val
    )
    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
