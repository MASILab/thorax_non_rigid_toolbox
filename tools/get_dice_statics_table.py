import argparse
from utils import get_logger
import pandas as pd
from utils import read_file_contents_list
import numpy as np
import os
import matplotlib.pyplot as plt


logger = get_logger('Dice')


def get_dice_data_table(dice_data_root, item_list, num_scans, mask_flag):
    data_table = np.zeros((num_scans, len(item_list)))
    for item_idx in range(len(item_list)):
        item = item_list[item_idx]
        dice_csv_path = os.path.join(dice_data_root, item)
        dice_csv_path = os.path.join(dice_csv_path, mask_flag + '.csv')
        logger.info(f'Read dice csv: {dice_csv_path}')
        dice_df = pd.read_csv(dice_csv_path)
        np_list = dice_df['Dice'].to_numpy()
        data_table[:, item_idx] = np_list[:]
    return data_table


def main():
    parser = argparse.ArgumentParser('Box plot for dice statistics.')
    parser.add_argument('--dice-data-root', type=str)
    parser.add_argument('--item-list', type=str)
    parser.add_argument('--out-fig-folder', type=str)
    parser.add_argument('--num-scans', type=int, default=50)
    args = parser.parse_args()

    item_list = read_file_contents_list(args.item_list)
    logger.info('Item list')
    # print(item_list)

    mask_flag_list = ['lung_mask', 'body_mask']

    for mask_flag in mask_flag_list:
        data_table = get_dice_data_table(args.dice_data_root, item_list, args.num_scans, mask_flag)
        mask_df = pd.DataFrame(data_table, columns=item_list)
        mask_df.plot.box(grid='True')

        out_fig_path = os.path.join(args.out_fig_folder, mask_flag + '.png')
        logger.info(f'Save plot to {out_fig_path}')
        plt.savefig(out_fig_path)


if __name__ == '__main__':
    main()
