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


logger = get_logger('Plot - Overlay')


class OverlayClip3Views:
    def __init__(
            self,
            ori_img,
            ref_img,
            affine_img,
            non_rigid_img):
        self._ori_img = ScanWrapper(ori_img).get_data()
        self._ref_img = ScanWrapper(ref_img).get_data()
        self._affine_img = ScanWrapper(affine_img).get_data()
        self._non_rigid_img = ScanWrapper(non_rigid_img).get_data()
        self._vmin = -1000
        self._vmax = 500
        self._sub_title_font_size = 70
        self._checkerboard_n_tiles = (10, 10)
        self._ref_cm = 'jet'
        self._moving_cm = 'hsv'
        self._out_dpi = 15

    def plot_3_view_clip(
            self,
            axial_offset,
            sagittal_offset,
            coronal_offset,
            out_png_folder):

        fig = plt.figure(figsize=(150, 120))

        num_overlay_views = 3
        num_views = 3
        gs = gridspec.GridSpec(num_views, num_overlay_views)
        gs.update(wspace=0.01, hspace=0.01)

        self._plot_view(axial_offset, gs, 1, 'Axial')
        self._plot_view(coronal_offset, gs, 0, 'Coronal')
        self._plot_view(sagittal_offset, gs, 2, 'Sagittal')

        out_png = os.path.join(out_png_folder, 'plot_3_view_plot.png')
        logger.info(f'Save png to {out_png}')
        plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=self._out_dpi)
        plt.close(fig=fig)

    def _plot_view(
            self,
            clip_offset,
            gs,
            plot_row,
            view_flag):
        moving_slice = self._clip_image(self._ori_img, view_flag, offset=clip_offset)
        ref_slice = self._clip_image(self._ref_img, view_flag, offset=clip_offset)
        affine_slice = self._clip_image(self._affine_img, view_flag, offset=clip_offset)
        non_rigid_slice = self._clip_image(self._non_rigid_img, view_flag, offset=clip_offset)

        # Moving + reference
        ax0 = plt.subplot(gs[plot_row, 0])
        plt.axis('off')
        plt.imshow(moving_slice,
                   interpolation='none',
                   cmap=self._moving_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)
        plt.imshow(ref_slice,
                   interpolation='none',
                   cmap=self._ref_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)

        # Affine + reference
        ax1 = plt.subplot(gs[plot_row, 1])
        plt.axis('off')
        plt.imshow(affine_slice,
                   interpolation='none',
                   cmap=self._moving_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)
        plt.imshow(ref_slice,
                   interpolation='none',
                   cmap=self._ref_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)

        # Affine + reference
        ax2 = plt.subplot(gs[plot_row, 2])
        plt.axis('off')
        plt.imshow(non_rigid_slice,
                   interpolation='none',
                   cmap=self._moving_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)
        plt.imshow(ref_slice,
                   interpolation='none',
                   cmap=self._ref_cm,
                   norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                   alpha=0.3)

    @staticmethod
    def _clip_image(image_data, clip_plane, offset=0):
        im_shape = image_data.shape
        clip = None
        if clip_plane == 'Sagittal':
            clip = image_data[int(im_shape[0] / 2) - 1 + offset, :, :]
            clip = np.flip(clip, 0)
            clip = np.rot90(clip)
        elif clip_plane == 'Coronal':
            clip = image_data[:, int(im_shape[1] / 2) - 1 + offset, :]
            clip = np.rot90(clip)
        elif clip_plane == 'Axial':
            clip = image_data[:, :, int(im_shape[2] / 2) - 1 + offset]
            clip = np.rot90(clip)
        else:
            raise NotImplementedError

        return clip


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-ori-img', type=str)
    parser.add_argument('--in-ref-img', type=str)
    parser.add_argument('--in-affine', type=str)
    parser.add_argument('--in-non-rigid', type=str)
    parser.add_argument('--out-png-folder', type=str)
    parser.add_argument('--axial-offset', type=int)
    parser.add_argument('--coronal-offset', type=int)
    parser.add_argument('--sagittal-offset', type=int)
    args = parser.parse_args()

    exe_obj = OverlayClip3Views(
        args.in_ori_img,
        args.in_ref_img,
        args.in_affine,
        args.in_non_rigid)

    exe_obj.plot_3_view_clip(
        args.axial_offset,
        args.coronal_offset,
        args.sagittal_offset,
        args.out_png_folder
    )


if __name__ == '__main__':
    main()
