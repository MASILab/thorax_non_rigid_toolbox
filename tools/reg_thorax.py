import argparse
import os
import time
import datetime
from utils import *
# from utils import *


def run_reg_thorax(fixed_path,
                   moving_path,
                   out_image_path,
                   out_matrix_path,
                   reg_tool_root,
                   reg_method='affine_flirt',
                   reg_args='',
                   label=''):
    t0 = time.time()

    print('Start registration image %s' % moving_path)
    print('Reference image is %s' % fixed_path)
    reg_command_list = get_registration_command(reg_method, reg_args, label, reg_tool_root, fixed_path, moving_path, out_image_path, out_matrix_path)

    for command_str in reg_command_list:
        print(command_str)
        os.system(command_str)

    print('Output registered image to %s' % out_image_path)
    print('Output matrix to %s' % out_matrix_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))
    print('Exit run_reg_thorax')
    print(datetime.datetime.now())
    print('')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--fixed', type=str, help='Reference image')
    parser.add_argument('--moving', type=str, help='Image to register to reference.')
    parser.add_argument('--out', type=str, help='Output (registered) image.')
    parser.add_argument('--omat', type=str, help='Output matrix.')
    parser.add_argument('--reg_tool_root', type=str)
    parser.add_argument('--reg_method', type=str)
    parser.add_argument('--reg_args', type=str, default='')
    parser.add_argument('--label', type=str, default='')
    args = parser.parse_args()

    # reg_args = args.reg_args[0].replace('_', ' ')
    reg_args = args.reg_args.replace('_', ' ')
    reg_args = reg_args.replace('"', '')

    run_reg_thorax(args.fixed, args.moving, args.out, args.omat, args.reg_tool_root, args.reg_method, reg_args, args.label)