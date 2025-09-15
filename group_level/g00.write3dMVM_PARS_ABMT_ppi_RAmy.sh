#!/bin/tcsh

############
# Settings #
############

set ssData = /path/to/data_23_ap_task_NL	

set Subjs = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f1`
set PARSpre = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f15`
set PARSpost = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f16`
set Age = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f14`
set Sex = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f3`
set ABMTGroup = `grep -v '#' change_Anx_ABMT_PARS.txt | cut -f4`

set my3dMVMcmd = 3dMVM.ABMT_PARS_ppi_RAmy
set mytable = 3dMVM.ABMT_PARS_ppi_RAmy_table.txt

touch $my3dMVMcmd
echo '#\!/usr/bin/tcsh\n' >> $my3dMVMcmd
echo "3dMVM -prefix ABMT_PARS_ppi_RAmy -jobs 16 \\" >> $my3dMVMcmd
echo "\t-bsVars 'ABMTGroup*PARSpost+PARSpre+Age+Sex'\t\t\\" >> $my3dMVMcmd
echo "\t-wsVars 'Condition'\t\t\\" >> $my3dMVMcmd
echo "\t-qVars 'PARSpost,PARSpre,Age'\t\t\\" >> $my3dMVMcmd
echo "\t-qVarCenters '0,0,0'\t\t\\" >> $my3dMVMcmd   
echo "\t-dataTable\t@$mytable\t\\" >> $my3dMVMcmd
echo "\n" >> $my3dMVMcmd

touch $mytable
echo "Subj\tABMTGroup\tPARSpost\tPARSpre\tAge\tSex\tCondition\tInputFile\t\t\\" >> $mytable
# Add all datasets specified in grpTemplate
foreach i (`seq $#Subjs`)
echo "$Subjs[$i]\t$ABMTGroup[$i]\t$PARSpost[$i]\t$PARSpre[$i]\t$Age[$i]\t$Sex[$i]\tcongruent\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.RAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[congruent.gPPI#0_Coef]\t\\" >> $mytable
echo "$Subjs[$i]\t$ABMTGroup[$i]\t$PARSpost[$i]\t$PARSpre[$i]\t$Age[$i]\t$Sex[$i]\tincongruent\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.RAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[incongruent.gPPI#0_Coef]\t\\" >> $mytable
echo "$Subjs[$i]\t$ABMTGroup[$i]\t$PARSpost[$i]\t$PARSpre[$i]\t$Age[$i]\t$Sex[$i]\tneutral\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.RAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[neutral.gPPI#0_Coef]\t\\" >> $mytable
end

echo "tcsh $my3dMVMcmd" > run_${my3dMVMcmd}.csh

