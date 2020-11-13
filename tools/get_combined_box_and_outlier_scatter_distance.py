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
    parser.add_argument('--outlier-list-1', type=str)
    parser.add_argument('--outlier-list-2', type=str)
    parser.add_argument('--thres-val', type=float)
    parser.add_argument('--out-fig', type=str)
    args = parser.parse_args()

    test_items = [
        {
            'outlier_list': args.outlier_list_1,
            'name': 'Diap Dist (mm)',
            'idx': 1,
            'title': 'Diaphragm Dist (mm)'
        },
        {
            'outlier_list': args.outlier_list_2,
            'name': 'Body Dist (mm)',
            'idx': 2,
            'title': 'Body Dist (mm)'
        }
    ]

    num_data = 50
    num_metric = 2
    y_table = np.full((num_data, num_metric), 1).astype(float)
    data_df = pd.read_csv(args.csv_data)
    y_table[:, 0] = data_df['Diap Dist (mm)'].to_numpy()
    y_table[:, 1] = data_df['Body Dist (mm)'].to_numpy()

    fig, ax = plt.subplots()

    plt.boxplot(y_table)

    # Add outliers as scatter points
    num_outlier = np.zeros(num_metric)
    data_dict = data_df.set_index('Scan').to_dict()
    for test_idx in range(len(test_items)):
        test_item = test_items[test_idx]
        data_dict_metric = data_dict[test_item['name']]
        outlier_list = read_file_contents_list(test_item['outlier_list'])
        num_outlier[test_idx] = len(outlier_list)
        x_outlier, y_outlier = get_x_y_outlier_list(data_dict_metric,
                                                    outlier_list,
                                                    test_item['idx'])
        scan_list_all = data_df['Scan'].to_list()
        x_all, y_all = get_x_y_outlier_list(data_dict_metric,
                                            scan_list_all,
                                            test_item['idx'])
        plt.scatter(x_outlier, y_outlier, color='r', alpha=0.5)
        plt.scatter(x_all, y_all, color='gray', alpha=0.3)

    labels = [item.get_text() for item in ax.get_xticklabels()]
    for test_idx in range(len(test_items)):
        test_item = test_items[test_idx]
        test_title = test_item['title']
        labels[test_idx] = f'{test_title} (Failed case {num_outlier[test_idx]}/{num_data})'
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
