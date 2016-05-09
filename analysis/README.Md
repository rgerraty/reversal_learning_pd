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
for i in /data/engine/abuch/NETPD/*/sess_?/{B0,T*}/dicoms/
do
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/convert_dicoms.sh $i
done
```

### Generate field map for B0 correction
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/B0;  
do 
	bo=$(ls $i/2*nii.gz);
	echo $bo; 
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/B0_unwarp.sh $bo; 
done
```

### Run anatomical preprocessing
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/T1/;
do 
	if [ -d $i/bravo.anat ]
		then
		echo fsl_anat already run for $i
	else
		if [ ! -e $i/bravo.nii.gz ]
			then
			bravo=$(ls $i/co*nii.gz | head -n1)
			mv $bravo $i/bravo.nii.gz
		fi
		fsl_anat -i $i/bravo.nii.gz
	fi
done
```

### B0 field correction for EPI scans
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}/*unwarp.nii.gz
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}/*unwarp.nii.gz
do
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/run_preproc.sh $i \
	/data/engine/abuch/NETPD/reversal_learning_pd/analysis/preproc_5mm_5del_100s_mc.fsf \
	$(dirname $i)/../T1/bravo.anat/T1_biascorr_brain.nii.gz
done
```
###Generate confounds and run extended preprocessing
For now, need a bunch of code from github.com/rgerraty/rl_flexibility for this to work
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}/preproc_5mm_5del_100s_mc.feat/filtered_func_data.nii.gz; 
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

###Apply non-linear registration
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}/preproc*feat
 do 
 	if [ -e $i/36par+spikes.feat/stats/res4d_std.nii.gz ];
 		then
     	echo warping already completed for $i
     else
     	echo warping $i;
    	#apply warp from FNIRT to preprocessed 4D data
    	applywarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz\
    	--in=$i/36par+spikes.feat/stats/res4d.nii.gz\
    	--out=$i/36par+spikes.feat/stats/res4d_std.nii.gz\
    	--warp=$i/../../T1/bravo.anat/T1_to_MNI_nonlin_field.nii.gz\
    	--premat=$i/reg/example_func2highres.mat;  
    fi
done

```


###Extract ROI Timecourses
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN_?}/preproc*/36*feat
	do 
	#extract timeseries (mean or 1st eigenvector, see function) data from each ROI in ~/Harvard-Oxford_ROIs/ 
	echo exracting ROIs from $i
    /home/rgerraty/GitHub/rl_flexibility/extract_ROIs.sh $i/stats/res4d_std.nii.gz\
    	/home/rgerraty/Harvard-Oxford_ROIs/\
    	$i/H-O_rois/;
done
```

###Calculate coherence matrices for each time window
``` {.matlab}
addpath /home/rgerraty/GitHub/rl_flexibility
%read in all subject/run ROI timeseries directories 
[a,b]=system('ls -d /data/engine/abuch/NETPD/8*/sess_?/{REST,RUN_?}/preproc_5mm_5del_100s_mc.feat/36par+spikes.feat/H-O_rois');
c=strread(b,'%s');

for i=1:size(c,1)
	if exist(char(strcat(c(i),'/all_rois.txt')))==0
		'no ROI file'
	elseif exist(char(strcat(c(i),'/conn_cells_40TR_06-5.mat')))==2
    	'already done'
    else
    	%calculate coherence per time window from concatenated ROI file
    	filename=char(strcat(c(i),'/all_rois.txt'))
    	%need to specify filename, window length in TR, sampling rate, bandpass
    	%detect cycles as slow as 3s and as fast as ~nyqhuist 
    	conn_cell=coherence_by_block(filename,40,1.177,.06,.5);
    	save(char(strcat(c(i),'/conn_cells_40TR_06-5')),'conn_cell')
    
    end
end
```

### Grid search for optimizing multi-layer community detection parameters
```{.matlab}
addpath /home/rgerraty/GitHub/rl_flexibility/
addpath /home/rgerraty/scripts/MATLAB/GenLouvain_for_Raphael/
addpath /home/rgerraty/scripts/MATLAB/Bassett_Code/


[a,b]=system('ls -d /data/engine/abuch/NETPD/8*/sess_?/RUN_?/preproc_5mm_5del_100s_mc.feat/36par+spikes.feat/H-O_rois');
c=strread(b,'%s')

res_pars=10.^[-4:.5:.5];
gamma_pars=10.^[-4:.5:.5];

numruns=1
k=1;
for j=1:size(c,1)/numruns
    c(k)
    conn_cell_cat=[];
    for i=1:numruns 
        load(strcat(char(c(k-1+i)),'/conn_cells_40TR_06-5'))
        conn_cell_cat=cat(3,conn_cell_cat,conn_cell);
    end
    [q,q_tmp]=Q_grid(conn_cell_cat,10,res_pars,gamma_pars);
    save(char(strcat(c(k),'/../../../../q_learning')),'q');
    save(char(strcat(c(k),'/../../../../q_tmp_learning')),'q_tmp');
    k=k+numruns;
end

```

### Run multi-slice community detection and flexibility statistics

Input coherence matrix for each block. Also need number of blocks,
resolution and coupling parameters. In Matlab

``` {.matlab}
%need multi-slice, flexibility codes not yet on GitHub for network_diags to run 
addpath /home/rgerraty/GitHub/rl_flexibility/
addpath /home/rgerraty/scripts/MATLAB/GenLouvain_for_Raphael/
addpath /home/rgerraty/scripts/MATLAB/Bassett_Code/

%read in data
[a,b]=system('ls -d /data/engine/abuch/NETPD/8*/sess_?/RUN_?/preproc_5mm_5del_100s_mc.feat/36par+spikes.feat/H-O_rois');
c=strread(b,'%s');

%concatenate runs for each subject
numruns=5
k=1;
for j=1:size(c,1)/numruns
    c(k)
    conn_cell_cat=[];
    for i=1:numruns 
        load(strcat(char(c(k-1+i)),'/conn_cells_40TR_06-5'))
        conn_cell_cat=cat(3,conn_cell_cat,conn_cell)
    end

    %network_diags code:
    %runs multi-slice community detection
    %gives flexibility for each run
    %also allegiance matrix (not using yet)
    %need to specify number of blocks, simulations, coupling, resolution
    [a_mat,flex]=network_diags(conn_cell_cat,8,500,3.1623,.0001);
    save(char(strcat(c(k),'/../../../../a_mat_learning')),'a_mat');
    save(char(strcat(c(k),'/../../../../flex_learning')),'flex');
    k=k+numruns;
end
```

### Get Flexibility Statistics for Resting State and Task 
```{.matlab}
clear flex_rest flex_learning
[a,b]=system('ls -d /data/engine/abuch/NETPD/8*/');
c=strread(b,'%s');
for i=1:length(c)
	for j=1:2
		load(char(strcat(c(i),'sess_',num2str(j),'/flex_rest.mat')))
		flex_rest(:,j,i)=flex;
		load(char(strcat(c(i),'sess_',num2str(j),'/flex_learning.mat')))
		flex_learning(:,:,j,i)=flex;
	end
end
```
