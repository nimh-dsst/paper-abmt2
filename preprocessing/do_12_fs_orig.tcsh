#!/bin/tcsh

# FS: run FreeSurfer's recon-all and AFNI's @SUMA_Make_Spec_FS.

# Process a single subj+ses pair.  Run this script in
# apmulti_demo/scripts/, via the corresponding run_*tcsh script.

# This is a Biowulf script.  Run it via swarm (see partner run*.tcsh).

# ----------------------------- biowulf-cmd ---------------------------------
# load modules
source /etc/profile.d/modules.csh
module load afni freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.csh

# set N_threads for OpenMP
# + consider using up to 4 threads, because of "-parallel" in recon-all
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
set dir_physio     = ${dir_inroot}/data_14_physio

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_epi       = ${sdir_basic}/func
set sdir_fs        = ${dir_fs}/${subj}/${ses}
set sdir_suma      = ${sdir_fs}/SUMA
set sdir_ssw       = ${dir_ssw}/${subj}/${ses}
set sdir_physio    = ${dir_physio}/${subj}/${ses}

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# dataset inputs
set dset_anat_00  = ${sdir_basic}/anat/${subj}_${ses}_*T1w.nii.gz
#set dset_anat_00_MMM = ${sdir_fs}/${subj}_${ses}_T1w_MMM.nii.gz
#set dset_anat_00_mskd = ${sdir_fs}/${subj}_${ses}_T1w_mskd.nii.gz
#set dset_anat_00_mskd_u = ${sdir_fs}/${subj}_${ses}_T1w_mskd_u.nii.gz
#set dset_anat_00_mskd_unifized = ${sdir_fs}/${subj}_${ses}_T1w_mskd_unifized.nii.gz

# control variables

# check available N_threads and report what is being used
set nthr_avail = `afni_system_check.py -disp_num_cpu`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

# ----------------------------- biowulf-cmd --------------------------------
# try to use /lscratch for speed 
if ( -d /lscratch/$SLURM_JOBID ) then
    set usetemp  = 1
    set sdir_BW  = ${sdir_fs}
    set sdir_fs  = /lscratch/$SLURM_JOBID/${subj}_${ses}

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

\mkdir -p ${sdir_fs}

# Create an automask of the anatomical
#3dAutomask				   \
#    -prefix	    ${dset_anat_00_MMM}	   \
#    ${dset_anat_00}

# Apply the mask to the anatomical
#3dcalc					   \
#    -a		    ${dset_anat_00_MMM}	   \
#    -b		    ${dset_anat_00}	   \
#    -expr	    'a*b'		   \
#    -prefix	    ${dset_anat_00_mskd}   

# apply brightness adjustment
#3dUnifize -GM	\
#	  -prefix "${dset_anat_00_mskd_u}"	\
#	  -input "${dset_anat_00_mskd}"

# Put the noise background back into the unifize anat
#3dcalc					   \
#    -a		${dset_anat_00_mskd_u}     \
#    -b		${dset_anat_00}		   \
#    -expr	'a+not(a)*b'		   \
#    -prefix	${dset_anat_00_mskd_unifized}

time recon-all                                                        \
    -all                                                              \
    -3T                                                               \
#    -parallel                                                         \
    -sd        "${sdir_fs}"                                           \
    -subjid    "${subj}"                                              \
    -i         "${dset_anat_00}"

if ( ${status} ) then
    set ecode = 1
    goto COPY_AND_EXIT
endif

# compress path (because of recon-all output dir naming): 
#   move output from DIR/${subj}/${ses}/${subj}/* to DIR/${subj}/${ses}/*
\mv    ${sdir_fs}/${subj}/* ${sdir_fs}/.
\rmdir ${sdir_fs}/${subj}

@SUMA_Make_Spec_FS                                                    \
    -fs_setup                                                         \
    -NIFTI                                                            \
    -sid       "${subj}"                                              \
    -fspath    "${sdir_fs}"

if ( ${status} ) then
    set ecode = 1
    goto COPY_AND_EXIT
endif

echo "++ FINISHED FS"

# ---------------------------------------------------------------------------

COPY_AND_EXIT:

# ----------------------------- biowulf-cmd --------------------------------
# copy back from /lscratch to "real" location
if( ${usetemp} && -d ${sdir_fs} ) then
    echo "++ Used /lscratch"
    echo "++ Copy from: ${sdir_fs}"
    echo "          to: ${sdir_BW}"
    \cp -pr   ${sdir_fs}/* ${sdir_BW}/.

    # reset group permission
    chgrp -R ${grp_own} ${sdir_BW}
endif
# ---------------------------------------------------------------------------

exit ${ecode}

