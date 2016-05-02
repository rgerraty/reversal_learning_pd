#Analysis Code for Network Dynamics and Dopamine in Parkinson's Disease
##Raphael Gerraty, Madeleine Sharp, Amanda Buch 2016

Descriptions and example scripts for running network preprocessing and analysis functions contained in this repository. 


### Set up directory structure
```{.bash}
#make sure only IDs corresponding to correct session are included in this loop
for i in /data/engine/abuch/NETPD/unzipped/<sess_2 ids>/scans/*/resources/DICOM/files/
do
	bash move_dicoms.sh $i /data/engine/abuch/NETPD/ 2
done
```

### Convert dicoms to niftis and reorient
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/{B0,T*}/dicoms/
do
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/convert_dicoms.sh $i
done
```

### Generate field map for B0 correction
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/B0;  
do 
	bo=$(ls $i/2*nii.gz); 
	echo $bo; 
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/B0_unwarp.sh $bo; 
done
```

### Run anatomical preprocessing
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/T1/;
do 
	if [ -d $i/bravo.anat ]
		then
		echo fsl_anat already run for $i
	else
		if [ ! -e $i/bravo.nii.gz ]
			then
			bravo=$(ls $i/co*nii.gz | head -n1)
			mv $bravo bravo.nii.gz
		fi
		fsl_anat $i/bravo.nii.gz
done
```

### B0 field correction for EPI scans
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/{REST,RUN_?}
do

	unwarp=$(ls $i/*_unwarp.nii.gz 2>/dev/null)
	epi=$(ls $i/*nii.gz | grep -v unwarp)

	if [[ -z $epi ]]
		then 
		echo no niftis in $i\!
	elif [[ ! -z $unwarp ]]
		then
		echo B0 field already generated \in $i
		echo delete before proceeding
	else
		dwell=$(echo $(dicom_hdr $i/dicoms/$(ls $i/dicoms/ | 
			head -n 1) | 
			grep 0043\ 102c | 
			awk 'BEGIN{ FS="//" }; { print $3 }') /1000000 | 
			bc -l) 

		fmap=$(ls $i/../B0/fieldmap_rads.nii.gz)

		fugue -i $epi --dwell=$dwell \
		--loadfmap=$fmap \
		-u $(dirname $epi)/$(basename $epi .nii.gz)_unwarp.nii.gz
	fi
done
```
### Get partially saturated first volume from every 4D epi volume as reference image
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/{REST,RUN_?}/*unwarp.nii.gz
do
	if [ ! -e $(dirname $i)/example_func.nii.gz ]
		then
		fslroi $i $(dirname $i)/example_func.nii.gz 0 1
		bet $(dirname $i)/example_func.nii.gz $(dirname $i)/example_func.nii.gz 
	else
		echo example_func.nii.gz already exists in $(dirname $i)
	fi
done
```

###Run preprocessing (need to generate template .fsf file first)
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/{REST,RUN_?}/*unwarp.nii.gz
do
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/run_preproc.sh $i \
	/data/engine/abuch/NETPD/reversal_learning_pd/analysis/preproc_5mm_5del_100s_mc.fsf \
	$(dirname $i)/../T1/bravo.anat/T1_biascorr_brain.nii.gz
done
```
###Generate confounds and run extended preprocessing
For now, need a bunch of code from github.com/rgerraty/rl_flexibility for this to work
```{.bash}
for i in /data/engine/abuch/NETPD/*/*/{REST,RUN_?}/preproc_5mm_5del_100s_mc.feat/filtered_func_data.nii.gz; 
do
	subdir=$(dirname $i);
	if [ -e $subdir/36par+spikes.txt ]
		then
		echo confound regressors already generated in $subdir
		echo delete before continuing if you want to regenerate
	else
		#need fsl_extract_confoundts.sh and make_spike_regs.m from github.com/rgerraty/rl_flexibility
		/home/rgerraty/GitHub/rl_flexibility/fsl_extract_confts.sh $subdir $subdir/../../T1/bravo.anat 3;
	fi

	if [ -e $subdir/36par+spikes.feat/stats/res4d.nii.gz ]
		then
		echo confound regression already run for $subdir
		echo delete to run again
	elif [ -d $subdir/36par+spikes.feat/ ]
		then 
		echo $subdir/36par+spikes.feat run but did not finish\!
		echo something went wrong
	else
		#need 1st_level_conf.sh and conf_reg_design.fsf from github.com/rgerraty/rl_flexibility
		/home/rgerraty/GitHub/rl_flexibility/1st_level_conf.sh $i $subdir/36par+spikes.txt; 
	fi
done
```