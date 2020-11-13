import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import pandas as pd
import os
import subprocess
from parse import parse


logger = get_logger('Metric - Mutual Information')


class MetricNMI(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 ref_img_obj,
                 niftyreg_root,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self._ref_img = ref_img_obj
        self._ref_measure_path = os.path.join(niftyreg_root, 'reg_measure')
        self._df_nmi = None

    def get_nmi(self):
        result_list = self.run_parallel()
        self._df_nmi = pd.DataFrame(result_list)

    def save_csv(self, csv_file):
        logger.info(f'Save dice table to csv {csv_file}')
        self._df_nmi.to_csv(csv_file, index=False)

    def _run_single_scan(self, idx):
        in_img_path = self._in_data_folder.get_file_path(idx)
        in_img_name = self._in_data_folder.get_file_name(idx)
        ref_img_path = self._ref_img.get_path()

        nmi_val = self._get_mutual_information(in_img_path, ref_img_path)

        result = {
            'Scan': in_img_name,
            'NMI': nmi_val
        }

        return result

    def _get_mutual_information(self, img1_path, img2_path):
        cmd_str = f'{self._ref_measure_path} -ref {img2_path} -flo {img1_path} -nmi'
        logger.info(cmd_str)
        result_str = subprocess.check_output(cmd_str, shell=True, text=True)
        parse_result = parse('NMI: {}', result_str)
        nmi_val = float(parse_result[0])

        logger.info(f'NMI: {nmi_val}')
        return nmi_val


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--ref-img', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--niftyreg-root', type=str)
    parser.add_argument('--out-csv', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    ref_img = ScanWrapper(args.ref_img)

    exe_obj = MetricNMI(in_folder_obj,
                        ref_img,
                        args.niftyreg_root,
                        args.num_process)

    exe_obj.get_nmi()
    exe_obj.save_csv(args.out_csv)


if __name__ == '__main__':
    main()
