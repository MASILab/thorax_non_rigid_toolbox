import argparse
import nibabel as nib
from data_io import DataFolder, ScanWrapper
from utils import get_dice_with_effective_mask, get_logger
from paral import AbstractParallelRoutine
import pandas as pd


logger = get_logger('merge_df')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-csv1', type=str)
    parser.add_argument('--in-csv2', type=str)
    parser.add_argument('--out-csv', type=str)
    args = parser.parse_args()

    logger.info(f'Load {args.in_csv1}')
    df1 = pd.read_csv(args.in_csv1)
    logger.info(f'Load {args.in_csv2}')
    df2 = pd.read_csv(args.in_csv2)

    df_final = df1.append(df2)

    logger.info(f'Save csv to file {args.out_csv}')
    df_final.to_csv(args.out_csv)


if __name__ == '__main__':
    main()
