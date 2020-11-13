import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors
import os
from utils import mkdir_p
from mpl_toolkits.axes_grid1 import make_axes_locatable


logger = get_logger('Clip 2d plot')


def clip_image(image_data, clip_plane, offset=0):
    im_shape = image_data.shape
    clip = None
    if clip_plane == 'sagittal':
        clip = image_data[int(im_shape[0] / 2) - 1 + offset, :, :]
        clip = np.flip(clip, 0)
        clip = np.rot90(clip)
    elif clip_plane == 'coronal':
        clip = image_data[:, int(im_shape[1] / 2) - 1 + offset, :]
        print(int(im_shape[1] / 2) - 1 + offset)
        # print(clip.shape)
        # x_idx = 91 - 1
        # y_idx = 62 - 1
        # x_max = 190
        # y_max = 145
        # x_idx_r = x_max - x_idx
        # y_idx_r = y_max - y_idx
        # clip[y_idx, x_idx] = -2000
        # clip[y_idx, x_idx_r] = -1000
        # clip[y_idx_r, x_idx] = 1000
        # clip[y_idx_r, x_idx_r] = 2000
        clip = np.rot90(clip)
        clip = np.flip(clip, axis=1)
    elif clip_plane == 'axial':
        clip = image_data[:, :, int(im_shape[2] / 2) - 1 + offset]
        clip = np.rot90(clip)
    else:
        raise NotImplementedError

    return clip


class ParalClipPlot(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 offset_axial,
                 offset_sagittal,
                 offset_coronal,
                 vmin, vmax,
                 unit_label,
                 num_process
                 ):
        super().__init__(in_folder_obj, num_process)
        self._out_folder_obj = out_folder_obj
        self._offset_axial = offset_axial
        self._offset_sagittal = offset_sagittal
        self._offset_coronal = offset_coronal
        self._vmin = vmin
        self._vmax = vmax
        self._sub_title_font_size = 70
        self._unit_label = unit_label

    def _run_single_scan(self, idx):
        im_obj = ScanWrapper(self._in_data_folder.get_file_path(idx))
        in_img_data = im_obj.get_data()

        out_png_prefix = self._out_folder_obj.get_file_path(idx)

        # self._plot_view(
        #     self._offset_axial,
        #     in_img_data,
        #     'axial',
        #     out_png_prefix
        # )
        #
        # self._plot_view(
        #     self._offset_sagittal,
        #     in_img_data,
        #     'sagittal',
        #     out_png_prefix
        # )

        self._plot_view(
            self._offset_coronal,
            in_img_data,
            'coronal',
            out_png_prefix
        )

    def _plot_view(self,
                   offset,
                   in_img_data,
                   view_flag,
                   out_png_prefix):
        img_slice = clip_image(in_img_data, view_flag, offset)

        fig, ax = plt.subplots()
        plt.axis('off')
        im = ax.imshow(
            img_slice,
            interpolation='bilinear',
            cmap='jet',
            norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
            alpha=1)

        p_cac_project = False
        if p_cac_project:
            # draw a cross to indicate the location of calcium centroid.
            x_idx = 91
            y_idx = 62
            x_max = 190
            y_max = 145
            x_idx = x_max - x_idx
            y_idx = y_max - y_idx
            ax.plot(
                [y_idx, y_idx],
                [0, x_max],
                linestyle='--',
                color='r',
                alpha=0.3
            )
            ax.plot(
                [0, y_max],
                [x_idx, x_idx],
                linestyle='--',
                color='r',
                alpha=0.3
            )
            ax.set_xlim(0, y_max)
            ax.set_ylim(x_max, 0)

        if self._unit_label is not None:
            divider = make_axes_locatable(ax)
            cax = divider.append_axes("right", size="5%", pad=0.05)

            cb = plt.colorbar(im, cax=cax)
            cb.set_label(self._unit_label)


        out_png_path = out_png_prefix + f'_{view_flag}.png'
        logger.info(f'Save png to {out_png_path}')
        plt.savefig(out_png_path, bbox_inches='tight', pad_inches=0)
        plt.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    # parser.add_argument(
    #     '--in-mask',
    #     type=str,
    #     default=None,
    #     help='If is none, the orignal input images will be used'
    # )
    parser.add_argument('--file-list', type=str)
    parser.add_argument('--out-png-folder', type=str)
    parser.add_argument('--offset-axial', type=int, default=0)
    parser.add_argument('--offset-sagittal', type=int, default=0)
    parser.add_argument('--offset-coronal', type=int, default=0)
    parser.add_argument('--vmin', type=float, default=-1000)
    parser.add_argument('--vmax', type=float, default=500)
    parser.add_argument(
        '--unit-label',
        type=str,
        default=None,
        help='If none, the color bar will be omitted.'
    )
    parser.add_argument('--num-process', type=str, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list)
    out_folder_obj = DataFolder(args.out_png_folder, args.file_list)
    out_folder_obj.change_suffix('')

    mkdir_p(args.out_png_folder)

    plot_obj = ParalClipPlot(
        in_folder_obj,
        out_folder_obj,
        args.offset_axial,
        args.offset_sagittal,
        args.offset_coronal,
        args.vmin,
        args.vmax,
        args.unit_label,
        args.num_process
    )

    plot_obj.run_parallel()


if __name__ == '__main__':
    main()
