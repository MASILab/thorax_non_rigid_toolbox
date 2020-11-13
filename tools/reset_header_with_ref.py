import argparse
import nibabel as nib

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-img', type=str)
    parser.add_argument('--out-img', type=str)
    parser.add_argument('--ref-img', type=str)
    args = parser.parse_args()

    in_img = nib.load(args.in_img)
    ref_img = nib.load(args.ref_img)

    out_img = nib.Nifti1Image(in_img.get_data(), header=ref_img.header, affine=ref_img.affine)
    nib.save(out_img, args.out_img)


if __name__ == '__main__':
    main()
