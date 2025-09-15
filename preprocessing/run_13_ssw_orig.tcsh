#!/bin/tcsh

# SSW: run @SSwarper to skullstrip (SS) and estimate a nonlinear warp.

# NOTES
#
# + This is a Biowulf script (has slurm stuff)
# + Run this script in the scripts/ dir, to execute the corresponding do_*tcsh
# + The ${dir_basic} is in a different spot than in present ${inroot}

# To execute:  
#     tcsh RUN_SCRIPT_NAME

# --------------------------------------------------------------------------

# specify script to execute
set cmd           = 13_ssw_orig

# upper directories
set dir_scr       = $PWD
set dir_inroot    = ..
set dir_log       = ${dir_inroot}/logs
set dir_swarm     = ${dir_inroot}/swarms
set dir_basic     = ${dir_inroot}/BIDS


# running
set cdir_log      = ${dir_log}/logs_${cmd}
set scr_swarm     = ${dir_swarm}/swarm_${cmd}.txt
set scr_cmd       = ${dir_scr}/do_${cmd}.tcsh

# --------------------------------------------------------------------------

\mkdir -p ${cdir_log}
\mkdir -p ${dir_swarm}

#clear away older swarm script 
 if ( -e ${scr_swarm} ) then
    \rm ${scr_swarm}
 endif

# --------------------------------------------------------------------------

# get list of all subj IDs for proc
cd ${dir_basic}


##list of all subjects 
set all_subj = ( sub-001 sub-002 )
 
cd -

cat <<EOF

++ Proc command:  ${cmd}
++ Found ${#all_subj} subj:

EOF

# -------------------------------------------------------------------------
# build swarm command

# loop over all subj
foreach subj ( ${all_subj} )
    echo "++ Prepare cmd for: ${subj}"

    # get session ID(s)
    cd ${dir_basic}/${subj}
    set all_ses = ( ses-1 )
    cd -

    foreach ses ( ${all_ses} )
        echo "   ... and ses: ${ses}"

        set log = ${cdir_log}/log_${cmd}_${subj}_${ses}.txt

        # run command script (verbosely, and don't use '-e'); 
        # log terminal text.
        echo "tcsh -xf ${scr_cmd} ${subj} ${ses} \\"    >> ${scr_swarm}
        echo "     |& tee ${log}"                       >> ${scr_swarm}
    end 
end

# -------------------------------------------------------------------------
# run swarm command
cd ${dir_scr}

echo "++ And start swarming: ${scr_swarm}"

swarm                                                              \
    -f ${scr_swarm}                                                \
    --partition=norm                                        \
    --threads-per-process=16                                       \
    --gb-per-process=10                                            \
    --time=06:00:00                                                \
    --gres=lscratch:6                                              \
    --logdir=${cdir_log}                                           \
    --job-name=job_${cmd}                                          \
    --merge-output                                                 \
    --usecsh
