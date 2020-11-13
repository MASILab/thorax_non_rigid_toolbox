import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd
import numpy as np
from scipy.stats import ranksums


logger = get_logger('p_value')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-csv1', type=str)
    parser.add_argument('--in-csv2', type=str)
    args = parser.parse_args()

    logger.info(f'Load {args.in_csv1}')
    df1 = pd.read_csv(args.in_csv1)
    logger.info(f'Load {args.in_csv2}')
    df2 = pd.read_csv(args.in_csv2)

    vec1 = df1['Dice'].to_numpy()
    vec2 = df2['Dice'].to_numpy()

    print(f'mean of vec1 {np.mean(vec1)}')
    print(f'mean of vec2 {np.mean(vec2)}')

    print(f'p_value is {ranksums(vec1, vec2)}')


if __name__ == '__main__':
    main()
