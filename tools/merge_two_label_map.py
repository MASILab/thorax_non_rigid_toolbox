import argparse
import os
import nibabel as nib


def merge_two_label_map(label_high_priority, label_low_priority, label_out):
    print(f'Merge label map {label_high_priority} to {label_low_priority}')

    label_high_priority_img = nib.load(label_high_priority).get_data()
    label_low_priority_img = nib.load(label_low_priority).get_data()
    header_img = nib.load(label_high_priority).header
    affine_img = nib.load(label_high_priority).affine

    out_img = label_low_priority_img
    out_img[label_high_priority_img > 0] = 0
    out_img += label_high_priority_img

    out_obj = nib.Nifti1Image(out_img, header=header_img, affine=affine_img)

    nib.save(out_obj, label_out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--label-high-priority', type=str)
    parser.add_argument('--label-low-priority', type=str)
    parser.add_argument('--label-out', type=str)
    args = parser.parse_args()

    merge_two_label_map(
        args.label_high_priority,
        args.label_low_priority,
        args.label_out
    )