from data_io import ScanWrapperWithMask, load_object
import numpy as np
import argparse
import pandas as pd
import pickle
from utils import get_logger
import os


logger = get_logger('VoxelwiseRegression')


class VoxelwiseRegression:
    def __init__(self,
                 in_image_data_matrix,
                 file_list,
                 ref_img_obj,
                 clinical_df):
        self._in_data_matrix = in_image_data_matrix
        self._file_list = file_list
        self._ref_img_obj = ref_img_obj
        self._clinical_df = clinical_df

    def create_regression_map_continue(self, field_flag, out_path):
        field_value_list, effective_file_idx_list = self._get_field_value_list_continue(field_flag)
        self._create_regression_map(field_value_list, effective_file_idx_list, out_path)

    def create_regression_map_discrete(self, field_flag, out_path):
        field_value_list, effective_file_idx_list = self._get_field_value_list_discrete(field_flag)
        self._create_regression_map(field_value_list, effective_file_idx_list, out_path)

    def _create_regression_map(self, field_value_list, effective_file_idx_list, out_path):
        print(f'Number of effective files: {len(effective_file_idx_list)}')

        x_list = field_value_list
        x_centered = x_list - np.mean(x_list)
        print(f'x_centered.shape: {x_centered.shape}')

        x_rsquare = np.sum(x_centered ** 2)

        y_data = self._in_data_matrix[effective_file_idx_list, :]

        y_mean = np.mean(y_data, axis=0)
        print(f'y_mean.shape: {y_mean.shape}')
        y_data = y_data - y_mean
        print(f'y_data.shape: {y_data.shape}')

        beta_list = y_data.transpose().dot(x_centered) / x_rsquare

        self._ref_img_obj.save_scan_flat_img(beta_list, out_path)

    def _get_field_value_list_continue(self, field_flag):
        field_value_list = np.zeros((len(self._file_list),), dtype=float)

        for idx_file in range(len(self._file_list)):
            file_name = self._file_list[idx_file]
            # print(file_name)
            # print(idx_file)
            field_value_list[idx_file] = self._clinical_df.loc[file_name, field_flag]

        effective_file_idx_list = range(len(self._file_list))

        return field_value_list, effective_file_idx_list

    def _get_field_value_list_discrete(self, field_flag):
        effective_file_flag_list = np.zeros((len(self._file_list),))
        effective_file_flag_list.fill(np.nan)
        for idx_file in range(len(self._file_list)):
            file_name = self._file_list[idx_file]
            field_value = self._convert_discrete_field_value_to_number(
                field_flag,
                self._clinical_df.loc[file_name, field_flag]
            )
            if field_value is not None:
                effective_file_flag_list[idx_file] = field_value

        effective_idx_list = np.where(effective_file_flag_list == effective_file_flag_list)

        return effective_file_flag_list[effective_idx_list], effective_idx_list[0]

    def _convert_discrete_field_value_to_number(self, field_flag, field_value):
        if field_flag == 'copd':
            if field_value == 'No':
                return 0
            elif field_value == 'Yes':
                return 1
            else:
                return None

        if field_flag == 'ctscannermake':
            if field_value == 'General Electric':
                return 0
            elif field_value == 'Phillips':
                return 1
            else:
                return None

        if field_flag == 'Coronary Artery Calcification':
            if field_value == 'Mild':
                return 0
            elif field_value == 'None':
                return 0
            elif field_value == 'Moderate':
                return 1
            elif field_value == 'Severe':
                return 1
            else:
                return None

        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-data-bin', type=str)
    parser.add_argument('--mask-img', type=str)
    parser.add_argument('--out-folder', type=str)
    parser.add_argument('--in-csv', type=str)
    args = parser.parse_args()

    logger.info(f'Reading csv from {args.in_csv}')
    clinical_df = pd.read_csv(args.in_csv, index_col=0)

    print(clinical_df)

    logger.info(f'Create ref image using mask {args.mask_img}')
    ref_img_obj = ScanWrapperWithMask(args.mask_img, args.mask_img)

    # binary data obj created by create_masked_feature_data_bin.py
    in_data = load_object(args.in_data_bin)

    regress_obj = VoxelwiseRegression(
        in_data['data_matrix'],
        in_data['file_list'],
        ref_img_obj,
        clinical_df
    )

    regress_obj.create_regression_map_continue(
        'bmi',
        os.path.join(args.out_folder, 'bmi.nii.gz')
    )

    regress_obj.create_regression_map_continue(
        'Age',
        os.path.join(args.out_folder, 'age.nii.gz')
    )

    regress_obj.create_regression_map_continue(
        'packyearsreported',
        os.path.join(args.out_folder, 'packyear.nii.gz')
    )

    regress_obj.create_regression_map_discrete(
        'copd',
        os.path.join(args.out_folder, 'copd.nii.gz')
    )

    regress_obj.create_regression_map_discrete(
        'ctscannermake',
        os.path.join(args.out_folder, 'vender.nii.gz')
    )

    regress_obj.create_regression_map_discrete(
        'Coronary Artery Calcification',
        os.path.join(args.out_folder, 'cac.nii.gz')
    )


if __name__ == '__main__':
    main()