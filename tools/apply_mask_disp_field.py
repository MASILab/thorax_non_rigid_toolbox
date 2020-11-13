import os
from utils import *
import argparse
import numpy as np
import nibabel as nib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--trans', type=str)
    parser.add_argument('--mask', type=str)
    parser.add_argument('--out', type=str)
    args = parser.parse_args()

    trans_img_obj = nib.load(args.trans)
    mask_img_obj = nib.load(args.mask)

    trans_data = trans_img_obj.get_data()
    mask_img_data = mask_img_obj.get_data()

    masked_trans_data = trans_data
    masked_trans_data[mask_img_data == 0, 0, :] = np.nan

    masked_img_obj = nib.Nifti1Image(masked_trans_data, affine=trans_img_obj.affine, header=trans_img_obj.header)
    nib.save(masked_img_obj, args.out)


if __name__ == '__main__':
    main()
