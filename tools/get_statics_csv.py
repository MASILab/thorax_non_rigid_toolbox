import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd
import numpy as np


logger = get_logger('merge_df')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-csv', type=str)
    args = parser.parse_args()

    logger.info(f'Load {args.in_csv}')
    df = pd.read_csv(args.in_csv)

    data_vec = df['Dice'].to_numpy()

    logger.info(f'Mean: {np.mean(data_vec)}')
    logger.info(f'STD: {np.std(data_vec)}')


if __name__ == '__main__':
    main()
