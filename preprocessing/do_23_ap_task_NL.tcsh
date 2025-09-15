#!/bin/tcsh

# AP_TASK_NL: use stims and full SSW.

# *** NB: REVISIT TIMING FILES--- HOW THEY ARE CREATED, STORE IN DATA DIRS, AND RUN ****

# NOTES
#
# + This is a Biowulf script (has slurm stuff)
# + Run this script in the scripts/ dir, via the corresponding run_*tcsh
# + The ${dir_basic} is in a different spot than in present ${inroot}
# + Filenames are not quite fully BIDSy (e.g., see ${dset_anat_00})
# + There is no session level ${ses} 
# + Module loading Python 3.9 here, but not necessary

# ----------------------------- biowulf-cmd ---------------------------------
# load modules
source /etc/profile.d/modules.csh
module load afni python/3.9 

# set N_threads for OpenMP
# + consider using up to 4 threads, because of "-parallel" in recon-all
setenv OMP_NUM_THREADS $SLURM_CPUS_PER_TASK

# compress BRIK files
setenv AFNI_COMPRESSOR GZIP

# initial exit code; we don't exit at fail, to copy partial results back
set ecode = 0
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# top level definitions (constant across demo)
# ---------------------------------------------------------------------------

# labels
set subj           = $1
set ses            = $2

set template       = MNI152_2009_template_SSW.nii.gz 

# upper directories
set dir_inroot     = ${PWD:h}                        # one dir above scripts/
set dir_log        = ${dir_inroot}/logs
set dir_basic      = /path/to/BIDS
set dir_fs         = ${dir_inroot}/data_12_fs
set dir_ssw        = ${dir_inroot}/data_13_ssw
set dir_timing     = ${dir_inroot}/data_15_timing

set dir_ap         = ${dir_inroot}/data_23_ap_task_NL

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_epi       = ${sdir_basic}/func # Use this for timing files
set sdir_fs        = ${dir_fs}/${subj}/${ses}
set sdir_suma      = ${sdir_fs}/SUMA
set sdir_ssw       = ${dir_ssw}/${subj}/${ses}
#set sdir_physio    = ${dir_physio}/${subj}/${ses}
set sdir_ap        = ${dir_ap}/${subj}/${ses}
#set sdir_fm	   = ${dir_basic}/${subj}/${ses}/dc_scan

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# dataset inputs
set dsets_epi   = ( ${sdir_basic}/func/${subj}_${ses}_task-TAU*_run-?_bold.nii* )
set dset_anat_00  = ${sdir_basic}/anat/${subj}_${ses}_*T1w.nii.gz
set anat_cp       = ${sdir_ssw}/anatSS.${subj}.nii

set dsets_NL_warp = ( ${sdir_ssw}/anatQQ.${subj}.nii         \
                      ${sdir_ssw}/anatQQ.${subj}.aff12.1D    \
                      ${sdir_ssw}/anatQQ.${subj}_WARP.nii  )

set roi_FSWe      = ${sdir_suma}/fs_ap_wm.nii.gz

set timing_files   = ( ${dir_timing}/${subj}_${ses}_task-TAU_congruent.1D  \
                      ${dir_timing}/${subj}_${ses}_task-TAU_incongruent.1D  \
                          ${dir_timing}/${subj}_${ses}_task-TAU_neutral.1D  \
			${dir_timing}/${subj}_${ses}_task-TAU_error.1D)
set stim_classes   = ( congruent incongruent neutral error )




# control variables
set nt_rm         = 4 # The time before the actual task 
set warp_dxyz     = 2.5                    # final (isotropic) voxel size
set blur_size     = 6.5
set cen_motion    = 1.0
set cen_outliers  = 0.1 # 10% of a volume has to be outlier to be removed
set run_csim      = yes
set njobs         = `afni_check_omp`


# check available N_threads and report what is being used
set nthr_avail = `afni_system_check.py -disp_num_cpu`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

# ----------------------------- biowulf-cmd --------------------------------
# try to use /lscratch for speed 
if ( -d /lscratch/$SLURM_JOBID ) then
    set usetemp  = 1
    set sdir_BW  = ${sdir_ap}
    set sdir_ap = /lscratch/$SLURM_JOBID/${subj}  #_${ses}

    # do here bc of group permissions
    \mkdir -p ${sdir_BW}
    set grp_own = `\ls -ld ${sdir_BW} | awk '{print $4}'`
else
    set usetemp  = 0
endif
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# run programs
# ---------------------------------------------------------------------------

set ap_cmd = ${sdir_ap}/ap.cmd.${subj}

\mkdir -p ${sdir_ap}

# write AP command to file 
cat << EOF >! ${ap_cmd}

afni_proc.py                                                                 \
    -subj_id                  ${subj}                                        \
    -blocks                   despike tshift align tlrc volreg mask blur     \
                              scale regress                                  \
    -dsets                    ${dsets_epi}                                   \
    -tcat_remove_first_trs    ${nt_rm}                                       \
    -radial_correlate_blocks  tcat volreg regress                                    \
    -copy_anat                ${anat_cp}                                     \
    -anat_has_skull           no                                             \
    -anat_follower            anat_w_skull anat ${dset_anat_00}              \
    -anat_follower_ROI	      FSWe epi ${roi_FSWe}		    	             \
    -anat_follower_erode      FSWe					                         \
    -regress_anaticor_fast						                             \
    -regress_anaticor_label   FSWe                                          \
    -volreg_align_to          MIN_OUTLIER                                    \
    -volreg_align_e2a                                                        \
    -volreg_tlrc_warp                                                        \
    -volreg_warp_dxyz         ${warp_dxyz}                                   \
    -align_unifize_epi	      local					     \
    -align_opts_aea           -check_flip -cost lpc+ZZ -giant_move -AddEdge  \
    -tlrc_base                ${template}                                    \
    -tlrc_NL_warp                                                            \
    -tlrc_NL_warped_dsets     ${dsets_NL_warp}                               \
    -mask_epi_anat            yes                                            \
    -blur_in_mask             yes                                            \
    -blur_size                ${blur_size}                                   \
    -blur_to_fwhm                                                            \
    -regress_stim_times       ${timing_files}                                \
    -regress_stim_labels      ${stim_classes}                                \
    -regress_basis            'GAM'                                    \
    -regress_local_times                                                     \
    -regress_motion_per_run                                                  \
    -regress_censor_motion    ${cen_motion}                                  \
    -regress_censor_outliers  ${cen_outliers}                                \
    -regress_compute_fitts                                                   \
    -regress_make_ideal_sum   sum_ideal.1D                                   \
    -regress_est_blur_epits                                                  \
    -regress_est_blur_errts                                                  \
    -regress_run_clustsim     ${run_csim}                                    \
    -regress_reml_exec                                                       \
    -regress_opts_reml                                                       \
        -GOFORIT              99                                             \
    -regress_opts_3dD                                                        \
        -bout                                                                \
        -jobs                 ${njobs}                                       \
        -allzero_OK                                                          \
        -GOFORIT              99                                             \
        -num_glt              8                                             \
     	-gltsym 'SYM: +incongruent -congruent' -glt_label 1 InCon_Con_Bias 				\
     	-gltsym 'SYM: +congruent -neutral' -glt_label 2 AngCongvNeutral 				\
     	-gltsym 'SYM: +incongruent -neutral' -glt_label 3 AngInConvNeutral 				\
      	-gltsym 'SYM: +incongruent +congruent' -glt_label 4 AngryvBaseline 				\
        -gltsym 'SYM: +incongruent +congruent +neutral' -glt_label 5 FacevBaseline 			\
 	-gltsym 'SYM: +3*error -incongruent -congruent -neutral' -glt_label 6 ErrorvCorrect 	\
        -gltsym 'SYM: +incongruent +congruent -2*neutral' -glt_label 7 AngConAngInConvNeutral        		\
        -gltsym 'SYM: +.5*incongruent +.5*congruent' -glt_label 8 Angry            		\
    -html_review_style        pythonic
 

EOF

if ( ${status} ) then
    set ecode = 1
    goto COPY_AND_EXIT
endif

cd ${sdir_ap}

# run AP to make proc script
tcsh -xef ${ap_cmd} |& tee output.run_ap_${subj}.txt

if ( ${status} ) then
    set ecode = 2
    goto COPY_AND_EXIT
endif

# run proc script
time tcsh -xef proc.${subj} |& tee output.${subj}.txt

if ( ${status} ) then
    set ecode = 3
    goto COPY_AND_EXIT
endif

echo "++ done proc ok"

# ---------------------------------------------------------------------------

COPY_AND_EXIT:

# ----------------------------- biowulf-cmd --------------------------------
# copy back from /lscratch to "real" location
if( ${usetemp} && -d ${sdir_ap} ) then
    echo "++ Used /lscratch"
    echo "++ Copy from: ${sdir_ap}"
    echo "          to: ${sdir_BW}"
    #\mkdir -p ${sdir_BW}
    \cp -pr   ${sdir_ap}/* ${sdir_BW}/.
    
    # reset grp permissions
    chgrp -R ${grp_own} ${sdir_BW}
endif
# ---------------------------------------------------------------------------

if ( ${ecode} ) then
    echo "++ BAD FINISH: AP_TASK_NL (ecode = ${ecode})"
else
    echo "++ GOOD FINISH: AP_TASK_NL"
endif

exit $ecode

