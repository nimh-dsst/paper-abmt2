#!/bin/tcsh

############
# Settings #
############

set ssData = /path/to/data_23_ap_task_NL 	 #Study directory

set Subjs = `grep -v '#' Time1_HV-Anx.txt | cut -f1` 
set Group = `grep -v '#' Time1_HV-Anx.txt | cut -f2`
set Age = `grep -v '#' Time1_HV-Anx.txt | cut -f11`
set Sex = `grep -v '#' Time1_HV-Anx.txt | cut -f3`

set my3dLMEcmd = 3dLME.Time1_HV-Anx_ppi_LAmy
set mytable = 3dLME.Time1_HV-Anx_ppi_LAmy_table.txt

touch $my3dLMEcmd
echo '#\!/usr/bin/tcsh\n' >> $my3dLMEcmd
echo "3dLMEr -prefix LME.Time1_HV-Anx_ppi_LAmy -jobs 16 \\" >> $my3dLMEcmd
echo "\t-model 'Group*Condition+(1|Subj)+Age+Sex'\t\t\\" >> $my3dLMEcmd
echo "\t-qVars 'Age'\t\t\\" >> $my3dLMEcmd
echo "\t-qVarCenters '0'\t\t\\" >> $my3dLMEcmd  
echo "\t-bounds -2 2\t\t\\" >> $my3dLMEcmd  
echo "\t-dataTable\t@$mytable\t\\" >> $my3dLMEcmd
echo "\n" >> $my3dLMEcmd

touch $mytable
echo "Subj\tGroup\tAge\tSex\tCondition\tInputFile\t\t\\" >> $mytable
foreach i (`seq $#Subjs`)
echo "$Subjs[$i]\t$Group[$i]\t$Age[$i]\t$Sex[$i]\tcongruent\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.LAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[congruent.gPPI#0_Coef]\t\\" >> $mytable
echo "$Subjs[$i]\t$Group[$i]\t$Age[$i]\t$Sex[$i]\tincongruent\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.LAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[incongruent.gPPI#0_Coef]\t\\" >> $mytable
echo "$Subjs[$i]\t$Group[$i]\t$Age[$i]\t$Sex[$i]\tneutral\t${ssData}/$Subjs[$i]/ses-1/$Subjs[$i].results.1mmOutlierCensored/PPI.LAmy_50_resampled_mask_gpEPImask.0.9.FINAL_ses-1stats.$Subjs[$i]+tlrc[neutral.gPPI#0_Coef]\t\\" >> $mytable
end


echo "tcsh $my3dLMEcmd" > run_${my3dLMEcmd}.csh

