import argparse
from utils import get_logger
from utils import save_file_contents_list
import pandas as pd

logger = get_logger('FileList')


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--in-csv', type=str)
    parser.add_argument('--thres-val', type=float)
    parser.add_argument('--which-column', type=str)
    parser.add_argument('--file-list-out', type=str)
    args = parser.parse_args()

    logger.info(f'Threshold {args.in_csv} using {args.which_column} with value less than {args.thres_val}.')
    df_dice = pd.read_csv(args.in_csv)
    logger.info(f'Number of items: {len(df_dice.index)}')
    df_thres = df_dice[df_dice[args.which_column] < args.thres_val]
    logger.info(f'Number of items after thres: {len(df_thres.index)}')

    file_list = df_thres['Scan'].tolist()

    save_file_contents_list(args.file_list_out, file_list)


if __name__ == '__main__':
    main()
