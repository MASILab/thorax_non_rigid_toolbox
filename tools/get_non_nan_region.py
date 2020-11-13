import os
from utils import *
import argparse
import numpy as np
import nibabel as nib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ori', type=str)
    parser.add_argument('--out-mask', type=str)
    args = parser.parse_args()

    ori_img_obj = nib.load(args.ori)

    ori_img = ori_img_obj.get_data()

    non_nan_mask = ori_img == ori_img

    mask_img_obj = nib.Nifti1Image(non_nan_mask.astype(int), affine=ori_img_obj.affine, header=ori_img_obj.header)
    nib.save(mask_img_obj, args.out_mask)


if __name__ == '__main__':
    main()