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
from skimage.measure import label, regionprops
import nibabel as nib
from scipy.interpolate import interp1d
import cv2 as cv
from utils import read_file_contents_list


logger = get_logger('Clip with mask')


def _clip_image(image_data, clip_plane, num_clip=1, idx_clip=0):
    im_shape = image_data.shape

    # Get clip offset
    idx_dim = -1
    if clip_plane == 'sagittal':
        idx_dim = 0
    elif clip_plane == 'coronal':
        idx_dim = 1
    elif clip_plane == 'axial':
        idx_dim = 2
    else:
        raise NotImplementedError

    clip_step_size = int(float(im_shape[idx_dim]) / (num_clip + 1))
    offset = -int(float(im_shape[idx_dim]) / 2) + (idx_clip + 1) * clip_step_size

    clip_location = int(im_shape[idx_dim] / 2) - 1 + offset

    clip = None
    if clip_plane == 'sagittal':
        clip = image_data[clip_location, :, :]
        clip = np.flip(clip, 0)
        clip = np.rot90(clip)
    elif clip_plane == 'coronal':
        clip = image_data[:, clip_location, :]
        clip = np.rot90(clip)
    elif clip_plane == 'axial':
        clip = image_data[:, :, clip_location]
        clip = np.rot90(clip)
    else:
        raise NotImplementedError

    return clip


def _clip_image_loc(image_data, clip_plane, loc_vec, p_marker=False):
    im_shape = image_data.shape

    # Get clip offset
    idx_dim = -1
    if clip_plane == 'sagittal':
        idx_dim = 0
    elif clip_plane == 'coronal':
        idx_dim = 1
    elif clip_plane == 'axial':
        idx_dim = 2
    else:
        raise NotImplementedError

    clip = None
    if clip_plane == 'sagittal':
        clip = image_data[loc_vec[idx_dim], :, :]
        if p_marker:
            clip[loc_vec[1], :] = 600
            clip[:, loc_vec[2]] = 600
        clip = np.flip(clip, 0)
        clip = np.rot90(clip)
    elif clip_plane == 'coronal':
        clip = image_data[:, loc_vec[idx_dim], :]
        if p_marker:
            clip[loc_vec[0], :] = 600
            clip[:, loc_vec[2]] = 600
        clip = np.rot90(clip)
    elif clip_plane == 'axial':
        clip = image_data[:, :, loc_vec[idx_dim]]
        if p_marker:
            clip[loc_vec[0], :] = 600
            clip[:, loc_vec[1]] = 600
        clip = np.rot90(clip)
    else:
        raise NotImplementedError

    return clip


def _pad_to(in_clip, pad_dim_x, pad_dim_y):
    dim_x, dim_y = in_clip.shape[0], in_clip.shape[1]
    dim_x_pad_before = int((pad_dim_x - dim_x) / 2)
    dim_x_pad_after = (pad_dim_x - dim_x) - dim_x_pad_before
    dim_y_pad_before = int((pad_dim_y - dim_y) / 2)
    dim_y_pad_after = (pad_dim_y - dim_y) - dim_y_pad_before
    out_pad = np.pad(in_clip, ((dim_x_pad_before, dim_x_pad_after),
                               (dim_y_pad_before, dim_y_pad_after)),
                     constant_values=0)
    return out_pad


def _clip_image_location_triplanar(in_nii, in_mask, loc_vec, out_png):
    loc_vec = np.asarray(loc_vec).astype(int)

    # Tripalner plot on that location, scaled by the true dimension
    image_obj = nib.load(in_nii)

    in_img = image_obj.get_data()
    mask_img = nib.load(in_mask).get_data()
    mask_img = np.flip(mask_img, axis=1)
    pixdim = image_obj.header['pixdim'][1:4]

    dim_physical = np.multiply(np.array(in_img.shape), pixdim).astype(int)
    print(f'Physical dimensions:')
    print(dim_physical)

    max_dim = np.max(np.array(dim_physical))

    view_flag_list = ['sagittal', 'coronal', 'axial']
    img_clip_list = []
    mask_clip_list = []

    normalizer = interp1d([-1000, 600], [0, 255])
    for idx_view in range(len(view_flag_list)):
        view_flag = view_flag_list[idx_view]
        clip_list = []

        clip = _clip_image_loc(in_img, view_flag, loc_vec, p_marker=True)
        clip_mask = _clip_image_loc(mask_img, view_flag, loc_vec)

        clip = np.clip(clip, -1000, 600)
        clip = normalizer(clip)
        if view_flag == 'sagittal':
            clip = cv.resize(clip, (dim_physical[1], dim_physical[2]), interpolation=cv.INTER_CUBIC)
            clip_mask = cv.resize(clip_mask, (dim_physical[1], dim_physical[2]), interpolation=cv.INTER_NEAREST)
        elif view_flag == 'coronal':
            clip = cv.resize(clip, (dim_physical[0], dim_physical[2]), interpolation=cv.INTER_CUBIC)
            clip_mask = cv.resize(clip_mask, (dim_physical[0], dim_physical[2]), interpolation=cv.INTER_NEAREST)
        elif view_flag == 'axial':
            clip = cv.resize(clip, (dim_physical[0], dim_physical[1]), interpolation=cv.INTER_CUBIC)
            clip_mask = cv.resize(clip_mask, (dim_physical[0], dim_physical[1]), interpolation=cv.INTER_NEAREST)
        clip = _pad_to(clip, max_dim, max_dim)
        clip = np.clip(clip, 0, 255)
        clip = np.uint8(clip)

        clip_mask = _pad_to(clip_mask, max_dim, max_dim)

        img_clip_list.append(clip)
        mask_clip_list.append(clip_mask)

    img_show = np.concatenate(img_clip_list, axis=1)
    mask_show = np.concatenate(mask_clip_list, axis=1)

    img_show = np.concatenate([img_show, img_show], axis=0)
    mask_show = np.concatenate([
        np.zeros(mask_show.shape, dtype=int),
        mask_show
    ], axis=0)

    fig, ax = plt.subplots()
    plt.axis('off')
    ax.imshow(
        img_show,
        interpolation='bilinear',
        cmap='gray',
        norm=colors.Normalize(vmin=0, vmax=255),
        alpha=0.8)
    mask_show = mask_show.astype(float)
    mask_show[mask_show == 0] = np.nan
    ax.imshow(
        mask_show,
        interpolation='none',
        cmap='jet',
        norm=colors.Normalize(vmin=0, vmax=1),
        alpha=0.5
    )

    print(f'Save to {out_png}')
    plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=300)
    plt.close()


def clip_connected_component_bb_center_with_mask(in_nii, in_mask, out_folder):
    mkdir_p(out_folder)

    # Find the connected components,
    in_img = ScanWrapper(in_nii).get_data()
    in_mask_img = ScanWrapper(in_mask).get_data()

    in_mask_img = np.flip(in_mask_img, axis=1)
    connected_label, num_label = label(in_mask_img, return_num=True)
    props = regionprops(connected_label)

    # Clip at the centers
    for idx_component in range(num_label):
        center = props[idx_component].centroid
        print(center)

        out_png = os.path.join(out_folder, f'component.{idx_component}.png')
        _clip_image_location_triplanar(in_nii, in_mask, center, out_png)


def multiple_clip_overlay_with_mask(in_nii, in_mask, out_png, dim_x=4, dim_y=4, view_flag='axial'):
    num_clip = dim_x * dim_y
    print(f'reading {in_nii}')
    print(f'reading {in_mask}')
    in_img = ScanWrapper(in_nii).get_data()
    in_mask_img = ScanWrapper(in_mask).get_data()

    # Hot fix, need to revert the y dim.
    in_mask_img = np.flip(in_mask_img, axis=1)

    clip_in_img_list = []
    clip_mask_img_list = []
    for idx_clip in range(num_clip):
        clip_in_img = _clip_image(in_img, view_flag, num_clip, idx_clip)
        clip_shape = clip_in_img.shape
        clip_in_img = np.concatenate([clip_in_img, clip_in_img], axis=1)

        clip_mask_img = _clip_image(in_mask_img, view_flag, num_clip, idx_clip)
        # clip_mask_img = np.concatenate(
        #     [np.zeros((in_img.shape[0], in_img.shape[1]), dtype=int),
        #      clip_mask_img], axis=1
        # )
        clip_mask_img = np.concatenate(
            [np.zeros((clip_shape[0], clip_shape[1]), dtype=int),
             clip_mask_img], axis=1
        )
        clip_mask_img = clip_mask_img.astype(float)
        clip_mask_img[clip_mask_img == 0] = np.nan

        clip_in_img_list.append(clip_in_img)
        clip_mask_img_list.append(clip_mask_img)

    in_img_row_list = []
    mask_img_row_list = []
    for idx_row in range(dim_y):
        in_img_block_list = []
        mask_img_block_list = []
        for idx_column in range(dim_x):
            in_img_block_list.append(clip_in_img_list[idx_column + dim_x * idx_row])
            mask_img_block_list.append(clip_mask_img_list[idx_column + dim_x * idx_row])
        in_img_row = np.concatenate(in_img_block_list, axis=1)
        mask_img_row = np.concatenate(mask_img_block_list, axis=1)
        in_img_row_list.append(in_img_row)
        mask_img_row_list.append(mask_img_row)

    in_img_plot = np.concatenate(in_img_row_list, axis=0)
    mask_img_plot = np.concatenate(mask_img_row_list, axis=0)

    vmin_img = -1000
    vmax_img = 600

    fig, ax = plt.subplots()
    plt.axis('off')
    ax.imshow(
        in_img_plot,
        interpolation='bilinear',
        cmap='gray',
        norm=colors.Normalize(vmin=vmin_img, vmax=vmax_img),
        alpha=0.8)
    ax.imshow(
        mask_img_plot,
        interpolation='none',
        cmap='jet',
        norm=colors.Normalize(vmin=np.min(in_mask_img), vmax=np.max(in_mask_img)),
        alpha=0.5
    )

    print(f'Save to {out_png}')
    plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=300)
    plt.close()


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
        cmap='jet',
        norm=colors.Normalize(vmin=np.min(in_mask_img), vmax=np.max(in_mask_img)),
        alpha=0.5
    )

    print(f'Save to {out_png}')
    plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=150)
    plt.close()


class ParalPPVMask(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_mask_folder_obj,
                 out_clip_png_folder_obj,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self.out_mask_folder_obj = out_mask_folder_obj
        self.out_clip_png_folder_obj = out_clip_png_folder_obj

    def _run_single_scan(self, idx):
        try:
            in_nii = self._in_data_folder.get_file_path(idx)
            out_mask_nii = self.out_mask_folder_obj.get_file_path(idx)
            out_png = self.out_clip_png_folder_obj.get_file_path(idx)

            # clip_overlay_with_mask(in_nii, out_mask_nii, out_png)
            multiple_clip_overlay_with_mask(in_nii, out_mask_nii, out_png)
        except:
            print(f'Something wrong with {self._in_data_folder.get_file_path}')


# def main():
#     parser = argparse.ArgumentParser()
#     parser.add_argument('--in-folder', type=str,
#                         default='/nfs/masi/xuk9/SPORE/data/data_flat')
#     parser.add_argument('--in-mask-folder', type=str,
#                         default='/nfs/masi/xuk9/src/lungmask/SPORE/lung_mask_nii')
#     parser.add_argument('--out-clip-png-folder', type=str,
#                         default='/nfs/masi/xuk9/src/lungmask/SPORE/lung_mask_nii_clip_png')
#     parser.add_argument('--file-list-txt', type=str,
#                         default='/nfs/masi/xuk9/SPORE/data/vlsp_data_list.txt')
#     parser.add_argument('--num-process', type=int, default=1)
#     args = parser.parse_args()
#
#     mkdir_p(args.in_mask_folder)
#     mkdir_p(args.out_clip_png_folder)
#
#     in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
#     out_mask_folder_obj = DataFolder(args.in_mask_folder, args.file_list_txt)
#     out_clip_png_folder_obj = DataFolder(args.out_clip_png_folder, args.file_list_txt)
#     out_clip_png_folder_obj.change_suffix('.png')
#
#     exe_obj = ParalPPVMask(
#         in_folder_obj,
#         out_mask_folder_obj,
#         out_clip_png_folder_obj,
#         args.num_process
#     )
#
#     exe_obj.run_parallel()


def main():
    # file_name = 'sub-S03174_ses-E06315_run-7_bp-chest_ct.nii'
    # file_name = 'sub-S03591_ses-E07300_run-3_bp-chest_ct.nii'
    # file_name = '00000001time20131205.nii.gz'

    # file_name_list_txt = '/nfs/masi/COVID19_public/BIMCV-COVID19/ct_cxr_pair/data/centaur_pilot.24.file_list'
    file_name_list_txt = '/nfs/masi/COVID19_public/TCIA_COVID_19_CT/COVID-19-20_miccai/COVID-19-20_v2/ct_list.txt'
    file_name_list = read_file_contents_list(file_name_list_txt)

    # in_nii_folder = '/nfs/masi/COVID19_public/BIMCV-COVID19/ct_cxr_pair/data/ct'
    # out_mask_nii_folder = '/nfs/masi/COVID19_public/BIMCV-COVID19/ct_cxr_pair/data/centaur_pilot.24'
    # out_png_folder = '/nfs/masi/COVID19_public/BIMCV-COVID19/ct_cxr_pair/data/centaur_pilot.24.clip'

    in_nii_folder = '/nfs/masi/COVID19_public/TCIA_COVID_19_CT/COVID-19-20_miccai/COVID-19-20_v2/Train'
    out_mask_nii_folder = '/nfs/masi/COVID19_public/TCIA_COVID_19_CT/COVID-19-20_miccai/COVID-19-20_v2/Train'
    out_png_folder = '/nfs/masi/COVID19_public/TCIA_COVID_19_CT/COVID-19-20_miccai/COVID-19-20_v2/clip_png'

    mkdir_p(out_png_folder)

    for file_name in file_name_list:
        in_nii = os.path.join(in_nii_folder, file_name)
        mask_nii = os.path.join(out_mask_nii_folder, file_name.replace('_ct.', '_seg.'))
        # out_png = os.path.join(out_png_folder, file_name.replace('.nii', '.png'))

        # get_pad_mask2(in_nii, out_nii)
        # out_axial_png = os.path.join(out_png_folder, file_name.replace('.nii', '_axial.png'))
        # multiple_clip_overlay_with_mask(in_nii, out_nii, out_axial_png, view_flag='axial')
        #
        # out_sagittal_png = os.path.join(out_png_folder, file_name.replace('.nii', '_sagittal.png'))
        # multiple_clip_overlay_with_mask(in_nii, out_nii, out_sagittal_png, view_flag='sagittal')
        #
        # out_coronal_png = os.path.join(out_png_folder, file_name.replace('.nii', '_coronal.png'))
        # multiple_clip_overlay_with_mask(in_nii, out_nii, out_coronal_png, view_flag='coronal')

        out_folder = os.path.join(out_png_folder, file_name)
        clip_connected_component_bb_center_with_mask(in_nii, mask_nii, out_folder)


if __name__ == '__main__':
    main()
