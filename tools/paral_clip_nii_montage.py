import cv2 as cv
import numpy as np
import nibabel as nib
from paral import AbstractParallelRoutine
from data_io import DataFolder, ScanWrapper
import argparse


class ClipMontagePlotNII:
    def __init__(
            self,
            num_clip,
            vmin, vmax
    ):
        self._num_clip = num_clip
        self._vmin = vmin
        self._vmax = vmax

    def clip_plot(
            self,
            in_nii,
            out_png
    ):
        montage_image = self._get_concatenated_nii_montage(in_nii)

        print(f'Output montage image to {out_png}')
        cv.imwrite(out_png, montage_image)

    def clip_plot_combine_cxr(
            self,
            in_nii,
            in_cxr,
            out_png
    ):
        ct_montage_image = self._get_concatenated_nii_montage(in_nii)

        dim_size = ct_montage_image.shape[0]
        print(f'Load {in_cxr}')
        cxr_image = cv.imread(in_cxr, cv.IMREAD_UNCHANGED)
        cxr_image = cv.resize(cxr_image, dsize=(dim_size, dim_size), interpolation=cv.INTER_CUBIC)

        concate_image = np.concatenate([ct_montage_image, cxr_image], axis=1)
        print(f'Write png to {out_png}')
        cv.imwrite(out_png, concate_image)

    def _get_concatenated_nii_montage(
            self,
            in_nii
    ):
        print(f'Load {in_nii}')
        image_obj = nib.load(in_nii)
        in_data = image_obj.get_data()

        pixdim = image_obj.header['pixdim'][1:4]

        dim_x, dim_y, dim_z = np.multiply(np.array(in_data.shape), pixdim).astype(int)

        # pixdim_xy = image_obj.header['pixdim'][2]
        # z_scale_ratio = pixdim_z / pixdim_xy
        # print(f'z_scale_ratio: {z_scale_ratio:.2f}')
        print(f'Input dimensions:')
        print(in_data.shape)
        # z_dim = int(z_scale_ratio * in_data.shape[2])
        # xy_dim = in_data.shape[0]

        # dim_vector = [in_data.shape[0], in_data.shape[1], z_dim]
        dim_vector = [dim_x, dim_y, dim_z]
        print(f'After normalization')
        print(dim_vector)
        # max_dim = np.max(np.array(in_data.shape))
        max_dim = np.max(np.array(dim_vector))

        # Step.1 Get all clip.
        # Step.2 Pad to the same size (cv2)
        # Step.3 Concatenate into montage view

        view_flag_list = ['sagittal', 'coronal', 'axial']
        view_image_list = []
        for idx_view in range(len(view_flag_list)):
            view_flag = view_flag_list[idx_view]
            clip_list = []
            for idx_clip in range(self._num_clip):
                clip = self._clip_image(in_data, view_flag, self._num_clip, idx_clip)
                clip = self._rescale_to_0_255(clip, self._vmin, self._vmax)
                # if (view_flag == 'sagittal') | (view_flag == 'coronal'):
                #     clip = cv.resize(clip, (xy_dim, z_dim), interpolation=cv.INTER_CUBIC)
                if view_flag == 'sagittal':
                    clip = cv.resize(clip, (dim_y, dim_z), interpolation=cv.INTER_CUBIC)
                elif view_flag == 'coronal':
                    clip = cv.resize(clip, (dim_x, dim_z), interpolation=cv.INTER_CUBIC)
                elif view_flag == 'axial':
                    clip = cv.resize(clip, (dim_x, dim_y), interpolation=cv.INTER_CUBIC)
                clip = self._pad_to(clip, max_dim, max_dim)
                clip = np.clip(clip, 0, 255)
                clip = np.uint8(clip)
                clip_list.append(clip)
            view_image = np.concatenate(clip_list, axis=1)
            view_image_list.append(view_image)

        montage_image = np.concatenate(view_image_list, axis=0)
        montage_image = cv.resize(montage_image, dsize=(self._num_clip * 512, 3 * 512),
                                  interpolation=cv.INTER_NEAREST)

        return montage_image

    @staticmethod
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

    @staticmethod
    def _rescale_to_0_255(in_img_data, vmin, vmax):
        img_data = np.clip(in_img_data, vmin, vmax)
        cv.normalize(img_data, img_data, 0, 255, cv.NORM_MINMAX)

        return img_data

    @staticmethod
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


class ParalClipMontagePlotNII(AbstractParallelRoutine):
    def __init__(self,
                 in_folder_obj,
                 out_folder_obj,
                 num_clip,
                 vmin, vmax,
                 num_process):
        super().__init__(in_folder_obj, num_process)
        self._out_folder_obj = out_folder_obj
        self._num_clip = num_clip
        self._vmin = vmin
        self._vmax = vmax

    def _run_single_scan(self, idx):
        plot_obj = ClipMontagePlotNII(self._num_clip, self._vmin, self._vmax)

        in_nii = self._in_data_folder.get_file_path(idx)
        out_path = self._out_folder_obj.get_file_path(idx)

        plot_obj.clip_plot(in_nii, out_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str, help='Folder of NIFTI files')
    parser.add_argument('--out-folder', type=str, help='Output folder')
    parser.add_argument('--file-list-txt', type=str, help='List of filename in plain txt')
    parser.add_argument('--num-clip', type=int, help='Number of clip on each direction')
    parser.add_argument('--vmin', type=float, default=-1000)
    parser.add_argument('--vmax', type=float, default=600)
    parser.add_argument('--num-process', type=int, default=10, help='Number of cores')
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    out_folder_obj = DataFolder(args.out_folder, args.file_list_txt)
    out_folder_obj.change_suffix('.png')

    exe_obj = ParalClipMontagePlotNII(
        in_folder_obj,
        out_folder_obj,
        args.num_clip,
        args.vmin, args.vmax,
        args.num_process
    )

    exe_obj.run_parallel()


if __name__ == '__main__':
    main()
