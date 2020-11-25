import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import matplotlib.pyplot as plt
from skimage import color, exposure
from matplotlib import colors
import matplotlib.gridspec as gridspec
from skimage.util import compare_images
import os
from utils import mkdir_p
from mpl_toolkits.axes_grid1 import make_axes_locatable


logger = get_logger('Plot')


class ClipPlotSeriesWithBack:
    def __init__(self,
                 in_img_path,
                 in_mask_path,
                 in_back_img_path,
                 step_axial,
                 step_sagittal,
                 step_coronal,
                 num_clip,
                 vmin, vmax,
                 vmin_back, vmax_back,
                 unit_label):
        self._in_img_path = in_img_path
        self._in_mask_path = in_mask_path
        self._in_back_img_path = in_back_img_path
        self._step_axial = step_axial
        self._step_sagittal = step_sagittal
        self._step_coronal = step_coronal
        self._num_clip = num_clip
        self._vmin = vmin
        self._vmax = vmax
        self._vmin_back = vmin_back
        self._vmax_back = vmax_back
        self._sub_title_font_size = 70
        self._unit_label = unit_label

    def clip_plot_3_view(self, out_png_folder):
        in_img_obj = ScanWrapper(self._in_img_path)
        in_mask_obj = ScanWrapper(self._in_mask_path)

        in_img_data = in_img_obj.get_data()
        in_mask_data = in_mask_obj.get_data()

        masked_img_data = np.zeros(in_img_data.shape, dtype=float)
        masked_img_data.fill(np.nan)
        masked_img_data[in_mask_data == 1] = in_img_data[in_mask_data == 1]



    def clip_plot(self, out_png_folder):
        in_img_obj = ScanWrapper(self._in_img_path)
        in_back_obj = ScanWrapper(self._in_back_img_path)

        in_img_data = in_img_obj.get_data()
        in_back_data = in_back_obj.get_data()

        masked_img_data = None
        masked_back_data = None

        if self._in_mask_path is not None:
            in_mask_obj = ScanWrapper(self._in_mask_path)
            in_mask_data = in_mask_obj.get_data()

            masked_img_data = np.zeros(in_img_data.shape, dtype=float)
            masked_img_data.fill(np.nan)
            masked_img_data[in_mask_data == 1] = in_img_data[in_mask_data == 1]

            masked_back_data = np.zeros(in_back_data.shape, dtype=float)
            masked_back_data.fill(np.nan)
            masked_back_data[in_mask_data == 1] = in_back_data[in_mask_data == 1]
        else:
            masked_img_data = in_img_data
            masked_back_data = in_back_data

        self._plot_view(
            self._num_clip,
            self._step_axial,
            masked_img_data,
            masked_back_data,
            'axial',
            out_png_folder,
            1
        )

        self._plot_view(
            self._num_clip,
            self._step_sagittal,
            masked_img_data,
            masked_back_data,
            'sagittal',
            out_png_folder,
            5.23438 / 2.28335
        )

        self._plot_view(
            self._num_clip,
            self._step_coronal,
            masked_img_data,
            masked_back_data,
            'coronal',
            out_png_folder,
            5.23438 / 2.17388
        )

    def _plot_view(self,
                   num_clip,
                   step_clip,
                   in_img_data,
                   in_back_data,
                   view_flag,
                   out_png_folder,
                   unit_ratio
                   ):
        for clip_idx in range(num_clip):
            clip_off_set = (clip_idx - 2) * step_clip
            img_slice = self._clip_image(in_img_data, view_flag, clip_off_set)
            back_slice = self._clip_image(in_back_data, view_flag, clip_off_set)

            fig, ax = plt.subplots()
            plt.axis('off')

            im_back = ax.imshow(
                back_slice,
                interpolation='none',
                cmap='gray',
                norm=colors.Normalize(vmin=self._vmin_back, vmax=self._vmax_back),
                alpha=0.7
            )

            im = ax.imshow(
                img_slice,
                interpolation='none',
                cmap='jet',
                norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                alpha=0.5
            )

            ax.set_aspect(unit_ratio)

            if self._unit_label is not None:
                divider = make_axes_locatable(ax)
                cax = divider.append_axes("right", size="5%", pad=0.05/unit_ratio)

                cb = plt.colorbar(im, cax=cax)
                cb.set_label(self._unit_label)

            out_png_path = os.path.join(out_png_folder, f'{view_flag}_{clip_idx}.png')
            plt.savefig(out_png_path, bbox_inches='tight', pad_inches=0)

    @staticmethod
    def _clip_image(image_data, clip_plane, offset=0):
        im_shape = image_data.shape
        clip = None
        if clip_plane == 'sagittal':
            clip = image_data[int(im_shape[0] / 2) - 1 + offset, :, :]
            clip = np.flip(clip, 0)
            clip = np.rot90(clip)
        elif clip_plane == 'coronal':
            clip = image_data[:, int(im_shape[1] / 2) - 1 + offset, :]
            clip = np.rot90(clip)
        elif clip_plane == 'axial':
            clip = image_data[:, :, int(im_shape[2] / 2) - 1 + offset]
            clip = np.rot90(clip)
        else:
            raise NotImplementedError

        return clip


# in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average.nii.gz'
# in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
# out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average_png'
# vmin = 0
# vmax = 1
# vmin_back = -1000
# vmax_back = 600
# unit_label = 'Valid probability'

# in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/variance.nii.gz'
# in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
# out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/variance_png'
# vmin = -2
# vmax = -0.5
# vmin_back = -1000
# vmax_back = 600
# unit_label = 'Log variance of valid probability'

# in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_normal/average.nii.gz'
# in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
# out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_normal/average_png'
# vmin = 0
# vmax = 1
# vmin_back = -1000
# vmax_back = 600
# unit_label = 'Valid probability'
#
# in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_normal/variance.nii.gz'
# in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
# out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_normal/variance_png'
# vmin = -2
# vmax = -0.5
# vmin_back = -1000
# vmax_back = 600
# unit_label = 'Log variance of valid probability'

# in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average.nii.gz'
# in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
# out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average_png'
# vmin = 0
# vmax = 1
# vmin_back = -1000
# vmax_back = 600
# unit_label = 'Valid probability'

in_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average.nii.gz'
in_back_img = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/non_rigid_ref.nii.gz'
out_png_folder = '/nfs/masi/xuk9/SPORE/CAC_class/data/atlas/valid_region/s2_atlas_ori_valid_region_average_obese/average_png'
vmin = 0
vmax = 1
vmin_back = -1000
vmax_back = 600
unit_label = 'Valid probability'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-img', type=str, default=in_img)
    parser.add_argument('--in-mask', type=str, default=None)
    parser.add_argument('--in-back-img', type=str, default=in_back_img)
    parser.add_argument('--step-axial', type=int, default=10)
    parser.add_argument('--step-sagittal', type=int, default=35)
    parser.add_argument('--step-coronal', type=int, default=15)
    parser.add_argument('--out-png-folder', type=str, default=out_png_folder)
    parser.add_argument('--vmin', type=float, default=vmin)
    parser.add_argument('--vmax', type=float, default=vmax)
    parser.add_argument('--vmin-back', type=float, default=vmin_back)
    parser.add_argument('--vmax-back', type=float, default=vmax_back)
    parser.add_argument('--unit-label', type=str, default=unit_label)
    parser.add_argument('--num-clip', type=int, default=3)
    args = parser.parse_args()

    mkdir_p(args.out_png_folder)
    plot_obj = ClipPlotSeriesWithBack(
        args.in_img,
        args.in_mask,
        args.in_back_img,
        args.step_axial,
        args.step_sagittal,
        args.step_coronal,
        args.num_clip,
        args.vmin,
        args.vmax,
        args.vmin_back,
        args.vmax_back,
        args.unit_label
    )
    plot_obj.clip_plot(args.out_png_folder)


if __name__ == '__main__':
    main()
