#!/bin/bash

##################################################
# 2/4/2020 - Kaiwen
# Test to revert back a transformation field.
##################################################

SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
bash_config_file=${SRC_ROOT}/bash_config/20200203_non_rigid_niftyreg_image2image_label.sh

echo "Non-rigid pipeline -- revert and interpolate deformation field"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

reg_folder=${OUT_ROOT}/interp_revert_trans
mkdir -p ${reg_folder}

trans=${reg_folder}/moving1_trans.nii.gz
trans_revert=${reg_folder}/moving1_trans_revert.nii.gz
moving_img=${reg_folder}/labels.nii.gz
out_img=${reg_folder}/labels_reverted.nii.gz
ref_img=${reg_folder}/moving1.nii.gz

echo
echo "Transformation ${trans}"
echo "Moving image ${moving_img}"
echo "Output image ${out_img}"
echo

start=`date +%s`
#Usage:	./reg_transform [OPTIONS].
# ....
#	-invNrr <filename1> <filename2> <filename3>
#		Invert a non-rigid transformation and save the result as a deformation field.
#		filename1 - Input transformation file name
#		filename2 - Input floating image where the inverted transformation is defined
#		filename3 - Output inverted transformation file name
#		Note that the cubic b-spline grid parametrisations can not be inverted without approximation,
#		as a result, they are converted into deformation fields before inversion.
# ....
set -o xtrace
${REG_TOOL_ROOT}/reg_transform \
  -ref ${ref_img} \
  -invNrr ${trans} ${moving_img} ${trans_revert}
set +o xtrace

#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#Usage:	./reg_resample -ref <filename> -flo <filename> [OPTIONS].
#	-ref <filename>
#		Filename of the reference image (mandatory)
#	-flo <filename>
#		Filename of the floating image (mandatory)
#
#* * OPTIONS * *
#	-trans <filename>
#		Filename of the file containing the transformation parametrisation (from reg_aladin, reg_f3d or reg_transform)
#	-res <filename>
#		Filename of the resampled image [none]
#	-blank <filename>
#		Filename of the resampled blank grid [none]
#	-inter <int>
#		Interpolation order (0, 1, 3, 4)[3] (0=NN, 1=LIN; 3=CUB, 4=SINC)
#	-pad <int>
#		Interpolation padding value [0]
#	-tensor
#		The last six timepoints of the floating image are considered to be tensor order as XX, XY, YY, XZ, YZ, ZZ [off]
#	-psf
#		Perform the resampling in two steps to resample an image to a lower resolution [off]
#	-psf_alg <0/1>
#		Minimise the matrix metric (0) or the determinant (1) when estimating the PSF [0]
#	-voff
#		Turns verbose off [on]
#	-omp <int>
#		Number of thread to use with OpenMP. [32/32]
#	--version
#		Print current version and exit (1.5.68)
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
set -o xtrace
${REG_TOOL_ROOT}/reg_resample \
 -ref ${ref_img}\
 -flo ${moving_img}\
 -trans ${trans_revert}\
 -res ${out_img}\
 -inter 0\
 -pad 0\
 -omp ${NUM_PROCESSES}
set +o xtrace

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"