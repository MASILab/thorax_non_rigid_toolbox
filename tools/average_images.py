import nibabel as nib
import argparse
import os
import numpy as np
from utils import get_extension, get_chunks_list
from multiprocessing import Pool


def main():
    parser = argparse.ArgumentParser(description='Generate average atlas for an image folder.')
    parser.add_argument('--in_folder', type=str,
                        help='The input image folder')
    parser.add_argument('--out', type=str,
                        help='The output image path (with .nii.gz)')
    parser.add_argument('--ref', type=str,
                        help='Path of reference image. Define the affine and header of output nii.gz')
    parser.add_argument('--num_processes', type=int, default=20)

    args = parser.parse_args()
    file_list_all = os.listdir(args.in_folder)
    print('Process images under folder: ', args.in_folder)
    print('Number of files in folder %s is %d' % (args.in_folder, len(file_list_all)))
    nifti_file_list = [file_path for file_path in file_list_all if get_extension(file_path) == '.gz']
    print('Number of nii.gz files: ', len(nifti_file_list))

    file_name_chunks = get_chunks_list(nifti_file_list, args.num_processes)

    pool = Pool(processes=args.num_processes)

    result_list = [pool.apply_async(average_nii_file_list_mem, (file_name_chunk, args.in_folder)) for file_name_chunk in file_name_chunks]

    # Get the shape.
    # im_temp = nib.load(os.path.join(args.in_folder, nifti_file_list[0]))
    im_temp = nib.load(args.ref)
    im_header = im_temp.header
    im_affine = im_temp.affine
    im_temp_data = im_temp.get_data()
    im_shape = im_temp_data.shape
    averaged_image = np.zeros(im_shape)
    for thread_idx in range(len(result_list)):
        result = result_list[thread_idx]
        result.wait()
        print(f'Thread with idx {thread_idx} / {len(result_list)} is completed')
        print('Adding to averaged_image...')
        averaged_image_chunk = result.get()
        chunk_size = len(file_name_chunks[thread_idx])
        averaged_image = np.add(averaged_image, np.multiply(averaged_image_chunk, chunk_size))
        print('Done.')

    print('')
    print('Averaging over all images...')
    averaged_image = np.divide(averaged_image, len(nifti_file_list))
    print('Done.')

    print('Output to file: ', args.out)
    averaged_image_obj = nib.Nifti1Image(averaged_image, affine=im_affine, header=im_header)
    nib.save(averaged_image_obj, args.out)


def average_nii_file_list_mem(file_list, in_folder):
    print('Loading images...')
    im_temp = nib.load(os.path.join(in_folder, file_list[0]))
    im_temp_data = im_temp.get_data()
    im_shape = im_temp_data.shape

    average_image = np.zeros(im_shape)

    for id_file in range(len(file_list)):
        file_name = file_list[id_file]
        print('%s (%d/%d)' % (file_name, id_file, len(file_list)))
        file_path = os.path.join(in_folder, file_name)
        im = nib.load(file_path)
        im_data = im.get_data()
        average_image = np.add(average_image, im_data)

    print('Average images...')
    average_image = np.divide(average_image, len(file_list))
    print('Done')

    return average_image


def load_scan(path):
    img=nib.load(path)
    return img #a nib object


# def get_extension(file_full_path):
#     filename, file_extension = os.path.splitext(file_full_path)
#     return file_extension


if __name__ == '__main__':
    main()