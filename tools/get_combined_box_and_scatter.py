import argparse
from matplotlib import cm
from utils import get_logger
import pandas as pd
from utils import read_file_contents_list
import numpy as np
import os
import matplotlib.pyplot as plt


logger = get_logger('Plot')


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--csv-data', type=str)
    parser.add_argument('--column', type=str)
    parser.add_argument('--out-fig', type=str)
    parser.add_argument('--outlier-list-lung-dice', type=str)
    parser.add_argument('--outlier-list-body-dice', type=str)
    parser.add_argument('--outlier-list-nmi', type=str)
    parser.add_argument('--outlier-list-manual', type=str)
    parser.add_argument('--thres-val', type=float)
    args = parser.parse_args()

    logger.info(f'Read csv: {args.csv_data}')
    data_df = pd.read_csv(args.csv_data)
    data_dict = data_df.set_index('Scan').to_dict()[args.column]
    # print(data_dict)
    outlier_list_lung_dice = read_file_contents_list(args.outlier_list_lung_dice)
    outlier_list_body_dice = read_file_contents_list(args.outlier_list_body_dice)
    outlier_list_nmi = read_file_contents_list(args.outlier_list_nmi)
    outlier_list_manual = read_file_contents_list(args.outlier_list_manual)

    outlier_items = [
        {
            'outlier_list': outlier_list_lung_dice,
            'idx': 2,
            'color': 'red'
        },
        {
            'outlier_list': outlier_list_body_dice,
            'idx': 3,
            'color': 'blue'
        },
        {
            'outlier_list': outlier_list_nmi,
            'idx': 4,
            'color': 'green'
        },
        {
            'outlier_list': outlier_list_manual,
            'idx': 5,
            'color': 'orange'
        }
    ]

    num_metric = 4
    y_all = data_df[args.column].to_numpy()
    y_all_table = np.zeros((len(y_all), num_metric+1))
    for i in range(num_metric+1):
        y_all_table[:, i] = y_all[:]
    x_all = np.random.normal(1, 0.01, len(y_all))

    fig, ax = plt.subplots()

    plt.boxplot(y_all_table)
    plt.scatter(x_all, y_all, c='grey', alpha=1)

    for outlier_item in outlier_items:
        x_outlier, y_outlier = get_x_y_outlier_list(data_dict,
                                                    outlier_item['outlier_list'],
                                                    outlier_item['idx'])
        plt.scatter(x_outlier, y_outlier, c=outlier_item['color'], alpha=0.5)

    labels = [item.get_text() for item in ax.get_xticklabels()]
    labels[0] = f'All ({len(y_all)})'
    labels[1] = f'Outliers (Lung, {len(outlier_list_lung_dice)}/{len(y_all)})'
    labels[2] = f'Outliers (Body, {len(outlier_list_body_dice)}/{len(y_all)})'
    labels[3] = f'Outliers (NMI, {len(outlier_list_nmi)}/{len(y_all)})'
    labels[4] = f'Outliers (Manual QA, {len(outlier_list_manual)}/{len(y_all)})'
    ax.set_xticklabels(labels)

    # Threshold.
    print(f'Thres: {args.thres_val}')
    plt.axhline(y=args.thres_val, color='r', linestyle='--')

    logger.info(f'Save plot to {args.out_fig}')
    fig.set_size_inches(14, 7.5)
    plt.savefig(args.out_fig)


def get_x_y_outlier_list(data_dict, outlier_list, x_idx):
    y_outlier = [data_dict[file_name] for file_name in outlier_list]
    x_outlier = np.random.normal(x_idx, 0.01, len(y_outlier))

    return x_outlier, y_outlier


if __name__ == '__main__':
    main()
