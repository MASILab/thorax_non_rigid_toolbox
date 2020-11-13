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


class ClipPlotSeriesWithTransField:
    def __init__(self,
                 in_img_path,
                 in_mask_path,
                 in_back_img_path,
                 in_trans_img_path,
                 step_axial,
                 step_sagittal,
                 step_coronal,
                 num_clip,
                 vmin, vmax,
                 vmin_back, vmax_back,
                 sample_distance
                 ):
        self._in_img_path = in_img_path
        self._in_mask_path = in_mask_path
        self._in_back_img_path = in_back_img_path
        self._in_trans_img_path = in_trans_img_path
        self._step_axial = step_axial
        self._step_sagittal = step_sagittal
        self._step_coronal = step_coronal
        self._num_clip = num_clip
        self._vmin = vmin
        self._vmax = vmax
        self._vmin_back = vmin_back
        self._vmax_back = vmax_back
        self._sub_title_font_size = 70
        self._sample_distance = sample_distance
        self._scale = 1
        self._upper = 50

    def clip_plot(self, out_png_folder):
        in_img_obj = ScanWrapper(self._in_img_path)
        in_mask_obj = ScanWrapper(self._in_mask_path)
        in_back_obj = ScanWrapper(self._in_back_img_path)
        in_trans_obj = ScanWrapper(self._in_trans_img_path)

        in_img_data = in_img_obj.get_data()
        in_mask_data = in_mask_obj.get_data()
        in_back_data = in_back_obj.get_data()
        in_trans_data = in_trans_obj.get_data()

        # masked_img_data = np.zeros(in_img_data.shape, dtype=float)
        # masked_img_data.fill(np.nan)
        # masked_img_data[in_mask_data == 1] = in_img_data[in_mask_data == 1]
        # masked_back_data = np.zeros(in_back_data.shape, dtype=float)
        # masked_back_data.fill(np.nan)
        # masked_back_data[in_mask_data == 1] = in_back_data[in_mask_data == 1]

        masked_img_data = in_img_data
        masked_back_data = in_back_data

        masked_trans_data = self._mask_in_trans_data(in_trans_data, in_mask_data)
        in_trans_data = masked_trans_data

        self._plot_view(
            self._num_clip,
            self._step_axial,
            masked_img_data,
            masked_back_data,
            in_trans_data,
            'axial',
            out_png_folder
        )

        self._plot_view(
            self._num_clip,
            self._step_sagittal,
            masked_img_data,
            masked_back_data,
            in_trans_data,
            'sagittal',
            out_png_folder
        )

        self._plot_view(
            self._num_clip,
            self._step_coronal,
            masked_img_data,
            masked_back_data,
            in_trans_data,
            'coronal',
            out_png_folder
        )

    def _plot_view(self,
                   num_clip,
                   step_clip,
                   in_img_data,
                   in_back_data,
                   in_trans_data,
                   view_flag,
                   out_png_folder):
        for clip_idx in range(num_clip):
            clip_off_set = (clip_idx - 2) * step_clip
            img_slice = self._clip_image(in_img_data, view_flag, clip_off_set)
            back_slice = self._clip_image(in_back_data, view_flag, clip_off_set)

            trans_x, trans_y, trans_u, trans_v, trans_c = \
                self._clip_trans_field(in_trans_data, view_flag, clip_off_set)

            fig, ax = plt.subplots()
            plt.axis('off')

            im_back = ax.imshow(
                back_slice,
                interpolation='none',
                cmap='hsv',
                norm=colors.Normalize(vmin=self._vmin_back, vmax=self._vmax_back),
                alpha=0.3
            )

            im = ax.imshow(
                img_slice,
                interpolation='none',
                cmap='jet',
                norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                alpha=0.3
            )

            quiver_img = ax.quiver(
                trans_x,
                trans_y,
                trans_u,
                trans_v,
                trans_c,
                norm=colors.Normalize(vmin=0, vmax=self._upper),
                cmap='jet',
                angles='xy',
                scale_units='xy',
                scale=self._scale
            )

            divider = make_axes_locatable(ax)
            cax = divider.append_axes("right", size="5%", pad=0.05)

            cb = plt.colorbar(quiver_img, cax=cax)
            cb.set_label('Displacement magnitude [mm]')
            out_png_path = os.path.join(out_png_folder, f'{view_flag}_{clip_idx}.png')
            plt.savefig(out_png_path, bbox_inches='tight', pad_inches=0, dpi=150)

    @staticmethod
    def _mask_in_trans_data(trans_data, mask_img_data):
        masked_trans_data = trans_data
        masked_trans_data[mask_img_data == 0, 0, :] = np.nan
        return masked_trans_data

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

        print(clip.shape)
        return clip

    def _clip_trans_field(self, trans_data, clip_plane, offset=0):
        """
        :param trans_data:
        :param clip_plane:
        :param offset:
        :return: the 2D transformation field for each view.
        """
        clip = ClipPlotSeriesWithTransField._clip_image(trans_data, clip_plane, offset)

        # clip_trans_x = range(0, clip.shape[0], self._sample_distance)
        # clip_trans_y = range(0, clip.shape[1], self._sample_distance)
        clip_trans_x = list(reversed(range(0, clip.shape[0], self._sample_distance)))
        clip_trans_y = list(reversed(range(0, clip.shape[1], self._sample_distance)))
        clip_trans_x, clip_trans_y = np.meshgrid(clip_trans_x, clip_trans_y)
        clip_trans_u = None
        clip_trans_v = None
        clip_trans_w = None
        clip_trans_c = None
        if clip_plane == 'sagittal':
            clip_trans_u = -clip[clip_trans_x, clip_trans_y, 0, 1]
            clip_trans_v = -clip[clip_trans_x, clip_trans_y, 0, 2]
            clip_trans_w = clip[clip_trans_x, clip_trans_y, 0, 0]
        elif clip_plane == 'axial':
            clip_trans_u = -clip[clip_trans_x, clip_trans_y, 0, 0]
            clip_trans_v = -clip[clip_trans_x, clip_trans_y, 0, 1]
            clip_trans_w = clip[clip_trans_x, clip_trans_y, 0, 2]
        elif clip_plane == 'coronal':
            clip_trans_u = -clip[clip_trans_x, clip_trans_y, 0, 0]
            clip_trans_v = -clip[clip_trans_x, clip_trans_y, 0, 2]
            clip_trans_w = clip[clip_trans_x, clip_trans_y, 0, 1]
        else:
            raise NotImplementedError

        clip_trans_c = np.sqrt(clip_trans_u**2 + clip_trans_v**2 + clip_trans_w**2)

        # return clip_trans_x, clip_trans_y, clip_trans_u, clip_trans_v, clip_trans_c
        return clip_trans_y, clip_trans_x, clip_trans_u, clip_trans_v, clip_trans_c

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-img', type=str)
    parser.add_argument('--in-mask', type=str)
    parser.add_argument('--in-back-img', type=str)
    parser.add_argument('--in-trans-file', type=str)
    parser.add_argument('--step-axial', type=int, default=50)
    parser.add_argument('--step-sagittal', type=int, default=75)
    parser.add_argument('--step-coronal', type=int, default=30)
    parser.add_argument('--out-png-folder', type=str)
    parser.add_argument('--vmin', type=float, default=-1000)
    parser.add_argument('--vmax', type=float, default=500)
    parser.add_argument('--vmin-back', type=float, default=-1000)
    parser.add_argument('--vmax-back', type=float, default=500)
    parser.add_argument('--num-clip', type=int, default=5)
    parser.add_argument('--sample-distance', type=int, default=10)
    args = parser.parse_args()

    mkdir_p(args.out_png_folder)
    plot_obj = ClipPlotSeriesWithTransField(
        args.in_img,
        args.in_mask,
        args.in_back_img,
        args.in_trans_file,
        args.step_axial,
        args.step_sagittal,
        args.step_coronal,
        args.num_clip,
        args.vmin,
        args.vmax,
        args.vmin_back,
        args.vmax_back,
        args.sample_distance
    )
    plot_obj.clip_plot(args.out_png_folder)


if __name__ == '__main__':
    main()
