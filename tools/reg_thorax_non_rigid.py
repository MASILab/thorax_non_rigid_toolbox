import argparse
import os
import time
import datetime
from utils import *
# from utils import *


def run_reg_thorax(args):
    t0 = time.time()

    reg_args_non_rigid = args.reg_args_non_rigid.replace('_', ' ')
    reg_args_non_rigid = reg_args_non_rigid.replace('"', '')
    reg_args_affine = args.reg_args_affine.replace('_', ' ')
    reg_args_affine = reg_args_affine.replace('"', '')

    print('Start registration image %s' % args.moving)
    print('Reference image is %s' % args.fixed)
    reg_command_list = get_registration_command_non_rigid(
        args.reg_method,
        reg_args_affine,
        reg_args_non_rigid,
        args.label,
        args.reg_tool_root,
        args.fixed,
        args.moving,
        args.out,
        args.omat,
        args.trans,
        args.out_affine
    )

    for command_str in reg_command_list:
        print(command_str)
        os.system(command_str)

    # print('Output registered image to %s' % out_image_path)
    # print('Output matrix to %s' % out_matrix_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))
    print('Exit run_reg_thorax')
    print(datetime.datetime.now())
    print('')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--fixed', type=str, help='Reference image')
    parser.add_argument('--moving', type=str, help='Image to register to reference.')
    parser.add_argument('--omat', type=str, help='Output matrix.')
    parser.add_argument('--reg_tool_root', type=str)
    parser.add_argument('--reg_method', type=str)
    parser.add_argument('--reg_args_affine', type=str, default='')
    parser.add_argument('--reg_args_non_rigid', type=str, default='')
    parser.add_argument('--label', type=str, default='')
    parser.add_argument('--trans', type=str)
    parser.add_argument('--out', type=str, help='Output (registered) image.')
    parser.add_argument('--out_affine', type=str, help='Affine registered', default='')
    args = parser.parse_args()

    run_reg_thorax(args)