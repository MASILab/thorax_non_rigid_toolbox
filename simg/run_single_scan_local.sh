#!/bin/bash

#SCAN_NAME=00000674time20170601.nii.gz
#SCAN_NAME=00001126time20180214.nii.gz
#SCAN_NAME=00000824time20170928.nii.gz
#SCAN_NAME=00000575time20170323.nii.gz
#SCAN_NAME=00000900time20171208.nii.gz
SCAN_NAME=00000557time20170316.nii.gz
#

set -o xtrace
singularity exec --contain -B /nfs/masi/xuk9/src/Thorax_non_rigid_combine/simg/bin:/bin_external -B /nfs/masi/xuk9/SPORE/data/data_flat:/data_root -B /nfs/masi/xuk9/SPORE/clustering/registration/20200512_corrField/male:/proj_root -B /nfs/masi/xuk9/src/Thorax_affine_combine:/src/Thorax_affine_combine -B /nfs/masi/xuk9/src/Thorax_non_rigid_combine:/src/Thorax_non_rigid_combine /nfs/masi/xuk9/singularity/thorax_combine/thorax_combine_20201022.img run_combine_pipeline.sh ${SCAN_NAME}
set +o xtrace

#for SCAN_NAME in 00000087time20160105.nii.gz 00000122time20150629.nii.gz 00000159time20170421.nii.gz 00000754time20160708.nii.gz 00000839time20131008.nii.gz 00000852time20150918.nii.gz 00000852time20161101.nii.gz 00000900time20171208.nii.gz 00001126time20180214.nii.gz
#do
#    set -o xtrace
#    singularity exec --contain -B /home/xuk9/src/Thorax_non_rigid_combine/simg/bin:/bin_external -B /scratch/xuk9/nifti/SPORE/data_flat:/data_root -B /scratch/xuk9/nifti/SPORE/reg_pipeline:/proj_root -B /home/xuk9/src/Thorax_affine_combine:/src/Thorax_affine_combine -B /home/xuk9/src/Thorax_non_rigid_combine:/src/Thorax_non_rigid_combine /scratch/xuk9/singularity/thorax_combine_20201022.img run_combine_pipeline.sh ${SCAN_NAME} &
#    set +o xtrace
#done


