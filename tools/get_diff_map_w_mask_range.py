import argparse
from data_io import DataFolder, ScanWrapper, ScanWrapperWithMask
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


class ClipPlotSeries:
    def __init__(self,
                 in_img_path,
                 in_mask_path,
                 step_axial,
                 step_sagittal,
                 step_coronal,
                 num_clip,
                 vmin, vmax, unit_label):
        self._in_img_path = in_img_path
        self._in_mask_path = in_mask_path
        self._step_axial = step_axial
        self._step_sagittal = step_sagittal
        self._step_coronal = step_coronal
        self._num_clip = num_clip
        self._vmin = vmin
        self._vmax = vmax
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
        in_mask_obj = ScanWrapper(self._in_mask_path)

        in_img_data = in_img_obj.get_data()
        in_mask_data = in_mask_obj.get_data()

        masked_img_data = np.zeros(in_img_data.shape, dtype=float)
        masked_img_data.fill(np.nan)
        masked_img_data[in_mask_data == 1] = in_img_data[in_mask_data == 1]
        # masked_img_data[masked_img_data != masked_img_data] = self._vmin

        self._plot_view(
            self._num_clip,
            self._step_axial,
            masked_img_data,
            'axial',
            out_png_folder
        )

        self._plot_view(
            self._num_clip,
            self._step_sagittal,
            masked_img_data,
            'sagittal',
            out_png_folder
        )

        self._plot_view(
            self._num_clip,
            self._step_coronal,
            masked_img_data,
            'coronal',
            out_png_folder
        )

    def _plot_view(self,
                   num_clip,
                   step_clip,
                   in_img_data,
                   view_flag,
                   out_png_folder):
        for clip_idx in range(num_clip):
            clip_off_set = (clip_idx - 2) * step_clip
            img_slice = self._clip_image(in_img_data, view_flag, clip_off_set)

            fig, ax = plt.subplots()
            plt.axis('off')
            im = ax.imshow(img_slice,
                      interpolation='none',
                      cmap='jet',
                      norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                      alpha=1)

            divider = make_axes_locatable(ax)
            cax = divider.append_axes("right", size="5%", pad=0.05)

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

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-img1', type=str)
    parser.add_argument('--in-img2', type=str)
    parser.add_argument('--in-mask', type=str)
    parser.add_argument('--out-img', type=str)
    parser.add_argument('--vmin', type=float, default=-1000)
    parser.add_argument('--vmax', type=float, default=500)
    args = parser.parse_args()

    in_img1 = ScanWrapperWithMask(args.in_img1, args.in_mask)
    in_img2 = ScanWrapperWithMask(args.in_img2, args.in_mask)

    img1_vec = in_img1.get_data_flat()
    img2_vec = in_img2.get_data_flat()

    # clip
    img1_vec[img1_vec > args.vmax] = args.vmax
    img1_vec[img1_vec < args.vmin] = args.vmin
    img2_vec[img2_vec > args.vmax] = args.vmax
    img2_vec[img2_vec < args.vmin] = args.vmin

    diff_vec = img1_vec - img2_vec

    in_img1.save_scan_flat_img(diff_vec, args.out_img)


if __name__ == '__main__':
    main()
