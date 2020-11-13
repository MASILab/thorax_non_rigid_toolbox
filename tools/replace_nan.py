import argparse
import nibabel as nib
import numpy as np

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--val', type=float)
    parser.add_argument('--in_image', type=str)
    parser.add_argument('--out_image', type=str)
    args = parser.parse_args()

    im_obj = nib.load(args.in_image)
    im_data = im_obj.get_data()

    print(f'Replace nan to value {args.val}')

    new_im_data = np.nan_to_num(im_data, nan=args.val)
    new_im_obj = nib.Nifti1Image(new_im_data, header=im_obj.header, affine=im_obj.affine)

    nib.save(new_im_obj, args.out_image)


if __name__ == '__main__':
    main()