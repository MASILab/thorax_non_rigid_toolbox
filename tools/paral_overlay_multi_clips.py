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


logger = get_logger('Plot - Overlay')


class Overlay3Views(AbstractParallelRoutine):
    def __init__(self,
                 in_ori_folder_obj,
                 in_affine_folder_obj,
                 in_warped_folder_obj,
                 out_png_folder_obj,
                 ref_img_obj,
                 step_axial,
                 step_sagittal,
                 step_coronal,
                 num_process):
        super().__init__(in_ori_folder_obj, num_process)
        self._in_affine_folder = in_affine_folder_obj
        self._in_warped_folder = in_warped_folder_obj
        self._out_png_folder = out_png_folder_obj
        self._ref_img = ref_img_obj
        self._vmin = -1000
        self._vmax = 500
        self._sub_title_font_size = 70
        self._checkerboard_n_tiles = (10, 10)
        self._out_dpi = 15
        self._ref_cm = 'jet'
        self._moving_cm = 'hsv'
        self._num_plot_per_view = 4
        self._step_axial = step_axial
        self._step_sagittal = step_sagittal
        self._step_coronal = step_coronal

    def _run_single_scan(self, idx):
        in_ori_image_obj = ScanWrapper(self._in_data_folder.get_file_path(idx))
        in_affine_image_obj = ScanWrapper(self._in_affine_folder.get_file_path(idx))
        in_warped_image_obj = ScanWrapper(self._in_warped_folder.get_file_path(idx))

        num_view = 3
        num_clip = 5

        fig = plt.figure(figsize=(num_view * 100, num_clip * 30))
        gs1 = gridspec.GridSpec(num_clip, self._num_plot_per_view * num_view)
        gs1.update(wspace=0.025, hspace=0.05)

        self._plot_view(num_clip,
                        step_clip=self._step_axial,
                        in_ori_data=in_ori_image_obj.get_data(),
                        in_affine_data=in_affine_image_obj.get_data(),
                        in_warped_data=in_warped_image_obj.get_data(),
                        gs=gs1,
                        plot_column=0,
                        view_flag='Axial')

        self._plot_view(num_clip,
                        step_clip=self._step_sagittal,
                        in_ori_data=in_ori_image_obj.get_data(),
                        in_affine_data=in_affine_image_obj.get_data(),
                        in_warped_data=in_warped_image_obj.get_data(),
                        gs=gs1,
                        plot_column=1,
                        view_flag='Sagittal')

        self._plot_view(num_clip,
                        step_clip=self._step_coronal,
                        in_ori_data=in_ori_image_obj.get_data(),
                        in_affine_data=in_affine_image_obj.get_data(),
                        in_warped_data=in_warped_image_obj.get_data(),
                        gs=gs1,
                        plot_column=2,
                        view_flag='Coronal')

        fig.suptitle(f'{self._in_data_folder.get_file_name(idx)}',
                     y=0.9,
                     fontsize=2 * self._sub_title_font_size,
                     va='center')

        out_png = self._out_png_folder.get_file_path(idx)
        logger.info(f'Save png to {out_png}')
        plt.savefig(out_png, bbox_inches='tight', pad_inches=0, dpi=self._out_dpi)
        plt.close(fig=fig)

    def _plot_view(self, num_clip, step_clip, in_ori_data, in_affine_data, in_warped_data, gs, plot_column, view_flag):
        for clip_idx in range(num_clip):
            clip_off_set = (clip_idx - 2) * step_clip
            ori_slice = self._clip_image(in_ori_data, view_flag, offset=clip_off_set)
            affine_slice = self._clip_image(in_affine_data, view_flag, offset=clip_off_set)
            warped_slice = self._clip_image(in_warped_data, view_flag, offset=clip_off_set)
            ref_slice = self._clip_image(self._ref_img.get_data(), view_flag, offset=clip_off_set)

            plt.axis('off')

            # Ori
            ax0 = plt.subplot(gs[clip_idx, self._num_plot_per_view * plot_column])
            plt.axis('off')
            plt.imshow(ori_slice,
                       interpolation='none',
                       cmap=self._moving_cm,
                       norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                       alpha=1)
            ax0.set_title(f'original ({clip_off_set})', fontsize=self._sub_title_font_size)

            # Ref
            ax1 = plt.subplot(gs[clip_idx, self._num_plot_per_view * plot_column + 1])
            plt.axis('off')
            plt.imshow(ref_slice,
                       interpolation='none',
                       cmap=self._ref_cm,
                       norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                       alpha=1)
            ax1.set_title(f'{view_flag}, reference ({clip_off_set})', fontsize=self._sub_title_font_size)

            # Affine
            # ax2 = plt.subplot(gs[clip_idx, self._num_plot_per_view * plot_column + 2])
            # plt.axis('off')
            # plt.imshow(affine_slice,
            #            interpolation='none',
            #            cmap=self._moving_cm,
            #            norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
            #            alpha=1)
            # ax2.set_title(f'affine ({clip_off_set})', fontsize=self._sub_title_font_size)

            # Affine + ref
            ax2 = plt.subplot(gs[clip_idx, self._num_plot_per_view * plot_column + 2])
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
            ax2.set_title(f'affine + ref ({clip_off_set})', fontsize=self._sub_title_font_size)

            # warped + ref
            ax3 = plt.subplot(gs[clip_idx, self._num_plot_per_view * plot_column + 3])
            plt.axis('off')
            # plt.imshow(slice_warped_rgb, alpha=0.8)
            plt.imshow(warped_slice,
                       interpolation='none',
                       cmap=self._moving_cm,
                       norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                       alpha=0.3)
            plt.imshow(ref_slice,
                       interpolation='none',
                       cmap=self._ref_cm,
                       norm=colors.Normalize(vmin=self._vmin, vmax=self._vmax),
                       alpha=0.3)
            ax3.set_title(f'warped + ref ({clip_off_set})', fontsize=self._sub_title_font_size)

    def _plot_view_checkerboard(self, num_clip, step_clip, in_ori_data, in_warped_data, gs, plot_column, view_flag):
        for clip_idx in range(num_clip):
            clip_off_set = (clip_idx - 2) * step_clip
            ori_slice = self._clip_image(in_ori_data, view_flag, offset=clip_off_set)
            warped_slice = self._clip_image(in_warped_data, view_flag, offset=clip_off_set)
            ref_slice = self._clip_image(self._ref_img.get_data(), view_flag, offset=clip_off_set)

            jet_cm = plt.get_cmap('jet')
            gray_cm = plt.get_cmap('gray')

            slice_ori_rescale = exposure.rescale_intensity(ori_slice,
                                                           in_range=(self._vmin, self._vmax),
                                                           out_range=(0, 1))
            # slice_ori_rgb = color.gray2rgba(slice_ori_rescale)
            slice_ori_rgb = jet_cm(slice_ori_rescale)

            slice_warped_rescale = exposure.rescale_intensity(warped_slice,
                                                              in_range=(self._vmin, self._vmax),
                                                              out_range=(0, 1))
            # slice_warped_rgb = color.gray2rgb(slice_warped_rescale)
            slice_warped_rgb = jet_cm(slice_warped_rescale)

            slice_ref_rescale = exposure.rescale_intensity(ref_slice,
                                                           in_range=(self._vmin, self._vmax),
                                                           out_range=(0, 1))
            # slice_ref_rgb = color.gray2rgb(slice_ref_rescale)
            slice_ref_rgb = gray_cm(slice_ref_rescale)

            ori_ref_checkerboard = np.zeros(slice_ref_rgb.shape)
            warped_ref_checkerboard = np.zeros(slice_ref_rgb.shape)
            for dim in range(slice_ref_rgb.shape[2]):
                ori_ref_checkerboard[:, :, dim] = \
                    compare_images(slice_ori_rgb[:, :, dim],
                                   slice_ref_rgb[:, :, dim],
                                   method='checkerboard',
                                   n_tiles=self._checkerboard_n_tiles)
                warped_ref_checkerboard[:, :, dim] = \
                    compare_images(slice_warped_rgb[:, :, dim],
                                   slice_ref_rgb[:, :, dim],
                                   method='checkerboard',
                                   n_tiles=self._checkerboard_n_tiles)

            plt.axis('off')

            # Ori + ref
            ax0 = plt.subplot(gs[clip_idx, 2 * plot_column])
            plt.axis('off')
            plt.imshow(ori_ref_checkerboard)
            ax0.set_title(f'{view_flag}, ori + ref ({clip_off_set})', fontsize=self._sub_title_font_size)

            # warped + ref
            ax1 = plt.subplot(gs[clip_idx, 2 * plot_column + 1])
            plt.axis('off')
            plt.imshow(warped_ref_checkerboard)
            ax1.set_title(f'{view_flag}, warped + ref ({clip_off_set})', fontsize=self._sub_title_font_size)

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
    parser.add_argument('--in-ori-folder', type=str)
    parser.add_argument('--in-affine-folder')
    parser.add_argument('--in-warped-folder', type=str)
    parser.add_argument('--ref-img', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--out-png-folder', type=str)
    parser.add_argument('--step-axial', type=int, default=50)
    parser.add_argument('--step-sagittal', type=int, default=75)
    parser.add_argument('--step-coronal', type=int, default=30)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_ori_folder_obj = DataFolder(args.in_ori_folder, args.file_list_txt)
    in_affine_folder_obj = DataFolder(args.in_affine_folder, args.file_list_txt)
    in_warped_folder_obj = DataFolder(args.in_warped_folder, args.file_list_txt)
    out_png_folder_obj = DataFolder(args.out_png_folder, args.file_list_txt)
    out_png_folder_obj.change_suffix('.png')
    ref_img = ScanWrapper(args.ref_img)

    exe_obj = Overlay3Views(in_ori_folder_obj,
                            in_affine_folder_obj,
                            in_warped_folder_obj,
                            out_png_folder_obj,
                            ref_img,
                            args.step_axial,
                            args.step_sagittal,
                            args.step_coronal,
                            args.num_process)
    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
