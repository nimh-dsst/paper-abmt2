#!/bin/tcsh

# SSW: run @SSwarper to skullstrip (SS) and estimate a nonlinear warp.

# Process a single subj+ses pair.  Run this script in
# apmulti_demo/scripts/, via the corresponding run_*tcsh script.

# This is a Biowulf script.  Run it via swarm (see partner run*.tcsh).

# ----------------------------- biowulf-cmd ---------------------------------
# load modules
source /etc/profile.d/modules.csh
module load afni 

# set N_threads for OpenMP
# + consider using up to 16 threads (alignment programs are parallelized)
setenv OMP_NUM_THREADS $SLURM_CPUS_PER_TASK

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

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_epi       = ${sdir_basic}/func
set sdir_fs        = ${dir_fs}/${subj}/${ses}
set sdir_suma      = ${sdir_fs}/SUMA
set sdir_ssw       = ${dir_ssw}/${subj}/${ses}

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# dataset inputs
set dset_anat_00  = ${sdir_basic}/anat/${subj}_${ses}_*T1w.nii.gz
set dset_anat_00_zp = ${sdir_ssw}/${subj}_${ses}_T1w_ZP.nii.gz

set mask_fs_orig    = ${sdir_suma}/fs_parc_wb_mask.nii.gz
set mask_fs_res     = ${sdir_ssw}/fs_parc_wb_mask_ZP.nii.gz
# control variables

# check available N_threads and report what is being used
set nthr_avail = `afni_system_check.py -disp_num_cpu`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

# ----------------------------- biowulf-cmd --------------------------------
# try to use /lscratch for speed 
if ( -d /lscratch/$SLURM_JOBID ) then
    set usetemp  = 1
    set sdir_BW  = ${sdir_ssw}
    set sdir_ssw = /lscratch/$SLURM_JOBID/${subj}_${ses}

    # prep for group permission reset
    \mkdir -p ${sdir_BW}
    set grp_own  = `\ls -ld ${sdir_BW} | awk '{print $4}'`
else
    set usetemp  = 0
endif
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# run programs
# ---------------------------------------------------------------------------

# make output dir
\mkdir -p ${sdir_ssw}

# chop out unneeded lower slices
3dZeropad                                  \
    -overwrite                             \
    -I              -70                    \
    -prefix         ${dset_anat_00_zp}     \
    ${dset_anat_00}

if ( ${status} ) then
    set ecode = 1
    goto COPY_AND_EXIT
endif

# resample FS mask to ZP'ed anatomical
3dresample                                 \
    -overwrite                             \
    -master        ${dset_anat_00_zp}      \
    -input         ${mask_fs_orig}         \
    -prefix        ${mask_fs_res}          \
    -rmode         NN

if ( ${status} ) then
    set ecode = 2
    goto COPY_AND_EXIT
endif

time /path/to/code/sswarper2B                \
    -base    "${template}"                                            \
    -subid   "${subj}"                                                \
    -input   "${dset_anat_00_zp}"                                     \
    -mask_ss "${mask_fs_res}"                                         \
    -cost_aff      nmi                                                \
    -cost_nl_final lpa                                                \
    -odir    "${sdir_ssw}"                                            \
    |& tee   ${sdir_ssw}/out.log_ssw_${subj}.txt


if ( ${status} ) then
    set ecode = 3
    goto COPY_AND_EXIT
endif

echo "++ FINISHED SSW"

# ---------------------------------------------------------------------------

COPY_AND_EXIT:

# ----------------------------- biowulf-cmd --------------------------------
# copy back from /lscratch to "real" location
if( ${usetemp} && -d ${sdir_ssw} ) then
    echo "++ Used /lscratch"
    echo "++ Copy from: ${sdir_ssw}"
    echo "          to: ${sdir_BW}"
    \cp -pr   ${sdir_ssw}/* ${sdir_BW}/.

    # reset group permission
    chgrp -R ${grp_own} ${sdir_BW}
endif
# ---------------------------------------------------------------------------

exit $ecode

