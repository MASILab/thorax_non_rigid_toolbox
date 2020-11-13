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
    parser.add_argument('--in-csv', type=str)
    parser.add_argument('--thres-val', type=float)
    parser.add_argument('--out-fig', type=str)
    args = parser.parse_args()

    test_collection_df = pd.read_csv(args.in_csv)
    test_dict = test_collection_df.set_index('TestName').to_dict('index')

    num_test = len(test_dict)
    num_data = 50

    y_table = np.full((num_data, num_test), 1).astype(float)
    for test_idx, test_name in enumerate(test_dict):
        test_item = test_dict[test_name]
        test_df = pd.read_csv(test_item['CSV'])
        y_all = test_df[test_item['COLUMN']].to_numpy()
        y_table[:, test_idx] = y_all[:]

    fig, ax = plt.subplots(figsize=(num_test * 2 + 2, 8))
    plt.boxplot(y_table)

    # Add outliers as scatter points
    num_outlier = np.zeros(num_test)
    mean_val = np.zeros(num_test)
    # kp_val = np.zeros(num_test)
    outlier_data = []
    for test_idx, test_name in enumerate(test_dict):
        test_item = test_dict[test_name]
        test_df = pd.read_csv(test_item['CSV'])
        data_dict = test_df.set_index('Scan').to_dict('index')
        outlier_list = read_file_contents_list(test_item['OUTLIER'])
        num_outlier[test_idx] = len(outlier_list)
        scan_list = test_df['Scan'].to_list()
        column_flag = test_item['COLUMN']
        x_out_all, y_out_all = get_x_y_outlier_list(data_dict,
                                            column_flag,
                                            scan_list,
                                            test_idx + 1)
        # kp_val[test_idx] = data_dict[outlier_list[0]][column_flag]
        mean_val[test_idx] = np.mean(y_out_all)
        plt.scatter(x_out_all, y_out_all, color='r', alpha=0.5)

        x_out, y_out = get_x_y_outlier_list(data_dict,
                                            column_flag,
                                            outlier_list,
                                            test_idx + 1)
        outlier_data.append(y_out)

    # plot outlier as connected dots
    # for outlier_idx in range(int(num_outlier[0])):
    #     y_val = [outlier_data[test_idx][outlier_idx] for test_idx in range(num_test)]
    #     plt.plot(range(1, len(y_val) + 1), y_val, linestyle='--', marker='o', color='b')

    labels = [item.get_text() for item in ax.get_xticklabels()]
    for test_idx, test_name in enumerate(test_dict):
        mean = float("{:.5f}".format(mean_val[test_idx]))
        # kp = float("{:.5f}".format(kp_val[test_idx]))
        # labels[test_idx] = f'{test_name} \noutlier {int(num_outlier[test_idx])}/{num_data}\nmean {mean}'
        labels[test_idx] = f'{test_name} \nmean {mean}'
        # labels[test_idx] = f'{test_name}\n KP1 Lung DSC {kp}'
    ax.set_xticklabels(labels)

    # Threshold.
    print(f'Thres: {args.thres_val}')
    plt.axhline(y=args.thres_val, color='r', linestyle='--')

    logger.info(f'Save plot to {args.out_fig}')
    plt.grid()
    plt.savefig(args.out_fig)


def get_x_y_outlier_list(data_dict, column_flag, outlier_list, x_idx):
    y_outlier = [data_dict[file_name][column_flag] for file_name in outlier_list]
    x_outlier = np.random.normal(x_idx, 0.01, len(y_outlier))

    return x_outlier, y_outlier


if __name__ == '__main__':
    main()
