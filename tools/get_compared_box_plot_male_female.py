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
    def __init__(self, lung_data_df, body_data_df):
        self._lung_data_df = lung_data_df
        self._body_data_df = body_data_df

    def plot_box(self, out_png):
        # fig = plt.figure(figsize=(30, 15))
        fig = plt.figure(figsize=(15, 8))
        gs = gridspec.GridSpec(1, 2)

        ax1 = plt.subplot(gs[0, 0])
        sns.boxplot(x='Sex', y='Dice', hue='Group', data=self._lung_data_df)
        ax1.set_title('Lung mask DSC')

        ax2 = plt.subplot(gs[0, 1])
        sns.boxplot(x='Sex', y='Dice', hue='Group', data=self._body_data_df)
        ax2.set_title('Body mask DSC')

        logger.info(f'Save to {out_png}')
        plt.savefig(out_png, bbox_inches='tight', pad_inches=0.2)
        plt.close()

    @staticmethod
    def create_dsc_box_plot_obj(
            dsc_l_m_all,
            dsc_l_m_success,
            dsc_l_f_all,
            dsc_l_f_success,
            dsc_b_m_all,
            dsc_b_m_success,
            dsc_b_f_all,
            dsc_b_f_success,
            out_csv_folder
    ):
        dict_list_lung = []
        dict_list_body = []

        dict_list_lung = dict_list_lung + DSCBoxPlot.get_dict_list_group(dsc_l_m_all, 'Male', 'All')
        dict_list_lung = dict_list_lung + DSCBoxPlot.get_dict_list_group(dsc_l_m_success, 'Male', 'Succeed')
        dict_list_lung = dict_list_lung + DSCBoxPlot.get_dict_list_group(dsc_l_f_all, 'Female', 'All')
        dict_list_lung = dict_list_lung + DSCBoxPlot.get_dict_list_group(dsc_l_f_success, 'Female', 'Succeed')

        dict_list_body = dict_list_body + DSCBoxPlot.get_dict_list_group(dsc_b_m_all, 'Male', 'All')
        dict_list_body = dict_list_body + DSCBoxPlot.get_dict_list_group(dsc_b_m_success, 'Male', 'Succeed')
        dict_list_body = dict_list_body + DSCBoxPlot.get_dict_list_group(dsc_b_f_all, 'Female', 'All')
        dict_list_body = dict_list_body + DSCBoxPlot.get_dict_list_group(dsc_b_f_success, 'Female', 'Succeed')

        lung_data_df = pd.DataFrame(dict_list_lung)
        body_data_df = pd.DataFrame(dict_list_body)
        lung_data_csv = os.path.join(out_csv_folder, 'lung_dsc.csv')
        body_data_csv = os.path.join(out_csv_folder, 'body_dsc.csv')
        logger.info(f'Save to {lung_data_csv}')
        lung_data_df.to_csv(lung_data_csv)
        logger.info(f'Save to {body_data_csv}')
        body_data_df.to_csv(body_data_csv)

        return DSCBoxPlot(lung_data_df, body_data_df)

    @staticmethod
    def get_dict_list_group(dsc_array, sex_flag, group_flag):
        dict_list = []

        for scan_idx in range(len(dsc_array)):
            dict_item = {
                'Sex': sex_flag,
                'Group': group_flag,
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
    parser.add_argument('--csv-lung-mask-male-all', type=str)
    parser.add_argument('--csv-lung-mask-male-success', type=str)
    parser.add_argument('--csv-lung-mask-female-all', type=str)
    parser.add_argument('--csv-lung-mask-female-success', type=str)
    parser.add_argument('--csv-body-mask-male-all', type=str)
    parser.add_argument('--csv-body-mask-male-success', type=str)
    parser.add_argument('--csv-body-mask-female-all', type=str)
    parser.add_argument('--csv-body-mask-female-success', type=str)
    parser.add_argument('--out-csv-folder', type=str)
    parser.add_argument('--out-png', type=str)
    args = parser.parse_args()

    dsc_lung_mask_male_all = pd.read_csv(args.csv_lung_mask_male_all)['Dice'].to_numpy()
    dsc_lung_mask_male_success = pd.read_csv(args.csv_lung_mask_male_success)['Dice'].to_numpy()
    dsc_lung_mask_female_all = pd.read_csv(args.csv_lung_mask_female_all)['Dice'].to_numpy()
    dsc_lung_mask_female_success = pd.read_csv(args.csv_lung_mask_female_success)['Dice'].to_numpy()

    dsc_body_mask_male_all = pd.read_csv(args.csv_body_mask_male_all)['Dice'].to_numpy()
    dsc_body_mask_male_success = pd.read_csv(args.csv_body_mask_male_success)['Dice'].to_numpy()
    dsc_body_mask_female_all = pd.read_csv(args.csv_body_mask_female_all)['Dice'].to_numpy()
    dsc_body_mask_female_success = pd.read_csv(args.csv_body_mask_female_success)['Dice'].to_numpy()

    print_statics('dsc_lung_mask_male_all', dsc_lung_mask_male_all)
    print_statics('dsc_lung_mask_male_success', dsc_lung_mask_male_success)
    print_statics('dsc_lung_mask_female_all', dsc_lung_mask_female_all)
    print_statics('dsc_lung_mask_female_success', dsc_lung_mask_female_success)

    print_statics('dsc_body_mask_male_all', dsc_body_mask_male_all)
    print_statics('dsc_body_mask_male_all', dsc_body_mask_male_success)
    print_statics('dsc_body_mask_female_all', dsc_body_mask_female_all)
    print_statics('dsc_body_mask_female_success', dsc_body_mask_female_success)

    dsc_box_plot_obj = DSCBoxPlot.create_dsc_box_plot_obj(
        dsc_lung_mask_male_all,
        dsc_lung_mask_male_success,
        dsc_lung_mask_female_all,
        dsc_lung_mask_female_success,
        dsc_body_mask_male_all,
        dsc_body_mask_male_success,
        dsc_body_mask_female_all,
        dsc_body_mask_female_success,
        args.out_csv_folder
    )

    dsc_box_plot_obj.plot_box(args.out_png)


if __name__ == '__main__':
    main()
