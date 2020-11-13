import argparse
from utils import get_logger
from utils import read_file_contents_list, save_file_contents_list
import pandas as pd

logger = get_logger('Find sub dataset in csv')


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--sub-file-list', type=str)
    parser.add_argument('--in-csv', type=str)
    parser.add_argument('--out-csv', type=str)
    args = parser.parse_args()

    data_df = pd.read_csv(args.in_csv)
    scan_list_total = data_df['Scan'].tolist()
    data_dict_total = data_df.to_dict('records')

    sub_file_list = read_file_contents_list(args.sub_file_list)
    idx_list = [scan_list_total.index(file_name) for file_name in sub_file_list]
    sub_dict = [data_dict_total[idx] for idx in idx_list]

    sub_data_df = pd.DataFrame(sub_dict)

    logger.info(f'Save to {args.out_csv}')
    sub_data_df.to_csv(args.out_csv, index=False)


if __name__ == '__main__':
    main()
