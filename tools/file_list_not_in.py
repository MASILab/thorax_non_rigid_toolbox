import argparse
from utils import get_logger
from utils import read_file_contents_list, save_file_contents_list

logger = get_logger('Exclude file list')


default_list_total = '/nfs/masi/COVID19_public/BIMCV-COVID19/WebCAV/local_dir/covid19_posi/ct_xray_pair/QA/ct/normal_list'
default_list_exclude = '/nfs/masi/COVID19_public/BIMCV-COVID19/WebCAV/local_dir/covid19_posi/ct_xray_pair/QA/ct/severe_compress_list'
default_list_out = '/nfs/masi/COVID19_public/BIMCV-COVID19/WebCAV/local_dir/covid19_posi/ct_xray_pair/QA/ct/normal_exclude_severe_compress_list'


def main():
    parser = argparse.ArgumentParser('')
    parser.add_argument('--file-list-total', type=str, default=default_list_total)
    parser.add_argument('--file-list-exclude', type=str, default=default_list_exclude)
    parser.add_argument('--file-list-out', type=str, default=default_list_out)
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
