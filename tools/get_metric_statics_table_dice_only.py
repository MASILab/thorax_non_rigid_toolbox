import argparse
from utils import get_logger
import pandas as pd
from utils import read_file_contents_list
import numpy as np
import os


logger = get_logger('Metric')


def get_statics_csv(csv_path, column_name):
    """
    Return the mean and std.
    """
    logger.info(f'Read column {column_name} of {csv_path}')
    df = pd.read_csv(csv_path)
    np_list = df[column_name].to_numpy()

    return np.mean(np_list), np.std(np_list)


def get_metric_list(dice_data_root):
    metric_list = {
        'Dice_lung' : {
            'csv_root': dice_data_root,
            'csv_name': 'lung_mask.csv',
            'column_name': 'Dice'
        },
        # 'MSD_lung': {
        #     'csv_root': surface_data_root,
        #     'csv_name': 'lung_mask.csv',
        #     'column_name': 'MSD'
        # },
        'Dice_body': {
            'csv_root': dice_data_root,
            'csv_name': 'body_mask.csv',
            'column_name': 'Dice'
        }
        # 'MSD_body': {
        #     'csv_root': surface_data_root,
        #     'csv_name': 'body_mask.csv',
        #     'column_name': 'MSD'
        # }
    }

    return metric_list


def main():
    parser = argparse.ArgumentParser('Box plot for dice statistics.')
    parser.add_argument('--dice-data-root', type=str)
    parser.add_argument('--item-list', type=str)
    parser.add_argument('--out-csv-folder', type=str)
    args = parser.parse_args()

    item_list = read_file_contents_list(args.item_list)
    logger.info('Item list')

    metric_list = get_metric_list(args.dice_data_root)

    mean_table = []
    std_table = []
    for method_name in item_list:
        metric_mean = {}
        metric_std = {}
        for metric in metric_list:
            metric_dict = metric_list[metric]
            csv_path = metric_dict['csv_root'] + '/' + method_name + '/' + metric_dict['csv_name']
            mean, std = get_statics_csv(csv_path, metric_dict['column_name'])
            metric_mean[metric] = mean
            metric_std[metric] = std
        metric_mean['Method'] = method_name
        metric_std['Method'] = method_name

        mean_table.append(metric_mean)
        std_table.append(metric_std)

    out_csv_mean = os.path.join(args.out_csv_folder, 'mean.csv')
    out_csv_std = os.path.join(args.out_csv_folder, 'std.csv')

    df_mean = pd.DataFrame(mean_table)
    df_std = pd.DataFrame(std_table)

    # headers = ["Method", "Dice_lung", "Dice_body", "MSD_lung", "MSD_body"]
    pd.set_option('precision', 5)
    headers = ["Method", "Dice_lung", "Dice_body"]
    logger.info(f'Saving mean table to {out_csv_mean}')
    df_mean.to_csv(out_csv_mean, index=False, columns=headers)
    logger.info(f'Saving std table to {out_csv_std}')
    df_std.to_csv(out_csv_std, index=False, columns=headers)


if __name__ == '__main__':
    main()
