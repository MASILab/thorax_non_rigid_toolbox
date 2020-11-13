import argparse
import nibabel as nib
from scipy import ndimage as ndi


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mask', type=str)
    parser.add_argument('--out-edt', type=str)
    args = parser.parse_args()

    mask_img_obj = nib.load(args.mask)
    mask_img = mask_img_obj.dataobj
    edt_img = ndi.distance_transform_edt(mask_img)

    edt_img_obj = nib.Nifti1Image(edt_img.astype(int),
                                  affine=mask_img_obj.affine,
                                  header=mask_img_obj.header)
    nib.save(edt_img_obj, args.out_edt)


if __name__ == '__main__':
    main()