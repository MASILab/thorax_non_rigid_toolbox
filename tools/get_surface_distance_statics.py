import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd
import numpy as np
from scipy import ndimage as ndi


logger = get_logger('Dice')


class GetMeanSurfaceDist(AbstractParallelRoutine):
    def __init__(self, in_folder_obj, effective_mask_folder_obj, num_process, gt_mask):
        super().__init__(in_folder_obj, num_process)
        self._effective_mask_folder_obj = effective_mask_folder_obj
        self._gt_mask = ScanWrapper(gt_mask)
        self._df_surface_metric = None

    def get_surface_metric(self):
        logger.info('Calculating surface metric')
        result_list = self.run_parallel()
        logger.info('Done')
        self._df_surface_metric = pd.DataFrame(result_list)

    def save_csv(self, csv_file):
        logger.info(f'Save surface metric table to csv {csv_file}')
        self._df_surface_metric.to_csv(csv_file, index=False)

    def _run_single_scan(self, idx):
        test_mask = ScanWrapper(self._in_data_folder.get_file_path(idx))
        effective_mask = ScanWrapper(self._effective_mask_folder_obj.get_file_path(idx))
        effective_data = effective_mask.get_data()

        test_data = test_mask.get_data()
        gt_data = self._gt_mask.get_data()

        edt_test, surf_test = self._get_edt_full(test_data)
        edt_gt, surf_gt = self._get_edt_full(gt_data)

        effective_surf_test = surf_test * effective_data
        effective_surf_gt = surf_gt * effective_data

        # For debug the effective surface.
        # effective_surf_combine_output_path = test_mask.get_path() + '_effsur.nii.gz'
        # combine_effective = effective_surf_test
        # np.copyto(combine_effective, 2 * effective_surf_gt, where=effective_surf_gt > 0.5)
        # test_mask.save_scan_same_space(effective_surf_combine_output_path, combine_effective)

        surf_dist_map_gt2test = effective_surf_gt * edt_test
        surf_dist_map_test2gt = effective_surf_test * edt_gt

        num_surface_test = effective_surf_test.sum()
        num_surface_gt = effective_surf_gt.sum()

        msd_sym = (surf_dist_map_gt2test.sum() / num_surface_gt) + \
                  (surf_dist_map_test2gt.sum() / num_surface_test)
        msd_sym /= 2
        hd_sym = np.amax(surf_dist_map_gt2test) + np.amax(surf_dist_map_test2gt)
        hd_sym /= 2

        result = {
            'Scan': test_mask.get_file_name(),
            'MSD': msd_sym,
            'HD': hd_sym,
            'effective surface points (test)': effective_surf_test.sum(),
            'effective ratio (test)': effective_surf_test.sum() / surf_test.sum(),
            'effective surface points (gt)': effective_surf_gt.sum(),
            'effective ratio (gt)': effective_surf_gt.sum() / surf_gt.sum()
        }

        return result


    @staticmethod
    def _get_edt_full(mask_img_data):
        """
        To get edt on both sides of the boundary, and the boundary itself as a second mask.
        :param img_data:
        :return:
        """
        invert_mask = np.ones(mask_img_data.shape)
        invert_mask = invert_mask - mask_img_data

        edt_img = ndi.distance_transform_edt(mask_img_data)
        edt_invert_img = ndi.distance_transform_edt(invert_mask)

        edt_full = edt_img + edt_invert_img

        boundary_mask = (edt_full < 1.5).astype(int)

        return edt_full, boundary_mask


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--in-effective-mask-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--gt-mask', type=str)
    parser.add_argument('--out-csv', type=str)
    parser.add_argument('--num-process', type=int, default=25)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    in_effective_mask_folder_obj = DataFolder(args.in_effective_mask_folder, args.file_list_txt)
    dice_cal = GetMeanSurfaceDist(in_folder_obj, in_effective_mask_folder_obj, args.num_process, args.gt_mask)
    dice_cal.get_surface_metric()
    dice_cal.save_csv(args.out_csv)


if __name__ == '__main__':
    main()
