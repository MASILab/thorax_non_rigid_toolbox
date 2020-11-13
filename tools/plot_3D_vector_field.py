from mpl_toolkits.mplot3d import Axes3D
import argparse
from data_io import DataFolder, ScanWrapper
from utils import get_logger
from paral import AbstractParallelRoutine
import numpy as np
import matplotlib.pyplot as plt
from skimage import color, exposure
from matplotlib import colors
import matplotlib.gridspec as gridspec
from skimage.util import compare_images
import os
from utils import mkdir_p
from mpl_toolkits.axes_grid1 import make_axes_locatable


logger = get_logger('Plot')

class PlotVectorField3D:
    def __init__(self,
                 in_trans_img_path,
                 sample_distance
                 ):
        self._in_trans_img_path = in_trans_img_path
        self._sample_distance = sample_distance
        self._scale = 1
        self._upper = 50

    def run_plot(self, out_png_folder):
        trans_img_data = ScanWrapper(self._in_trans_img_path).get_data()
        view_trans_x = list(reversed(range(0, trans_img_data.shape[0], self._sample_distance)))
        view_trans_y = list(reversed(range(0, trans_img_data.shape[1], self._sample_distance)))
        view_trans_z = list(reversed(range(0, trans_img_data.shape[2], self._sample_distance)))

        view_trans_x, view_trans_y, view_trans_z = np.meshgrid(
            view_trans_x,
            view_trans_y,
            view_trans_z
        )

        trans_u = trans_img_data[view_trans_x, view_trans_y, view_trans_z, 0, 0]
        trans_v = trans_img_data[view_trans_x, view_trans_y, view_trans_z, 0, 1]
        trans_w = trans_img_data[view_trans_x, view_trans_y, view_trans_z, 0, 2]

        # trans_c = np.sqrt(trans_u**2 + trans_v**2 + trans_w**2)

        fig = plt.figure()
        ax = fig.gca(projection='3d')

        # fig, ax = plt.subplots()
        # plt.axis('off')

        # im = ax.quiver(
        #     view_trans_x,
        #     view_trans_y,
        #     view_trans_z,
        #     trans_u,
        #     trans_v,
        #     trans_w,
        #     trans_c,
        #     norm=colors.Normalize(vmin=0, vmax=self._upper),
        #     cmap='jet'
        # )

        im = ax.quiver(
            view_trans_x,
            view_trans_y,
            view_trans_z,
            trans_u,
            trans_v,
            trans_w
        )

        out_png_path = os.path.join(out_png_folder, '3d_vector_field.png')
        plt.savefig(out_png_path, bbox_inches='tight', pad_inches=0, dpi=150)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-trans-file', type=str)
    parser.add_argument('--sample-distance', type=int, default=10)
    parser.add_argument('--out-png-folder', type=str)
    args = parser.parse_args()

    mkdir_p(args.out_png_folder)
    plot_obj = PlotVectorField3D(
        args.in_trans_file,
        args.sample_distance
    )
    plot_obj.run_plot(args.out_png_folder)


if __name__ == '__main__':
    main()
