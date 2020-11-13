from argparse import ArgumentParser
import nibabel as nib
import numpy as np
import os
import struct
import warnings
warnings.filterwarnings('ignore')

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

def pdist_squared(x):
    xx = (x**2).sum(dim=2).unsqueeze(2)
    yy = xx.permute(0, 2, 1)
    dist = xx + yy - 2.0 * torch.bmm(x, x.permute(0, 2, 1))
    dist[:, torch.arange(dist.shape[1]), torch.arange(dist.shape[2])] = 0
    return dist

def knn_graph(kpts, k):
    dist = pdist_squared(kpts.unsqueeze(0)).squeeze(0)
    dist_knn = dist.topk(k + 1, dim=0, largest=False)[0]
    return ((dist <= dist_knn[-1, :]) & (dist > 0)).float(), dist

def laplacian(kpts, k, lambd, sigma=0):
    A, dist = knn_graph(kpts, k)
    W = lambd * A
    if sigma > 0:
        W = W * torch.exp(- dist / (sigma ** 2))
    return torch.diag(W.sum(1) + 1) - W, W

def densify(kpts, kpts_disp, shape, smooth_iter=4, kernel_size=7, eps=0.001):
    N, _ = kpts.shape
    device = kpts.device
    D, H, W = shape
    
    grid = torch.zeros(1, 4, D, H, W).to(device)
    grid.requires_grad=True
    kpts_disp_h = torch.cat((kpts_disp, torch.ones(N, 1).to(device)), dim = 1)
    out = F.grid_sample(grid, kpts.view(1, -1, 1, 1, 3), padding_mode='border', align_corners=True)
    loss = (out.view(4, -1).t() * kpts_disp_h).sum()
    loss.backward()
    grid.data = grid.grad.data
        
    avg_pool = nn.AvgPool3d(kernel_size, stride=1, padding=kernel_size // 2).to(device)
    for i in range(smooth_iter):
        grid = avg_pool(grid)
    grid = grid[:, :3, :, :, :] / (grid[:, 3:4, :, :, :] + eps)
    
    return grid

def fit_sparse(kpts, kpts_disp, soft_cost, shape, scale_factor=3, noise_sigma=0.05, kernel_size=5, smooth_iter=3, init_lr=0.015, lambd=1.5, num_iter=100):
    N, _ = kpts.shape
    device = kpts.device
    D, H, W = shape
    
    Ds = D // scale_factor
    Hs = H // scale_factor
    Ws = W // scale_factor
    
    dense_disp_s = densify(kpts, kpts_disp, (Ds, Hs, Ws))

    dense_disp = F.interpolate(dense_disp_s, size=(D, H, W))
    
    net = nn.Parameter(torch.randn(1, 3, Ds, Hs, Ws).to(device))
    net.data = dense_disp_s.detach() + torch.randn_like(dense_disp_s) * noise_sigma
    
    avg_pool = nn.AvgPool3d(kernel_size, stride=1, padding=kernel_size // 2).to(device)
    
    optimizer = optim.Adam([net], lr=init_lr)
    
    for i in range(num_iter):
        optimizer.zero_grad()
        grid_fit = net
        for j in range(smooth_iter):
            grid_fit = avg_pool(grid_fit)
        net_sampled = F.grid_sample(grid_fit, kpts.view(1, -1, 1, 1, 3), align_corners=True).permute(2, 0, 3, 4, 1)
        cost_sampled = F.grid_sample(soft_cost.permute(1, 0, 2, 3, 4), net_sampled, align_corners=True)
        loss = (- cost_sampled).mean()

        loss += lambd * ((grid_fit[0, :, :, :, 1:] - grid_fit[0, :, :, :, :-1]) ** 2).mean() + \
                lambd * ((grid_fit[0, :, :, 1:, :] - grid_fit[0, :, :, :-1, :]) ** 2).mean() + \
                lambd * ((grid_fit[0, :, 1:, :, :] - grid_fit[0, :, :-1, :, :]) ** 2).mean()
        loss.backward()

        optimizer.step()
        
    dense_disp_fit = F.interpolate(grid_fit.detach(), size=(D, H, W))
    
    return dense_disp_fit, dense_disp

def fit(input_img_fixed,
        input_file_dat,
        input_file_marg,
        input_file_sim,
        output_file_dat,
        lambd,
        k,
        disp_width,
        quant,
        alpha,
        device):
    
    img_fixed = torch.from_numpy(nib.load(input_img_fixed).get_data()).float().to(device)
    D, H, W = img_fixed.shape

    content = open(input_file_dat, 'rb').read()
    data = np.array(struct.unpack("f" * (len(content) // 4), content)).reshape(-1,6)
    kpts_fixed_vox = torch.from_numpy(data[:, :3]).float().to(device)
    kpts_moving_vox = torch.from_numpy(data[:, 3:]).float().to(device)
    kpts_fixed = (torch.from_numpy(data[:, :3]).flip(1).float() / (torch.Tensor([W, H, D]) - 1).view(1, -1) * 2 - 1).to(device)

    #content = open(input_file_sim, 'rb' ).read()
    #disp_map = torch.from_numpy(np.array(struct.unpack("f" * (len(content) // 4), content)).reshape(kpts_fixed.size(0), -1)).float().to(device)
    
    content = open(input_file_marg, 'rb' ).read()
    data_marginals = torch.from_numpy(np.array(struct.unpack("f" * (len(content) // 4), content)).reshape(kpts_fixed.size(0), -1)).float().to(device)
    
    #L, _ = laplacian(kpts_fixed, k, lambd) #using Laplacian smoothed similarities
    #disp_map_reg = torch.solve(disp_map.view(L.size(0), -1), L)[0]

    disp_range = (disp_width - 1) / 2 * quant
    disp = F.affine_grid(torch.eye(3, 4).unsqueeze(0), (1, 1, disp_width, disp_width, disp_width), align_corners=True).to(device)

    soft_disp_map_reg = torch.softmax(- alpha * 0.1*data_marginals, 1) #using MRF regularised similarities

    #soft_disp_map_reg = torch.softmax(- alpha * disp_map_reg, 1) #using Laplacian smoothed similarities
    
    kpts_fixed_disp = torch.gather(disp.view(1, -1, 3).repeat(soft_disp_map_reg.size(0), 1, 1), 1, torch.argmax(soft_disp_map_reg,1).view(-1, 1, 1).repeat(1, 1, 3)).squeeze(1)

    dense_disp_fit, _ = fit_sparse(kpts_fixed, kpts_fixed_disp, soft_disp_map_reg.view(1, -1, disp_width, disp_width, disp_width), (D, H, W))

    dense_fit_sampled = F.grid_sample(dense_disp_fit, kpts_fixed.view(1, -1, 1, 1, 3), align_corners=True).view(3, -1).t()

    kpts_moving_vox_new = kpts_fixed_vox + disp_range*dense_fit_sampled
    data_new = torch.cat((kpts_fixed_vox, kpts_moving_vox_new), 1).flatten().cpu().numpy()

    file = open(output_file_dat, 'wb')
    f = "f" * len(data_new)
    binary_data = struct.pack(f, *data_new)
    file.write(binary_data)
    file.close()
    
    return
    

if __name__ == "__main__":
    parser = ArgumentParser()

    parser.add_argument("--input_img_fixed",
                        type=str,
                        help="path to input fixed image")
    
    parser.add_argument("--input_file_dat",
                        type=str,
                        help="path to input dat file")
    
    parser.add_argument("--input_file_marg",
                        type=str,
                        help="path to input marg file")
    
    parser.add_argument("--input_file_sim",
                        type=str,
                        help="path to input sim file")
    
    parser.add_argument("--output_file_dat",
                        type=str,
                        help="path to output dat file")
    
    parser.add_argument("--lambd",
                        type=float,
                        default=.5,
                        help="lambda for laplacian regularization")
    
    parser.add_argument("--k",
                        type=int,
                        default=15,
                        help="k (nearest neighbour) for laplacian regularization")
    
    parser.add_argument("--disp_width",
                        type=int,
                        default=23,
                        help="displacement width")
    
    parser.add_argument("--quant",
                        type=int,
                        default=2,
                        help="quantisation")
    
    parser.add_argument("--alpha",
                        type=float,
                        default=15,
                        help="alpha")
    
    parser.add_argument("--device",
                        type=str,
                        default='cuda',
                        help="cuda or cpu")
   
    fit(**vars(parser.parse_args()))