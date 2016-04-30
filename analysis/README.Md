#Analysis Code for Network Dynamics and Dopamine in Parkinson's Disease
##Raphael Gerraty, Madeleine Sharp, Amanda Buch 2016

Descriptions and example scripts for running network preprocessing and analysis functions contained in this repository. 


### Set up directory structure
```{.bash}
for i in /data/engine/abuch/NETPD/unzipped/*/scans/*T2*/resources/DICOM/files/
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
Coming Soon