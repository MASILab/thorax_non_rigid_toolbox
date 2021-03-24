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
import nibabel as nib
from scipy import ndimage as ndi
import skimage.morphology
import skimage.measure
import argparse
import SimpleITK as sitk


logger = get_logger('Inference the CT native padding mask')


def create_body_mask(in_img, out_mask):
    rBody = 2

    print(f'Get body mask of image {in_img}')

    image_itk = sitk.ReadImage(in_img)

    gaussian_filter = sitk.DiscreteGaussianImageFilter()
    gaussian_filter.SetVariance(2)
    print(f'Apply gaussian filter')
    filtered_image = gaussian_filter.Execute(image_itk)
    image_np = sitk.GetArrayFromImage(filtered_image)

    BODY = (image_np>=-500)# & (I<=win_max)
    print(f'{np.sum(BODY)} of {np.size(BODY)} voxels masked.')
    if np.sum(BODY)==0:
      raise ValueError('BODY could not be extracted!')

    # Find largest connected component in 3D
    struct = np.ones((3,3,3),dtype=np.bool)
    BODY = ndi.binary_erosion(BODY,structure=struct,iterations=rBody)

    BODY_labels = skimage.measure.label(np.asarray(BODY, dtype=np.int))

    props = skimage.measure.regionprops(BODY_labels)
    areas = []
    for prop in props:
      areas.append(prop.area)
    print(f' -> {len(areas)} areas found.')
    # only keep largest, dilate again and fill holes
    BODY = ndi.binary_dilation(BODY_labels==(np.argmax(areas)+1),structure=struct,iterations=rBody)
    # Fill holes slice-wise
    # for z in range(0,BODY.shape[2]):
    #   BODY[:,:,z] = ndi.binary_fill_holes(BODY[:,:,z])

    for z in range(0,BODY.shape[0]):
      BODY[z,:,:] = ndi.binary_fill_holes(BODY[z,:,:])
    print(BODY.shape)

    result_out = sitk.GetImageFromArray(BODY.astype(np.int8))
    result_out.CopyInformation(image_itk)
    dilate_filter = sitk.BinaryDilateImageFilter()
    dilate_filter.SetBackgroundValue(0)
    dilate_filter.SetForegroundValue(1)
    dilate_filter.SetKernelRadius(1)
    result_out = dilate_filter.Execute(result_out)
    sitk.WriteImage(result_out, out_mask)
    # new_image = nib.Nifti1Image(BODY.astype(np.int8), header=image_nb.header, affine=image_nb.affine)
    # nib.save(new_image,out_mask)
    print(f'Generated body_mask segs in Abwall {out_mask}')


def _clip_image(image_data, num_clip=1, idx_clip=0):
    im_shape = image_data.shape

    # Get clip offset
    idx_dim = 2

    clip_step_size = int(float(im_shape[idx_dim]) / (num_clip + 1))
    offset = -int(float(im_shape[idx_dim]) / 2) + (idx_clip + 1) * clip_step_size

    clip_location = int(im_shape[idx_dim] / 2) - 1 + offset

    clip = image_data[:, :, clip_location]
    clip = np.rot90(clip)

    return clip


def clip_overlay_with_mask_n_clip(in_nii, in_mask, out_png, num_clip=10):
    print(f'reading {in_nii}')
    print(f'reading {in_mask}')
    in_img = ScanWrapper(in_nii).get_data()
    in_mask_img = ScanWrapper(in_mask).get_data()

    clip_in_img_montage = []
    clip_in_mask_montage = []

    for idx_clip in range(num_clip):
        clip_in_img = _clip_image(in_img, num_clip, idx_clip)
        clip_in_img = np.concatenate([clip_in_img, clip_in_img], axis=1)

        clip_mask_img = _clip_image(in_mask_img, num_clip, idx_clip)
        clip_mask_img = np.concatenate(
            [np.zeros((in_img.shape[0], in_img.shape[1]), dtype=int),
             clip_mask_img], axis=1
        )
        clip_mask_img = clip_mask_img.astype(float)
        clip_mask_img[clip_mask_img == 0] = np.nan

        clip_in_img_montage.append(clip_in_img)
        clip_in_mask_montage.append(clip_mask_img)

    clip_in_img_montage = np.concatenate(clip_in_img_montage, axis=0)
    clip_in_mask_montage = np.concatenate(clip_in_mask_montage, axis=0)

    vmin_img = -1200
    vmax_img = 600

    fig, ax = plt.subplots()
    plt.axis('off')
    ax.imshow(
        clip_in_img_montage,
        interpolation='bilinear',
        cmap='gray',
        norm=colors.Normalize(vmin=vmin_img, vmax=vmax_img),
        alpha=0.8)
    ax.imshow(
        clip_in_mask_montage,
        interpolation='none',
        cmap='Reds',
        norm=colors.Normalize(vmin=0, vmax=1),
        alpha=0.5
    )

    print(f'Save to {out_png}')
    plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=300)


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
    plt.close()


class ParalBodyMask(AbstractParallelRoutine):
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

            create_body_mask(in_nii, out_mask_nii)

            clip_overlay_with_mask(in_nii, out_mask_nii, out_png)
            # clip_overlay_with_mask_n_clip(in_nii, out_mask_nii, out_png, num_clip=7)
        except:
            print(f'Something wrong with {self._in_data_folder.get_file_path}')


# Clip view the downsampled
in_folder = '/nfs/masi/xuk9/src/thorax_pair_reg/data/SPORE/downsample/niftyreg_out'
mask_folder = '/nfs/masi/xuk9/src/thorax_pair_reg/data/SPORE/downsample/final_body_mask'
clip_folder = '/nfs/masi/xuk9/src/thorax_pair_reg/data/SPORE/downsample/body_mask_clip'
file_list = '/nfs/masi/xuk9/src/thorax_pair_reg/data/SPORE/file_list/male_all.txt'

# SPORE
# in_folder = '/nfs/masi/xuk9/SPORE/data/data_flat'
# mask_folder = '/nfs/masi/xuk9/SPORE/data/body_mask'
# clip_folder = '/nfs/masi/xuk9/SPORE/data/body_mask_clip_png'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str,
                        default=in_folder)
    parser.add_argument('--out-mask-folder', type=str,
                        default=mask_folder)
    parser.add_argument('--out-clip-png-folder', type=str,
                        default=clip_folder)
    parser.add_argument('--file-list-txt', type=str,
                        default=file_list)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    mkdir_p(args.out_mask_folder)
    mkdir_p(args.out_clip_png_folder)

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_mask_folder_obj = DataFolder(args.out_mask_folder, args.file_list_txt)
    out_clip_png_folder_obj = DataFolder(args.out_clip_png_folder, args.file_list_txt)
    out_clip_png_folder_obj.change_suffix('.png')

    exe_obj = ParalBodyMask(
        in_folder_obj,
        out_mask_folder_obj,
        out_clip_png_folder_obj,
        args.num_process
    )

    exe_obj.run_parallel()


# def main():
#     # file_name = '00000068time20180214.nii.gz'
#     # file_name = '00000001time20131205.nii.gz'
#     #
#     # in_nii_folder = '/nfs/masi/xuk9/SPORE/data/data_flat'
#     # out_mask_nii_folder = '/nfs/masi/xuk9/SPORE/data/body_mask'
#     # out_png_folder = '/nfs/masi/xuk9/SPORE/data/body_mask_clip_png'
#     #
#     # mkdir_p(out_mask_nii_folder)
#     # mkdir_p(out_png_folder)
#
#     # in_nii = os.path.join(in_nii_folder, file_name)
#     # out_nii = os.path.join(out_mask_nii_folder, file_name)
#     # out_png = os.path.join(out_png_folder, file_name.replace('.nii.gz', '.png'))
#     # in_nii = '/nfs/masi/xuk9/src/thorax_pair_reg/data/NLST/downsample/raw/102073time1999.nii.gz'
#     in_nii = '/nfs/masi/xuk9/src/thorax_pair_reg/data/NLST/downsample/raw/114987time1999.nii.gz'
#     out_nii = '/nfs/masi/xuk9/src/thorax_pair_reg/data/NLST/downsample/body_mask/102073time1999.nii.gz'
#     out_png = '/nfs/masi/xuk9/src/thorax_pair_reg/data/NLST/downsample/body_mask_clip/102073time1999.png'
#
#     create_body_mask(in_nii, out_nii)
#     clip_overlay_with_mask(in_nii, out_nii, out_png)


if __name__ == '__main__':
    main()
