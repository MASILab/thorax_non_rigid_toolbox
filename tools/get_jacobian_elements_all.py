import numpy as np
import argparse
import nibabel as nib
from data_io import ScanWrapper
import os
from utils import get_logger


logger = get_logger('Get all Jacobian elements.')


path1 = '/nfs/masi/xuk9/SPORE/clustering/registration/20200512_corrField/male/output/non_rigid/output'
path2 = os.path.join(path1, '00000674time20170601.nii/jac')

omat_folder = '/nfs/masi/xuk9/SPORE/clustering/registration/20200512_corrField/male/output/affine/omat'
in_omat_txt = os.path.join(omat_folder, '00000674time20170601.txt')

in_trans = os.path.join(path2, 'trans_combine_low_res.nii.gz_jacM.nii.gz')
in_ref_img = os.path.join(path2, 'jac.nii.gz')
out_d_idx_img = os.path.join(path2, 'd_idx.nii.gz')
out_elem_prefix = os.path.join(path2, 'jac_elements')

c3d_path = '/home/local/VANDERBILT/xuk9/bin/c3d'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-trans-img', type=str, default=in_trans)
    parser.add_argument('--in-ref-img', type=str, default=in_ref_img)
    parser.add_argument('--out-jac-elem-prefix', type=str, default=out_elem_prefix)
    parser.add_argument('--c3d-path', type=str, default=c3d_path)
    args = parser.parse_args()

    in_trans_img = nib.load(args.in_trans_img)
    in_trans_data = in_trans_img.get_data()

    print(in_trans_data.shape)

    ref_obj = ScanWrapper(args.in_ref_img)

    for idx_elem in range(9):
        jac_elem = in_trans_data[:, :, :, 0, idx_elem]
        out_elem_path = f'{args.out_jac_elem_prefix}_{idx_elem}_raw.nii.gz'
        ref_obj.save_scan_same_space(out_elem_path, jac_elem)
        out_clip_elem_path = f'{args.out_jac_elem_prefix}_{idx_elem}_clip_95.nii.gz'
        cmd_str = f'{args.c3d_path} {out_elem_path} -clip 5% 95% -o {out_clip_elem_path}'
        logger.info(f'{cmd_str}')
        os.system(cmd_str)


if __name__ == '__main__':
    main()