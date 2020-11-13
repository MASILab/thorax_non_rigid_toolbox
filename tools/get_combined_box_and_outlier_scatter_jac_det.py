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
    parser.add_argument('--csv-data-baseline', type=str)
    parser.add_argument('--csv-data-1', type=str)
    parser.add_argument('--csv-data-2', type=str)
    parser.add_argument('--csv-data-3', type=str)
    parser.add_argument('--csv-data-4', type=str)
    parser.add_argument('--csv-data-5', type=str)
    parser.add_argument('--column', type=str)
    parser.add_argument('--thres-val', type=float)
    parser.add_argument('--out-fig', type=str)
    parser.add_argument('--num-complete-test', type=int)
    args = parser.parse_args()

    test_items = [
        {
            'in_csv': args.csv_data_baseline,
            'name': 'Baseline',
            'idx': 1
        },
        {
            'in_csv': args.csv_data_1,
            'name': 'Cap. Range 80mm',
            'idx': 2
        }
        # },
        # {
        #     'in_csv': args.csv_data_2,
        #     'name': 'Template ref',
        #     'idx': 3
        # },
        # {
        #     'in_csv': args.csv_data_3,
        #     'name': '6 Step',
        #     'idx': 4
        # },
        # {
        #     'in_csv': args.csv_data_4,
        #     'name': '4 Step',
        #     'idx': 5
        # },
        # {
        #     'in_csv': args.csv_data_5,
        #     'name': 'Inst. Opt. (MH)',
        #     'idx': 6
        # }
    ]

    num_test = len(test_items)
    num_test_complete = args.num_complete_test
    num_data = 50

    y_table = np.full((num_data, num_test), 1).astype(float)
    for test_idx in range(num_test_complete):
        test_item = test_items[test_idx]
        test_df = pd.read_csv(test_item['in_csv'])
        y_all = test_df[args.column].to_numpy()
        y_table[:, test_idx] = y_all[:]

    fig, ax = plt.subplots()

    plt.boxplot(y_table)

    # Add scatter plot
    mean_val = np.zeros(num_test)
    for test_idx in range(num_test_complete):
        test_item = test_items[test_idx]
        test_df = pd.read_csv(test_item['in_csv'])
        data_dict = test_df.set_index('Scan').to_dict()[args.column]
        scan_list = test_df['Scan'].to_list()
        x_out, y_out = get_x_y_outlier_list(data_dict,
                                            scan_list,
                                            test_item['idx'])
        mean_val[test_idx] = np.mean(y_out)
        plt.scatter(x_out, y_out, color='r', alpha=0.5)

    labels = [item.get_text() for item in ax.get_xticklabels()]
    for test_idx in range(num_test):
        test_item = test_items[test_idx]
        test_name = test_item['name']
        mean = float("{:.5f}".format(mean_val[test_idx]))
        labels[test_idx] = f'{test_name} \nmean {mean}'
    ax.set_xticklabels(labels)

    # Threshold.
    print(f'Thres: {args.thres_val}')
    plt.axhline(y=args.thres_val, color='r', linestyle='--')

    logger.info(f'Save plot to {args.out_fig}')
    plt.grid()
    fig.set_size_inches(14, 7.5)
    plt.savefig(args.out_fig)


def get_x_y_outlier_list(data_dict, outlier_list, x_idx):
    y_outlier = [data_dict[file_name] for file_name in outlier_list]
    x_outlier = np.random.normal(x_idx, 0.01, len(y_outlier))

    return x_outlier, y_outlier


if __name__ == '__main__':
    main()
