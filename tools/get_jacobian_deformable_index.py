import numpy as np
import argparse
import nibabel as nib
from data_io import ScanWrapper
import os



path1 = '/nfs/masi/xuk9/SPORE/clustering/registration/20200512_corrField/male/output/non_rigid/output'
path2 = os.path.join(path1, '00000674time20170601.nii/jac')

in_trans = os.path.join(path2, 'trans_combine_low_res.nii.gz_jacM.nii.gz')
in_ref_img = os.path.join(path2, 'jac.nii.gz')
out_d_idx_img = os.path.join(path2, 'd_idx.nii.gz')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-trans-img', type=str, default=in_trans)
    parser.add_argument('--in-ref-img', type=str, default=in_ref_img)
    parser.add_argument('--out-d-idx-img', type=str, default=out_d_idx_img)
    args = parser.parse_args()

    in_trans_img = nib.load(args.in_trans_img)
    in_trans_data = in_trans_img.get_data()

    print(in_trans_data.shape)

    in_trans_data = np.reshape(in_trans_data, (225, 225, 200, 1, 3, 3))

    print(in_trans_data.shape)

    print(f'Start calculate the svd')

    _, s, _ = np.linalg.svd(in_trans_data)

    print(f'Complete calculating svd.')

    print(s.shape)

    # print('Get the log jac')
    # # jac_log = np.log((s[:,:,:,:, 0] * s[:,:,:,:, 1] * s[:,:,:,:, 2]))
    #
    # print('Done')

    print('Get D index')
    d_idx = np.zeros((s.shape[0], s.shape[1], s.shape[2]), dtype=float)
    for idx in range(3):
        print(f'idx {idx}')
        s_idx_1 = idx % 3
        s_idx_2 = (idx + 1) % 3
        pair_wise_idx = np.abs(np.log(np.abs(s[:,:,:,0, s_idx_1])/np.abs(s[:,:,:,0, s_idx_2])))
        d_idx += pair_wise_idx

    print('Done')
    print(f'Save to {args.out_d_idx_img}')
    ref_obj = ScanWrapper(args.in_ref_img)
    ref_obj.save_scan_same_space(args.out_d_idx_img, d_idx)


if __name__ == '__main__':
    main()