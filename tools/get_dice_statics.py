import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd


logger = get_logger('Dice')


class CalculateDice(AbstractParallelRoutine):
    def __init__(self, in_folder_obj, effective_mask_folder, num_process, gt_mask):
        super().__init__(in_folder_obj, num_process)
        self._effective_mask_folder_obj = effective_mask_folder
        self._gt_mask = ScanWrapper(gt_mask)
        self._df_dice = None

    def get_dice(self):
        logger.info(f'Calculating dice score')
        result_list = self.run_parallel()
        logger.info(f'Done.')
        self._df_dice = pd.DataFrame(result_list)
        # print(self._df_dice)

    def save_csv(self, csv_file):
        logger.info(f'Save dice table to csv {csv_file}')
        self._df_dice.to_csv(csv_file, index=False)

    def _run_single_scan(self, idx):
        test_mask = ScanWrapper(self._in_data_folder.get_file_path(idx))
        effective_mask = ScanWrapper(self._effective_mask_folder_obj.get_file_path(idx))

        dice_val = get_dice_with_effective_mask(
            self._gt_mask.get_data(),
            test_mask.get_data(),
            effective_mask.get_data()
        )

        result = {
            'Scan': test_mask.get_file_name(),
            'Dice': dice_val
        }

        return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--in-effective-mask-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--gt-mask', type=str)
    parser.add_argument('--out-csv', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    in_effective_mask_folder_obj = DataFolder(args.in_effective_mask_folder, args.file_list_txt)
    dice_cal = CalculateDice(in_folder_obj, in_effective_mask_folder_obj, args.num_process, args.gt_mask)
    dice_cal.get_dice()
    dice_cal.save_csv(args.out_csv)


if __name__ == '__main__':
    main()
