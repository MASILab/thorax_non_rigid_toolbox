import argparse
from utils import get_logger
from utils import read_file_contents_list, save_file_contents_list
import random


logger = get_logger('Random select')


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--file-list-total', type=str)
    parser.add_argument('--file-list-out', type=str)
    parser.add_argument('--num-file-select', type=int)

    args = parser.parse_args()

    file_list_total = read_file_contents_list(args.file_list_total)

    file_list_out = random.choices(file_list_total, k=args.num_file_select)

    save_file_contents_list(args.file_list_out, file_list_out)


if __name__ == '__main__':
    main()
