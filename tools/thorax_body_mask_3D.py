import numpy as np
import nibabel as nib
from scipy import ndimage as ndi
import skimage.morphology
import skimage.measure
import argparse


def create_body_mask(in_img, out_mask):
    rBody = 2

    print(f'Get body mask of image {in_img}')

    image_nb = nib.load(in_img)
    image_np = np.array(image_nb.dataobj)

    BODY = (image_np>=-500)# & (I<=win_max)
    print(f'{np.sum(BODY)} of {np.size(BODY)} voxels masked.')
    if np.sum(BODY)==0:
      raise ValueError('BODY could not be extracted!')

    # Find largest connected component in 3D
    struct = np.ones((3,3,3),dtype=np.bool)
    BODY = ndi.binary_erosion(BODY,structure=struct,iterations=rBody)

    BODY_labels = skimage.measure.label(np.asarray(BODY, dtype=np.int))

    props = skimage.measure.regionprops(BODY_labels)
    areas = []
    for prop in props:
      areas.append(prop.area)
    print(f' -> {len(areas)} areas found.')
    # only keep largest, dilate again and fill holes
    BODY = ndi.binary_dilation(BODY_labels==(np.argmax(areas)+1),structure=struct,iterations=rBody)
    # Fill holes slice-wise
    for z in range(0,BODY.shape[2]):
      BODY[:,:,z] = ndi.binary_fill_holes(BODY[:,:,z])

    new_image = nib.Nifti1Image(BODY.astype(np.int8), header=image_nb.header, affine=image_nb.affine)
    nib.save(new_image,out_mask)
    print(f'Generated body_mask segs in Abwall {out_mask}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create mask file to remove the CT table')
    parser.add_argument('--in-img', type=str,
                        help='Ori image, without any preprocessing.')
    parser.add_argument('--out-mask', type=str,
                        help='Output body mask.')
    args = parser.parse_args()

    create_body_mask(args.in_img, args.out_mask)

