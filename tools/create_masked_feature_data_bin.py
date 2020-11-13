from data_io import ScanWrapperWithMask, DataFolder, ScanWrapper
import numpy as np
from utils import get_logger
import pickle
import argparse


logger = get_logger('CreateFeatureMatrixBin')


class CreateMaskedFeatureMatrix:
    def __init__(self, in_data_folder_obj, mask_obj):
        self._in_data_folder_obj = in_data_folder_obj
        self._mask_obj = mask_obj
        self._file_list = None
        self._data_matrix = None

    def load_data(self):
        self._file_list = self._in_data_folder_obj.get_data_file_list()
        num_files = len(self._file_list)

        ref_img = ScanWrapperWithMask(
            self._in_data_folder_obj.get_file_path(0),
            self._mask_obj.get_path()
        )
        num_features = ref_img.get_number_voxel()

        self._data_matrix = np.zeros((int(num_files), int(num_features)), dtype=float)

        for idx_file in range(num_files):
            self._in_data_folder_obj.print_idx(idx_file)
            in_img = ScanWrapperWithMask(
                self._in_data_folder_obj.get_file_path(idx_file),
                self._mask_obj.get_path()
            )
            self._data_matrix[idx_file, :] = in_img.get_data_flat()

    def save_to_bin(self, bin_path):
        data_dict = {
            'file_list': self._file_list,
            'data_matrix': self._data_matrix
        }

        with open(bin_path, 'wb') as output:
            logger.info(f'Saving data obj to {bin_path}')
            pickle.dump(data_dict, output, pickle.HIGHEST_PROTOCOL)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--mask-img', type=str)
    parser.add_argument('--file-list-txt', type=str)
    parser.add_argument('--out-bin-path', type=str)
    args = parser.parse_args()

    in_folder_obj = DataFolder(args.in_folder, args.file_list_txt)
    mask_img = ScanWrapper(args.mask_img)

    creator_obj = CreateMaskedFeatureMatrix(in_folder_obj, mask_img)

    creator_obj.load_data()
    creator_obj.save_to_bin(args.out_bin_path)


if __name__ == '__main__':
    main()
