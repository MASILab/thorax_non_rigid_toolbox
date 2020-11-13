import argparse
import numpy as np
import nibabel as nib
from data_io import DataFolder, ScanWrapper
import os
from paral import AbstractParallelRoutine
from utils import get_logger

logger = get_logger('Average')


class AverageValidRegion(AbstractParallelRoutine):
    def __init__(self, in_folder_obj, num_process):
        super().__init__(in_folder_obj, num_process)
        self._ref_img = ScanWrapper(self._in_data_folder.get_first_path())
        self._sum_map = None
        self._average_map = None
        self._sum_variance_map = None
        self._variance_map = None
        self._valid_count_map = None
        self._run_mode = None

    def run_get_average(self):
        logger.info('Calculating average')

        self._run_mode = 'get_average'
        result_list = self.run_parallel()

        im_shape = self._ref_img.get_shape()
        self._sum_map = np.zeros(im_shape)
        self._valid_count_map = np.zeros(im_shape)

        for result in result_list:
            self._sum_map += result['sum_image']
            self._valid_count_map += result['region_count']

        average_image = np.zeros(im_shape)
        average_image = np.divide(
            self._sum_map,
            self._valid_count_map,
            out=average_image,
            where=self._valid_count_map > 0.5
        )
        self._average_map = average_image

    def run_get_variance(self):
        logger.info('Calculating variance')
        self._run_mode = 'get_variance'
        result_list = self.run_parallel()
        im_shape = self._ref_img.get_shape()
        self._sum_variance_map = np.zeros(im_shape)

        for result in result_list:
            self._sum_variance_map += result['sum_image']

        self._variance_map = np.zeros(im_shape)
        self._variance_map = np.divide(
            self._sum_variance_map,
            self._valid_count_map,
            out=self._variance_map,
            where=self._valid_count_map > 0.5
        )
        epsilon = 1.0e-5
        self._variance_map = np.log10(np.add(self._variance_map, epsilon))

    def output_result_folder(self, output_folder, ambient_val):
        average_img_path = os.path.join(output_folder, 'average.nii.gz')
        variance_img_path = os.path.join(output_folder, 'variance.nii.gz')
        count_map_path = os.path.join(output_folder, 'count_map.nii.gz')

        average_image_out_data = np.ma.masked_array(self._average_map, mask=self._valid_count_map == 0)
        variance_image_out_data = np.ma.masked_array(self._variance_map, mask=self._valid_count_map == 0)

        self._ref_img.save_scan_same_space(average_img_path, average_image_out_data.filled(ambient_val))
        self._ref_img.save_scan_same_space(variance_img_path, variance_image_out_data.filled(ambient_val))
        self._ref_img.save_scan_same_space(count_map_path, self._valid_count_map)

    def output_variance(self, variance_path, ambient_val):
        variance_image_out_data = np.ma.masked_array(self._variance_map, mask=self._valid_count_map == 0)
        self._ref_img.save_scan_same_space(variance_path, variance_image_out_data.filled(ambient_val))

    def _run_chunk(self, chunk_list):
        result_list = []
        if self._run_mode == 'get_average':
            result_list = self._run_chunk_get_average(chunk_list)
        elif self._run_mode == 'get_variance':
            result_list = self._run_chunk_get_variance(chunk_list)
        else:
            logger.info('Into the error')
            raise NotImplementedError

        return result_list

    def _run_chunk_get_average(self, chunk_list):
        result_list = []
        im_shape = self._ref_img.get_shape()
        sum_image_union = np.zeros(im_shape)
        region_mask_count_image = np.zeros(im_shape)
        for idx in chunk_list:
            self._in_data_folder.print_idx(idx)
            img_obj = ScanWrapper(self._in_data_folder.get_file_path(idx))
            img_data = img_obj.get_data()
            valid_mask = np.logical_not(np.isnan(img_data)).astype(int)
            np.add(img_data, sum_image_union, out=sum_image_union, where=valid_mask > 0)
            region_mask_count_image += valid_mask

        result = {
            'sum_image': sum_image_union,
            'region_count': region_mask_count_image
        }

        result_list.append(result)
        return result_list

    def _run_chunk_get_variance(self, chunk_list):
        result_list = []
        im_shape = self._ref_img.get_shape()
        sum_image_union = np.zeros(im_shape)
        for idx in chunk_list:
            self._in_data_folder.print_idx(idx)
            img_obj = ScanWrapper(self._in_data_folder.get_file_path(idx))
            img_data = img_obj.get_data()
            valid_mask = np.logical_not(np.isnan(img_data)).astype(int)

            residue_map = np.zeros(img_data.shape)
            np.subtract(img_data, self._average_map, out=residue_map, where=valid_mask > 0)
            residue_map = np.power(residue_map, 2)
            np.add(residue_map, sum_image_union, out=sum_image_union, where=valid_mask > 0)

        result = {
            'sum_image': sum_image_union
        }

        result_list.append(result)
        return result_list


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--out-variance-path', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--num-process', type=int, default=10)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    exe_obj = AverageValidRegion(in_folder_obj, args.num_process)

    exe_obj.run_get_average()
    exe_obj.run_get_variance()
    exe_obj.output_variance(args.out_variance_path, np.nan)


if __name__ == '__main__':
    main()