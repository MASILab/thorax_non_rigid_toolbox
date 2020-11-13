import os
from utils import *
import argparse
import numpy as np
import nibabel as nib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ori', type=str)
    parser.add_argument('--mask', type=str)
    parser.add_argument('--ambient', type=str)
    parser.add_argument('--out', type=str)
    args = parser.parse_args()

    ambient_val = None
    ambient_val_str = args.ambient
    if ambient_val_str is 'nan':
        ambient_val = np.nan
    else:
        ambient_val = float(args.ambient)

    ori_img_obj = nib.load(args.ori)
    mask_img_obj = nib.load(args.mask)

    ori_img = ori_img_obj.get_data()
    # ori_img = np.nan_to_num(ori_img, nan=args.ambient)
    mask_img = mask_img_obj.get_data()

    new_img_data = np.full(ori_img.shape, ambient_val)
    np.copyto(new_img_data, ori_img, where=mask_img > 0)

    masked_img_obj = nib.Nifti1Image(new_img_data, affine=ori_img_obj.affine, header=ori_img_obj.header)
    nib.save(masked_img_obj, args.out)


if __name__ == '__main__':
    main()
