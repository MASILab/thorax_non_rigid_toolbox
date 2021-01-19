import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import pandas as pd
import os
import subprocess
from parse import parse
from fit_circle import fit_circle_algebraic
import matplotlib.pyplot as plt
from matplotlib import colors
from utils import mkdir_p


logger = get_logger('Inference the CT native padding mask')


def get_pad_mask2(in_native_nii, out_mask_nii):
    in_native_obj = ScanWrapper(in_native_nii)
    in_native_img = in_native_obj.get_data()

    print(in_native_img.shape)
    z_variance_map = np.var(in_native_img, axis=2)
    print(z_variance_map.shape)

    slice_pad_region = (z_variance_map == 0).astype(int)

    mask_img = np.zeros(in_native_img.shape, dtype=int)
    for z_idx in range(mask_img.shape[2]):
        mask_img[:, :, z_idx] = slice_pad_region

    in_native_obj.save_scan_same_space(out_mask_nii, mask_img)

    return np.sum(slice_pad_region) != 0


def clip_overlay_with_mask(in_nii, in_mask, out_png):
    # Only do the clip on axial plane.
    print(f'reading {in_nii}')
    print(f'reading {in_mask}')
    in_img = ScanWrapper(in_nii).get_data()
    in_mask_img = ScanWrapper(in_mask).get_data()
    clip_in_img = in_img[:, :, int(in_img.shape[2] / 2.0)]
    clip_in_img = np.rot90(clip_in_img)
    clip_in_img = np.concatenate([clip_in_img, clip_in_img], axis=1)

    clip_mask_img = in_mask_img[:, :, int(in_img.shape[2] / 2.0)]
    clip_mask_img = np.rot90(clip_mask_img)
    clip_mask_img = np.concatenate(
        [np.zeros((in_img.shape[0], in_img.shape[1]), dtype=int),
         clip_mask_img], axis=1
    )
    clip_mask_img = clip_mask_img.astype(float)

    clip_mask_img[clip_mask_img == 0] = np.nan

    vmin_img = -1200
    vmax_img = 600

    fig, ax = plt.subplots()
    plt.axis('off')
    ax.imshow(
        clip_in_img,
        interpolation='bilinear',
        cmap='gray',
        norm=colors.Normalize(vmin=vmin_img, vmax=vmax_img),
        alpha=0.8)
    ax.imshow(
        clip_mask_img,
        interpolation='none',
        cmap='Reds',
        norm=colors.Normalize(vmin=0, vmax=1),
        alpha=0.5
    )

    print(f'Save to {out_png}')
    plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=150)


class ParalPPVMask(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_mask_folder_obj,
                 out_label_folder_obj,
                 out_clip_png_folder_obj,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self.out_mask_folder_obj = out_mask_folder_obj
        self.out_label_folder_obj = out_label_folder_obj
        self.out_clip_png_folder_obj = out_clip_png_folder_obj

    def _run_single_scan(self, idx):
        try:
            in_nii = self._in_data_folder.get_file_path(idx)
            out_mask_nii = self.out_mask_folder_obj.get_file_path(idx)
            out_png = self.out_clip_png_folder_obj.get_file_path(idx)

            if get_pad_mask2(in_nii, out_mask_nii):
                out_label_file = self.out_label_folder_obj.get_file_path(idx)
                cmd_str = f'touch {out_label_file}'
                print(cmd_str)
                os.system(cmd_str)

            clip_overlay_with_mask(in_nii, out_mask_nii, out_png)
        except:
            print(f'Something wrong with {self._in_data_folder.get_file_path}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str,
                        default='/nfs/masi/xuk9/SPORE/data/data_flat')
    parser.add_argument('--out-mask-folder', type=str,
                        default='/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region2')
    parser.add_argument('--out-label-folder', type=str,
                        default='/nfs/masi/xuk9/SPORE/data/PPV_cases')
    parser.add_argument('--out-clip-png-folder', type=str,
                        default='/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region_clip_png2')
    parser.add_argument('--file-list-txt', type=str,
                        default='/nfs/masi/xuk9/SPORE/data/vlsp_data_list.txt')
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    mkdir_p(args.out_mask_folder)
    mkdir_p(args.out_label_folder)
    mkdir_p(args.out_clip_png_folder)

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_mask_folder_obj = DataFolder(args.out_mask_folder, args.file_list_txt)
    out_label_folder_obj = DataFolder(args.out_label_folder, args.file_list_txt)
    out_clip_png_folder_obj = DataFolder(args.out_clip_png_folder, args.file_list_txt)
    out_clip_png_folder_obj.change_suffix('.png')

    exe_obj = ParalPPVMask(
        in_folder_obj,
        out_mask_folder_obj,
        out_label_folder_obj,
        out_clip_png_folder_obj,
        args.num_process
    )

    exe_obj.run_parallel()


# def main():
#     # file_name = '00000068time20180214.nii.gz'
#     file_name = '00000001time20131205.nii.gz'
#
#     in_nii_folder = '/nfs/masi/xuk9/SPORE/data/data_flat'
#     out_mask_nii_folder = '/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region2'
#     out_png_folder = '/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region_clip_png2'
#
#     mkdir_p(out_mask_nii_folder)
#     mkdir_p(out_png_folder)
#
#     in_nii = os.path.join(in_nii_folder, file_name)
#     out_nii = os.path.join(out_mask_nii_folder, file_name)
#     out_png = os.path.join(out_png_folder, file_name.replace('.nii.gz', '.png'))
#
#     get_pad_mask2(in_nii, out_nii)
#     clip_overlay_with_mask(in_nii, out_nii, out_png)


if __name__ == '__main__':
    main()
