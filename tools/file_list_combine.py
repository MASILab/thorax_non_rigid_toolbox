import argparse
from utils import get_logger
import pandas as pd
from utils import read_file_contents_list
import numpy as np
import matplotlib.pyplot as plt
import os


logger = get_logger('Merge file list')


def main():
    parser = argparse.ArgumentParser('Plot box and scatter data.')
    parser.add_argument('--file-list-folder', type=str)
    parser.add_argument('--out-file-list', type=str)
    args = parser.parse_args()

    file_list_of_file_list_txt = os.listdir(args.file_list_folder)

    total_list = []
    for file_list_file in file_list_of_file_list_txt:
        file_path = os.path.join(args.file_list_folder, file_list_file)
        file_list = read_file_contents_list(file_path)
        total_list = total_list + file_list
    unique_list = unique(total_list)
    logger.info(f'Number of unique files {len(unique_list)}')

    with open(args.out_file_list, 'w') as file:
        for item in unique_list:
            file.write(item + '\n')


def unique(in_list):
    # insert the list to the set
    list_set = set(in_list)
    # convert the set to the list
    unique_list = (list(list_set))

    return unique_list


if __name__ == '__main__':
    main()
