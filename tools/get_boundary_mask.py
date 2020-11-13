import argparse
import nibabel as nib
import numpy as np


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ref', type=str)
    parser.add_argument('--dist', type=int)
    parser.add_argument('--out-mask', type=str)
    args = parser.parse_args()

    dist = args.dist
    ref_img_obj = nib.load(args.ref)
    im_shape = ref_img_obj.dataobj.shape

    mask = np.zeros(im_shape)
    mask[dist:-(dist+1), dist:-(dist+1), dist:-(dist+1)] = 1

    mask_img_obj = nib.Nifti1Image(mask.astype(int),
                                   affine=ref_img_obj.affine,
                                   header=ref_img_obj.header)

    nib.save(mask_img_obj, args.out_mask)


if __name__ == '__main__':
    main()