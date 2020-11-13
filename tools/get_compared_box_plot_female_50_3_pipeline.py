import argparse
from matplotlib import cm
from utils import get_logger
import pandas as pd
from utils import read_file_contents_list
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.gridspec as gridspec


logger = get_logger('Plot')


class DSCBoxPlot:
    def __init__(self,
                 data_df):
        self._data_df = data_df

    def plot_box(self, out_png):
        fig = plt.figure(figsize=(15, 8))

        ax1 = plt.subplot()
        # sns.boxplot(x='Registration pipeline', y='Dice', hue='Mask type', data=self._data_df)
        sns.boxplot(x='Mask type', y='Dice', hue='Registration pipeline', data=self._data_df)

        logger.info(f'Save to {out_png}')
        plt.savefig(out_png, bbox_inches='tight', pad_inches=0.05)
        plt.close()

    @staticmethod
    def create_dsc_box_plot_obj(
            lung_dsc_df_list,
            body_dsc_df_list,
            pipeline_label_list
    ):
        num_test = len(lung_dsc_df_list)
        dict_list = []

        for idx_test in range(num_test):
            dict_list += DSCBoxPlot.get_dict_list_group(
                lung_dsc_df_list[idx_test],
                pipeline_label_list[idx_test],
                'lung mask'
            )
            dict_list += DSCBoxPlot.get_dict_list_group(
                body_dsc_df_list[idx_test],
                pipeline_label_list[idx_test],
                'body mask'
            )

        data_df = pd.DataFrame(dict_list)

        return DSCBoxPlot(data_df)

    @staticmethod
    def get_dict_list_group(dsc_df, pipeline_flag, mask_flag):
        dict_list = []

        dsc_array = dsc_df['Dice'].to_numpy()

        print(pipeline_flag)
        print(mask_flag)
        print(f'mean: {np.mean(dsc_array)}, std: {np.std(dsc_array)}')
        print()

        for scan_idx in range(len(dsc_array)):
            dict_item = {
                'Registration pipeline': pipeline_flag,
                'Mask type': mask_flag,
                'Dice': dsc_array[scan_idx]
            }
            dict_list.append(dict_item)

        return dict_list


def read_dsc_list(in_csv_file):
    logger.info(f'Read {in_csv_file}')
    return pd.read_csv(in_csv_file)['Dice'].to_numpy()


def print_statics(flag_str, in_data_array):
    print(f'============ ({flag_str})')
    print(f'Mean: {np.mean(in_data_array)}')
    print(f'STD: {np.std(in_data_array)}')
    print(f'============ ({flag_str})')
    print()


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--num-test', type=int)
    parser.add_argument('--csv-lung-mask-list', nargs='+', type=str)
    parser.add_argument('--csv-body-mask-list', nargs='+', type=str)
    parser.add_argument('--pipeline-label-list', nargs='+', type=str)
    parser.add_argument('--out-png', type=str)
    args = parser.parse_args()

    lung_mask_csv_list = args.csv_lung_mask_list
    body_mask_csv_list = args.csv_body_mask_list
    pipeline_label_list = args.pipeline_label_list

    lung_mask_dsc_df_list = [pd.read_csv(csv_path) for csv_path in lung_mask_csv_list]
    body_mask_dsc_df_list = [pd.read_csv(csv_path) for csv_path in body_mask_csv_list]

    dsc_box_plot_obj = DSCBoxPlot.create_dsc_box_plot_obj(
        lung_mask_dsc_df_list,
        body_mask_dsc_df_list,
        pipeline_label_list
    )

    dsc_box_plot_obj.plot_box(args.out_png)


if __name__ == '__main__':
    main()
