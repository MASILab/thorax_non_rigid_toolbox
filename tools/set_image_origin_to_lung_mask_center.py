import nibabel as nib
import argparse
import numpy as np
import math
import os

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_image', type=str)
    parser.add_argument('--in_mask', type=str)
    parser.add_argument('--out', type=str)
    parser.add_argument('--c3d_root', type=str)

    args = parser.parse_args()

    print(f'Translate image origin of {args.in_image} to center of mask {args.in_mask}')

    in_image_obj = nib.load(args.in_image)
    in_affine = in_image_obj.affine

    in_mask = nib.load(args.in_mask).get_data()

    xc, yc, zc = get_mask_bb_center(in_mask)
    pos_xc, pos_yc, pos_zc = get_world_coord_from_voxel_index(xc, yc, zc, in_affine)

    trans = in_affine[:3, 3]
    new_trans = trans - [pos_xc, pos_yc, pos_zc]
    new_trans = [-new_trans[0], -new_trans[1], new_trans[2]]

    print(f'Lung mask center is {xc}, {yc}, {zc}')
    print(f'New origin should be {new_trans}')

    command_str = f'{args.c3d_root}/c3d {args.in_image} -origin {new_trans[0]}x{new_trans[1]}x{new_trans[2]}mm -o {args.out}'
    print(command_str, flush=True)
    os.system(command_str)


def get_mask_bb_center(in_mask):
    in_mask[in_mask > 0] = 1
    x_list, y_list, z_list = [], [], []
    for i in range(in_mask.shape[0]):
        if np.sum(in_mask[i, :, :]) > 20:
            x_list.append(i)
    for i in range(in_mask.shape[1]):
        if np.sum(in_mask[:, i, :]) > 20:
            y_list.append(i)
    for i in range(in_mask.shape[2]):
        if np.sum(in_mask[:, :, i]) > 20:
            z_list.append(i)

    x_begin, x_end = x_list[0], x_list[-1]
    y_begin, y_end = y_list[0], y_list[-1]
    z_begin, z_end = z_list[0], z_list[-1]

    return math.floor((x_begin+x_end)/2), math.floor((y_begin+y_end)/2), math.floor((z_begin+z_end)/2)


def get_world_coord_from_voxel_index(i,j,k, im_affine):
    M = im_affine[:3, :3]
    trans = im_affine[:3, 3]
    return M.dot([i,j,k]) + trans


if __name__ == '__main__':
    main()