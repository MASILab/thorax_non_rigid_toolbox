import os
import argparse
import numpy as np
import nibabel as nib
from skimage.morphology import convex_hull_image


def get_xy_convex_hull(args):
    in_mask_obj = nib.load(args.in_mask)
    in_mask_data = in_mask_obj.get_data()
    print(in_mask_data.shape)

    convex_mask_data = in_mask_data
    for i_layer in range(in_mask_data.shape[2]):
        mask = in_mask_data[:, :, i_layer]
        if np.sum(mask) > 0:
            convex_mask = convex_hull_image(mask)
            convex_mask_data[:, :, i_layer] = convex_mask
        else:
            convex_mask_data[:, :, i_layer] = 0

    out_mask_obj = nib.Nifti1Image(convex_mask_data, header=in_mask_obj.header, affine=in_mask_obj.affine)
    nib.save(out_mask_obj, args.out_mask)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-mask', type=str)
    parser.add_argument('--out-mask', type=str)

    args = parser.parse_args()
    get_xy_convex_hull(args)