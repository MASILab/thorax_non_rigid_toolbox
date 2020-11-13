import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd
import numpy as np


logger = get_logger('Dice')


class JacobianDetStatics(AbstractParallelRoutine):
    def __init__(self, in_folder_obj, num_process):
        super().__init__(in_folder_obj, num_process)
        self._df_data = None

    def get_jac_statics(self):
        logger.info(f'Calculating Jacobian statistics (ratio of neg jac det, std of jac det)')
        result_list = self.run_parallel()
        logger.info(f'Done.')
        self._df_data = pd.DataFrame(result_list)

    def save_csv(self, csv_file):
        logger.info(f'Save table to csv {csv_file}')
        self._df_data.to_csv(csv_file, index=False)

    def _run_single_scan(self, idx):
        in_scan_data = ScanWrapper(self._in_data_folder.get_file_path(idx)).get_data()

        neg_map = (in_scan_data < 0).astype(int)
        neg_ratio = np.sum(neg_map) / neg_map.size

        result = {
            'Scan': self._in_data_folder.get_file_name(idx),
            'STD': np.std(in_scan_data),
            'NegRatio': neg_ratio
        }

        return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-jac-det-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--out-csv', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_jac_det_folder, args.file_list_txt)
    dice_cal = JacobianDetStatics(in_folder_obj, args.num_process)
    dice_cal.get_jac_statics()
    dice_cal.save_csv(args.out_csv)


if __name__ == '__main__':
    main()
