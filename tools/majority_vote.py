import os
import argparse
import numpy as np
import nibabel as nib


def majority_vote(in_folder, out_map, num_class):
    file_name_list = os.listdir(in_folder)
    sample_im_obj = nib.load(os.path.join(in_folder, file_name_list[0]))
    sample_im_data = sample_im_obj.get_data()

    print(f'Majority voting for labels under {in_folder} ({len(file_name_list)} label maps)')

    im_shape = sample_im_data.shape
    im_header = sample_im_obj.header
    im_affine = sample_im_obj.affine

    vote_accumulator = np.zeros((num_class, im_shape[0], im_shape[1], im_shape[2]))

    for file_idx in range(len(file_name_list)):
        file_path = os.path.join(in_folder, file_name_list[file_idx])
        print(f'({file_idx} / {len(file_name_list)}) {file_path}')
        im_data = nib.load(file_path).get_data()
        for i in range(num_class):
            binary_map_val = (im_data == i)
            vote_accumulator[i] = vote_accumulator[i] + binary_map_val

    vote_result = vote_accumulator.argmax(0)

    vote_result_obj = nib.Nifti1Image(vote_result, header=im_header, affine=im_affine)
    print(f'Output voting result to {out_map}')
    nib.save(vote_result_obj, out_map)



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-folder', type=str)
    parser.add_argument('--out', type=str)
    parser.add_argument('--num-class', type=int)

    args = parser.parse_args()
    majority_vote(args.in_folder, args.out, args.num_class)