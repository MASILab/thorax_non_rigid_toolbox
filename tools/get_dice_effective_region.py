import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice, get_logger
from paral import AbstractParallelRoutine
import pandas as pd
import numpy as np
from scipy import ndimage as ndi


logger = get_logger('Dice')


class GetDiceEffectiveRegion(AbstractParallelRoutine):
    def __init__(self,
                 in_ori_folder_obj,
                 in_ref_valid_mask,
                 num_process,
                 out_folder_obj,
                 etch_radius):
        super().__init__(in_ori_folder_obj, num_process)
        self._in_ref_valid_mask = ScanWrapper(in_ref_valid_mask)
        self._out_folder_obj = out_folder_obj
        self._etch_radius = etch_radius

    def _run_single_scan(self, idx):
        in_ori_image = ScanWrapper(self._in_data_folder.get_file_path(idx))
        in_ori_data = in_ori_image.get_data()
        in_effective_mask = (in_ori_data == in_ori_data).astype(int)

        effective_region_mask = in_effective_mask * self._in_ref_valid_mask.get_data()

        # We need to make sure the boundary elements are all 0
        boundary_mask = np.zeros(in_ori_image.get_shape())
        boundary_mask[1:-1, 1:-1, 1:-1] = 1
        effective_region_mask = effective_region_mask * boundary_mask
        edt_img = ndi.distance_transform_edt(effective_region_mask)
        effective_region_mask = (edt_img > self._etch_radius).astype(int)

        out_mask_path = self._out_folder_obj.get_file_path(idx)
        in_ori_image.save_scan_same_space(out_mask_path, effective_region_mask)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-ori-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--in-ref-valid-mask', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--etch-radius', type=int)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_ori_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)
    effect_region = GetDiceEffectiveRegion(
        in_folder_obj,
        args.in_ref_valid_mask,
        args.num_process,
        out_folder_obj,
        args.etch_radius
    )

    effect_region.run_parallel()


if __name__ == '__main__':
    main()
