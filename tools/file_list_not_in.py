import argparse
from utils import get_logger
from utils import read_file_contents_list, save_file_contents_list

logger = get_logger('Exclude file list')


def main():
    parser = argparse.ArgumentParser('')
    parser.add_argument('--file-list-total', type=str)
    parser.add_argument('--file-list-exclude', type=str)
    parser.add_argument('--file-list-out', type=str)
    args = parser.parse_args()

    file_list_total = read_file_contents_list(args.file_list_total)
    file_list_exclude = read_file_contents_list(args.file_list_exclude)

    file_list_reduced = [file_name for file_name in file_list_total if file_name not in file_list_exclude]

    save_file_contents_list(args.file_list_out, file_list_reduced)


def unique(in_list):
    # insert the list to the set
    list_set = set(in_list)
    # convert the set to the list
    unique_list = (list(list_set))

    return unique_list


if __name__ == '__main__':
    main()
