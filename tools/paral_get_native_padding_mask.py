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


logger = get_logger('Inference the CT native padding mask')


def get_ct_pixel_pad_circle_fit(in_nii):
    in_obj = ScanWrapper(in_nii)
    in_data = in_obj.get_data()

    print(in_data.shape)
    middle_slice = in_data[:, :, int(in_data.shape[2] / 2)]
    print(middle_slice.shape)

    # Get 4 walls
    w_x_0 = in_data[0, :, :]
    w_x_1 = in_data[-1, :, :]
    w_y_0 = in_data[:, 0, :]
    w_y_1 = in_data[:, -1, :]

    w_x_0_p = (w_x_0 <= -1024).astype(int)
    w_x_1_p = (w_x_1 <= -1024).astype(int)
    w_y_0_p = (w_y_0 <= -1024).astype(int)
    w_y_1_p = (w_y_1 <= -1024).astype(int)

    w_x_0_acc = np.prod(w_x_0_p, axis=1)
    w_x_1_acc = np.prod(w_x_1_p, axis=1)
    w_y_0_acc = np.prod(w_y_0_p, axis=1)
    w_y_1_acc = np.prod(w_y_1_p, axis=1)

    if (np.sum(w_x_0_acc) + np.sum(w_x_1_acc) + np.sum(w_y_0_acc) + np.sum(w_y_1_acc)) == 0:
        print(f'No padding region detected')
        return None

    # Find the circle center coordinate.
    w_x_0_valid = np.where(w_x_0_acc == 0)
    w_x_1_valid = np.where(w_x_1_acc == 0)
    w_y_0_valid = np.where(w_y_0_acc == 0)
    w_y_1_valid = np.where(w_y_1_acc == 0)

    # Assume the valid region will reach the boundary on 4 sides.
    center_x = None
    center_y = None
    radius = 0

    # Get the set of intersection
    intersect_pos_list = []
    if len(w_x_0_valid) > 0:
        if np.max(w_x_0_valid) < in_data.shape[1] - 1:
            intersect_pos_list.append({
                'x': 0,
                'y': np.max(w_x_0_valid)
            })
        if np.min(w_x_0_valid) > 0:
            intersect_pos_list.append({
                'x': 0,
                'y': np.min(w_x_0_valid)
            })

    if len(w_x_1_valid) > 0:
        if np.max(w_x_1_valid) < in_data.shape[1] - 1:
            intersect_pos_list.append({
                'x': in_data.shape[0] - 1,
                'y': np.max(w_x_1_valid)
            })
        if np.min(w_x_1_valid) > 0:
            intersect_pos_list.append({
                'x': in_data.shape[0] - 1,
                'y': np.min(w_x_1_valid)
            })

    if len(w_y_0_valid) > 0:
        if np.max(w_y_0_valid) < in_data.shape[0] - 1:
            intersect_pos_list.append({
                'x': np.max(w_y_0_valid),
                'y': 0
            })
        if np.min(w_y_0_valid) > 0:
            intersect_pos_list.append({
                'x': np.min(w_y_0_valid),
                'y': 0
            })

    if len(w_y_1_valid) > 0:
        if np.max(w_y_1_valid) < in_data.shape[0] - 1:
            intersect_pos_list.append({
                'x': np.max(w_y_1_valid),
                'y': 0
            })
        if np.min(w_y_1_valid) > 0:
            intersect_pos_list.append({
                'x': np.min(w_y_1_valid),
                'y': 0
            })

    print(len(intersect_pos_list))
    print(intersect_pos_list)

    if len(intersect_pos_list) < 3:
        print(f'Not enough intercept point to fit circle')
        return None

    c_x, c_y, c_r = fit_circle_algebraic(intersect_pos_list)
    print(f'Fitted circle: (x: {c_x}; y: {c_y}; r: {c_r})')

    return c_x, c_y, c_r


def get_pad_mask(in_nii, out_nii):
    circle_info = get_ct_pixel_pad_circle_fit(in_nii)
    in_obj = ScanWrapper(in_nii)
    in_img = in_obj.get_data()
    mask_img = np.zeros(in_img.shape, dtype=int)
    if circle_info is not None:
        c_x, c_y, c_r = circle_info
        mask_slice = np.zeros((in_img.shape[0], in_img.shape[1]), dtype=int)
        for i in range(in_img.shape[0]):
            for j in range(in_img.shape[1]):
                dist2center = np.sqrt((i - c_x)**2 + (j - c_y)**2)
                if dist2center > c_r - 1:
                    mask_slice[i, j] = 1
        for k in range(in_img.shape[2]):
            mask_img[:, :, k] = mask_slice

    in_obj.save_scan_same_space(out_nii, mask_img)

    return circle_info is not None


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

            if get_pad_mask(in_nii, out_mask_nii):
                out_label_file = self.out_label_folder_obj.get_file_path(idx)
                cmd_str = f'touch {out_label_file}'
                print(cmd_str)
                os.system(cmd_str)

            clip_overlay_with_mask(in_nii, out_mask_nii, out_png)
        except:
            print(f'Something wrong with {self._in_data_folder.get_file_path}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--out-mask-folder', type=str)
    parser.add_argument('--out-label-folder', type=str)
    parser.add_argument('--out-clip-png-folder', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

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
#     out_mask_nii_folder = '/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region'
#     out_png_folder = '/nfs/masi/xuk9/SPORE/data/data_pixel_pad_region_clip_png'
#
#     in_nii = os.path.join(in_nii_folder, file_name)
#     out_nii = os.path.join(out_mask_nii_folder, file_name)
#     out_png = os.path.join(out_png_folder, file_name.replace('.nii.gz', '.png'))
#
#     get_pad_mask(in_nii, out_nii)
#     clip_overlay_with_mask(in_nii, out_nii, out_png)


if __name__ == '__main__':
    main()
