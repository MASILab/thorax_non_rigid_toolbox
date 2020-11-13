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
import pandas as pd
from matplotlib.pyplot import cm


logger = get_logger('Plot heatmap')


class EvaluationDatabase:
    def __init__(self,
                 body_dice_csv_folder,
                 thres_body_dice,
                 lung_dice_csv_folder,
                 thres_lung_dice,
                 jac_csv_folder,
                 thres_neg_jac_ratio,
                 test_prefix):
        self._body_dice_csv_folder = body_dice_csv_folder
        self._body_dice_thres = thres_body_dice
        self._lung_dice_csv_folder = lung_dice_csv_folder
        self._lung_dice_thres = thres_lung_dice
        self._jac_csv_folder = jac_csv_folder
        self._thres_neg_jac_ratio = thres_neg_jac_ratio
        self._test_data_list = {}
        self._out_dpi = 15
        # self._sub_title_font_size = 150
        # self._sub_title_font_size_double = 100
        self._sub_title_font_size = 50
        self._sub_title_font_size_double = 20
        self._test_prefix = test_prefix

    def read_data_list(self):
        range_search_radius, range_kp_disp, range_reg, range_sim_size = self._get_range()

        for idx_search_radius in range(len(range_search_radius)):
            for idx_kp_disp in range(len(range_kp_disp)):
                for idx_range_reg in range(len(range_reg)):
                    for idx_range_sim_size in range(len(range_sim_size)):
                        test_name = self._get_test_name(idx_search_radius,
                                                        idx_kp_disp,
                                                        idx_range_reg,
                                                        idx_range_sim_size)
                        complete_p = self._check_if_test_complete(test_name)
                        if complete_p:
                            test_data = self._read_data_of_test(test_name)
                            self._test_data_list[test_name] = test_data
        logger.info(f'Read {len(self._test_data_list)} data')

    def save_data_list_csv(self, csv_path):
        data_list_df = pd.DataFrame.from_dict(self._test_data_list, orient='index')
        print(data_list_df)
        logger.info(f'Save csv file to {csv_path}')
        data_list_df.to_csv(csv_path)

    def _check_if_test_complete(self, test_name):
        csv_path = os.path.join(self._body_dice_csv_folder, test_name)
        return os.path.exists(csv_path)

    def get_statistics(self, val_flag):
        statics = {}

        data_list = [self._test_data_list[test_name][val_flag]
                     for test_name in self._test_data_list]

        statics['min'] = np.min(data_list)
        statics['max'] = np.max(data_list)
        statics['mean'] = np.mean(data_list)
        statics['std'] = np.std(data_list)

        print(f'Show statistics of {val_flag}:')
        print(statics)
        return statics

    def _read_data_of_test(self, test_name):
        result_dict = {}

        body_dice_df = pd.read_csv(os.path.join(self._body_dice_csv_folder, test_name))
        body_np_list = body_dice_df['Dice'].to_numpy()
        result_dict['BodyDiceMean'] = np.mean(body_np_list)
        result_dict['BodyDiceMin'] = np.min(body_np_list)

        body_outlier_df = body_dice_df[body_dice_df['Dice'] < self._body_dice_thres]
        body_outlier_list = body_outlier_df['Scan'].tolist()
        result_dict['BodyDiceOutliers'] = body_outlier_list
        result_dict['NumBodyDiceOutliers'] = len(body_outlier_list)

        body_dice_worst_n = np.argsort(body_np_list)[0:5]
        body_dice_name_list = body_dice_df['Scan'].tolist()
        body_dice_worst_n_name_list = [body_dice_name_list[idx] for idx in body_dice_worst_n]
        result_dict['BodyDiceWorst5Scan'] = body_dice_worst_n_name_list

        lung_dice_df = pd.read_csv(os.path.join(self._lung_dice_csv_folder, test_name))
        lung_np_list = lung_dice_df['Dice'].to_numpy()
        result_dict['LungDiceMean'] = np.mean(lung_np_list)
        result_dict['LungDiceMin'] = np.min(lung_np_list)

        lung_median_idx = np.argsort(lung_np_list)[len(lung_np_list)//2]
        median_scan_name = lung_dice_df['Scan'].tolist()[lung_median_idx]
        result_dict['LungDiceMedianScan'] = median_scan_name

        lung_dice_worst_n = np.argsort(lung_np_list)[0:5]
        lung_dice_name_list = lung_dice_df['Scan'].tolist()
        lung_dice_worst_n_name_list = [lung_dice_name_list[idx] for idx in lung_dice_worst_n]
        result_dict['LungDiceWorst5Scan'] = lung_dice_worst_n_name_list

        result_dict['SumDiceMean'] = result_dict['BodyDiceMean'] + result_dict['LungDiceMean']

        lung_outlier_df = lung_dice_df[lung_dice_df['Dice'] < self._lung_dice_thres]
        lung_outlier_list = lung_outlier_df['Scan'].tolist()
        result_dict['LungDiceOutliers'] = lung_outlier_list
        result_dict['NumLungDiceOutliers'] = len(lung_outlier_list)

        jac_df = pd.read_csv(os.path.join(self._jac_csv_folder, test_name))
        jac_neg_ratio_list = jac_df['NegRatio'].to_numpy()
        result_dict['NegJacRatioMean'] = np.mean(jac_neg_ratio_list)

        jac_neg_ratio_outlier_df = jac_df[jac_df['NegRatio'] > self._thres_neg_jac_ratio]
        jac_neg_ratio_outlier_list = jac_neg_ratio_outlier_df['Scan'].tolist()
        result_dict['NegJacRatioOutliers'] = jac_neg_ratio_outlier_list
        result_dict['NumNegJacRatioOutliers'] = len(jac_neg_ratio_outlier_list)

        jac_neg_median_idx = np.argsort(jac_neg_ratio_list)[len(jac_neg_ratio_list)//2]
        median_scan_name = jac_df['Scan'].tolist()[jac_neg_median_idx]
        result_dict['JacNegMedianScan'] = median_scan_name

        jac_neg_worst_n = np.argsort(jac_neg_ratio_list)[-5:]
        jac_neg_name_list = jac_df['Scan'].tolist()
        jac_neg_worst_n_name_list = [jac_neg_name_list[idx] for idx in jac_neg_worst_n]
        result_dict['JacNegWorst5Scan'] = jac_neg_worst_n_name_list

        outlier_dice_all = result_dict['BodyDiceOutliers'] + result_dict['LungDiceOutliers']
        outlier_dice_all = set(outlier_dice_all)
        outlier_dice_all = (list(outlier_dice_all))
        result_dict['NumDiceOutliers'] = len(outlier_dice_all)

        outlier_all = result_dict['BodyDiceOutliers'] + result_dict['LungDiceOutliers'] + result_dict['NegJacRatioOutliers']
        outlier_all = set(outlier_all)
        outlier_all = (list(outlier_all))
        result_dict['AllOutliers'] = outlier_all
        result_dict['NumAllOutliers'] = len(outlier_all)

        return result_dict

    def plot_heat_map_grid(self, out_png, val_flag):
        num_search_radius = self._get_num_sample('search_radius')
        num_kp_disp = self._get_num_sample('kp_disp')
        num_reg = self._get_num_sample('reg')
        num_sim_size = self._get_num_sample('sim_size')

        fig_size_scaler = 2

        # fig_width = (10 * num_kp_disp + 10) * num_reg
        # fig_height = (10 * num_search_radius + 10) * num_sim_size

        fig_width = (fig_size_scaler * num_kp_disp + fig_size_scaler) * num_reg
        fig_height = (fig_size_scaler * num_search_radius + fig_size_scaler) * num_sim_size

        fig = plt.figure(figsize=(fig_width, fig_height))
        gs = gridspec.GridSpec(num_sim_size, num_reg)
        gs.update(wspace=0.2, hspace=0.2)

        val_statics = self.get_statistics(val_flag)

        for idx_sim_size in range(num_sim_size):
            sim_size = self._get_variable_range_idx('sim_size', idx_sim_size)
            for idx_reg in range(num_reg):
                # print(f'Plot idx_sim_size {idx_sim_size}, idx_reg {idx_reg}')
                reg_val = self._get_variable_range_idx('reg', idx_reg)
                data_matrix = self._get_data_matrix_search_radius_kp_disp(
                    idx_sim_size,
                    idx_reg,
                    val_flag)
                self._plot_one_heatmap(
                    idx_sim_size,
                    idx_reg,
                    data_matrix,
                    gs,
                    val_statics['min'],
                    val_statics['max'],
                    f'Reg. {round(reg_val, 3)}, Sim. Patch Size {sim_size}\nX: KPs Disp, Y: Search Range.'
                )

        out_eps = out_png.replace('.png', '.eps')
        logger.info(f'Save png to {out_eps}')
        # plt.savefig(out_png,  bbox_inches='tight', pad_inches=0, dpi=self._out_dpi)
        plt.savefig(out_eps, bbox_inches='tight', pad_inches=0, dpi=self._out_dpi)

    def _plot_one_heatmap(self, idx_row, idx_column, data_matrix, gs, vmin, vmax, title_str):
        range_search_radius, range_kp_disp, _, _ = self._get_range()

        ax = plt.subplot(gs[idx_row, idx_column])
        plt.imshow(
            data_matrix,
            cmap='hot',
            norm=colors.Normalize(vmin=vmin, vmax=vmax)
        )

        ax.set_yticks(np.arange(len(range_search_radius)))
        ax.set_xticks(np.arange(len(range_kp_disp)))

        ax.set_yticklabels(range_search_radius, {'fontsize': self._sub_title_font_size})
        ax.set_xticklabels(range_kp_disp, {'fontsize': self._sub_title_font_size})

        # Loop over data dimensions and create text annotations.
        for idx_search_radius in range(len(range_search_radius)):
            for idx_kp_disp in range(len(range_kp_disp)):
                ax.text(idx_kp_disp, idx_search_radius, round(data_matrix[idx_search_radius, idx_kp_disp], 5),
                               ha="center", va="center", color="b", fontdict={'fontsize': self._sub_title_font_size_double})
                # ax.text(idx_kp_disp, idx_search_radius, data_matrix[idx_search_radius, idx_kp_disp],
                #                ha="center", va="center", color="b", fontdict={'fontsize': self._sub_title_font_size})

        [t.set_visible(True) for t in ax.get_xticklabels()]
        [t.set_visible(True) for t in ax.get_yticklabels()]

        ax.set_title(title_str, fontsize=self._sub_title_font_size_double)

    def _get_data_matrix_search_radius_kp_disp(
            self,
            idx_sim_size,
            idx_reg,
            val_flag):

        num_search_radius = self._get_num_sample('search_radius')
        num_kp_disp = self._get_num_sample('kp_disp')

        data_matrix = np.zeros((num_search_radius, num_kp_disp)).astype(float)
        for idx_search_radius in range(num_search_radius):
            for idx_kp_disp in range(num_kp_disp):
                test_name = self._get_test_name(
                    idx_search_radius,
                    idx_kp_disp,
                    idx_reg,
                    idx_sim_size)
                if test_name in self._test_data_list:
                    data_matrix[idx_search_radius][idx_kp_disp] = self._test_data_list[test_name][val_flag]
                else:
                    data_matrix[idx_search_radius][idx_kp_disp] = np.nan

        return data_matrix

    def _get_num_sample(self, which_variable):
        range_search_radius, range_kp_disp, range_reg, range_sim_size = self._get_range()

        val_dict = {
            'search_radius': len(range_search_radius),
            'kp_disp': len(range_kp_disp),
            'reg': len(range_reg),
            'sim_size': len(range_sim_size)
        }

        return val_dict[which_variable]

    def _get_variable_range_idx(self, which_variable, idx):
        range_search_radius, range_kp_disp, range_reg, range_sim_size = self._get_range()

        val_dict = {
            'search_radius': range_search_radius,
            'kp_disp': range_kp_disp,
            'reg': range_reg,
            'sim_size': range_sim_size
        }

        return val_dict[which_variable][idx]

    def _get_test_name(self, idx_search_radius, idx_kp_disp, idx_reg, idx_sim_size):
        # idx_search_radius = idx_search_radius + 5
        # idx_reg = idx_reg + 2
        # idx_sim_size = idx_sim_size + 1
        return f'{self._test_prefix}_{idx_search_radius}_{idx_kp_disp}_{idx_reg}_{idx_sim_size}'

    @staticmethod
    def _get_range():
        # Stage 1
        # range_search_radius = np.arange(10, 31, 5, dtype=int)
        # range_kp_disp = np.arange(6, 15, 2, dtype=int)
        # range_reg = np.arange(0.4, 1.7, 0.3, dtype=float)
        # range_sim_size = np.arange(3, 10, 3, dtype=int)

        range_search_radius = np.arange(10, 51, 5, dtype=int)
        range_kp_disp = np.arange(6, 15, 2, dtype=int)
        range_reg = np.arange(0.4, 2.3, 0.3, dtype=float)
        range_sim_size = np.arange(3, 10, 3, dtype=int)

        # # Stage 2
        # range_search_radius = np.arange(4, 17, 3, dtype=int)
        # range_kp_disp = np.arange(6, 15, 2, dtype=int)
        # range_reg = np.arange(0.4, 1.7, 0.3, dtype=float)
        # range_sim_size = np.arange(3, 10, 3, dtype=int)

        # plot_search_radius = range_search_radius[5:9]
        # plot_kp_disp = range_kp_disp[0:4]
        # plot_reg = range_reg[2:3]
        # plot_sim_size = range_sim_size[1:2]

        # return plot_search_radius, plot_kp_disp, plot_reg, plot_sim_size
        return range_search_radius, range_kp_disp, range_reg, range_sim_size


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-archive-folder', type=str)
    parser.add_argument('--thres-lung-dice', type=float)
    parser.add_argument('--thres-body-dice', type=float)
    parser.add_argument('--thres-jac-neg-ratio', type=float)
    parser.add_argument('--out-png-folder', type=str)
    parser.add_argument('--save-csv-path', type=str)
    parser.add_argument('--test-prefix', type=str)
    args = parser.parse_args()

    database = EvaluationDatabase(
        os.path.join(args.in_archive_folder, 'body_dice'),
        args.thres_body_dice,
        os.path.join(args.in_archive_folder, 'lung_dice'),
        args.thres_lung_dice,
        os.path.join(args.in_archive_folder, 'jac'),
        args.thres_jac_neg_ratio,
        args.test_prefix
    )

    database.read_data_list()
    database.save_data_list_csv(args.save_csv_path)


    # database.get_statistics('BodyDiceMean')
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'outliers_body.png'),
    #     'NumBodyDiceOutliers'
    # )
    #
    # database.get_statistics('LungDiceMean')
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'outliers_lung.png'),
    #     'NumLungDiceOutliers'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'outliers_neg_jac.png'),
    #     'NumNegJacRatioOutliers'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'outliers_dice.png'),
    #     'NumDiceOutliers'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'outliers_all.png'),
    #     'NumAllOutliers'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'body_dice.png'),
    #     'BodyDiceMean'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'lung_dice.png'),
    #     'LungDiceMean'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'lung_dice_min.png'),
    #     'LungDiceMin'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'body_dice_min.png'),
    #     'BodyDiceMin'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'sum_dice.png'),
    #     'SumDiceMean'
    # )
    #
    # database.plot_heat_map_grid(
    #     os.path.join(args.out_png_folder, 'jac_ratio_mean.png'),
    #     'NegJacRatioMean'
    # )

if __name__ == '__main__':
    main()
