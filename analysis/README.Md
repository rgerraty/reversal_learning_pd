#Analysis Code for Network Dynamics and Dopamine in Parkinson's Disease
##Raphael Gerraty, Madeleine Sharp, Amanda Buch 2016

Descriptions and example scripts for running network preprocessing and analysis functions contained in this repository. 

### Grab files from XNat Server
```{.bash}

# Xnatgrab_func.sh [user] [password] [project] [subject] [subject]

user= # enter username for XNat Server
pw= # enter password for XNat Server
project= # enter project directory for XNat Server
subjs=(801 802 803)
sess1=(12816 12951 13000)
sess2=(12822 12956 13008)

last=${#subjs[@]}

for ((i=0; i <= last-1; i++))
do
	/home/rgerraty/GitHub/reversal_learning_pd/analysis/Xnatgrab_func.sh $user $pw $project ${subjs[$i]} ${sess1[$i]}
	/home/rgerraty/GitHub/reversal_learning_pd/analysis/Xnatgrab_func.sh $user $pw $project ${subjs[$i]} ${sess2[$i]}
done
```
### Set up directory structure
```{.bash}
#make sure only IDs corresponding to correct session are included in this loop
for i in /data/engine/abuch/NETPD/unzipped_tmp/<sess_2 ids>/scans/*/resources/DICOM/files/
do
	#indicate whether session 1 or 2 since this is not contained in dicom header
	bash /home/rgerraty/GitHub/reversal_learning_pd/analysis/move_dicoms.sh $i /data/engine/abuch/NETPD/ 2
done
```

### Convert dicoms to niftis and reorient
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{B0,T*}/dicoms/
do
	bash /home/rgerraty/GitHub/reversal_learning_pd/analysis/convert_dicoms.sh $i
done
```

### Generate field map for B0 correction
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/B0;  
do 
	bo=$(ls $i/2*nii.gz);
	echo $bo; 
	bash /home/rgerraty/GitHub/reversal_learning_pd/analysis/B0_unwarp.sh $bo; 
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST*,RUN*}
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST*,RUN*}/*unwarp.nii.gz
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST*,RUN*}/*unwarp.nii.gz
do
	bash /data/engine/abuch/NETPD/reversal_learning_pd/analysis/run_preproc.sh $i \
	/home/rgerraty/GitHub/reversal_learning_pd/analysis/preproc_5mm_5del_100s_mc.fsf \
	$(dirname $i)/../T1/bravo.anat/T1_biascorr_brain.nii.gz
done
```
###Generate confounds and run extended preprocessing
For now, need a bunch of code from github.com/rgerraty/rl_flexibility for this to work
```{.bash}
for i in /data/engine/abuch/NETPD/*/sess_?/{REST,RUN*}/preproc_5mm_5del_100s_mc.feat/filtered_func_data.nii.gz; 
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST*,RUN*}/preproc*feat
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
for i in /data/engine/abuch/NETPD/*/sess_?/{REST*,RUN*}/preproc*/36*feat
	do 
	#extract timeseries (mean or 1st eigenvector, see function) data from each ROI in ~/Harvard-Oxford_ROIs/ 
	echo exracting ROIs from $i
    /home/rgerraty/GitHub/rl_flexibility/extract_ROIs.sh $i/stats/res4d_std.nii.gz\
    	/home/rgerraty/Harvard-Oxford_ROIs/\
    	$i/H-O_rois/;
done
```

###Multiplication of temporal derivatives for time-resolved connectivity and multislice community detection
Taken from Shine et al. 2015 (http://dx.doi.org/10.1016/j.neuroimage.2015.07.064)

```{.matlab}
addpath ~/scripts/MATLAB/  
addpath ~/scripts/MATLAB/GenLouvain_for_Raphael/
addpath ~/scripts/MATLAB/Bassett_Code
addpath ~/scripts/MATLAB/2013_12_25' BCT'/

base='/data/engine/abuch/NETPD/8'
for i=1:23
for j=1:2
    learnfile=char(strcat(base,sprintf('%02d',i),'/sess_',num2str(j),'/all_rois_all_runs.txt'));
    tss=dlmread(learnfile);
    a=coupling(tss,13);
    a_mean=mean(a,3);
    a_z=weight_conversion(a_mean,'normalize');
    [m n t]=size(a);
    conn_cell=mat2cell(a,m,n,[ones(1,t)]);
    [c,Q]=multiord_res_norm(conn_cell,1,1);
    save(char(strcat(base,sprintf('%02d',i),'/sess_',num2str(j),'/mtd_commdet.mat')));
end
end
```

###Compute flexibility statistics for each time bin
```{.matlab}
addpath ~/scripts/MATLAB/Bassett_Code
str_ind=[49,51,54,104,106,109];
wb_ind=1:110;
meds=~dlmread('/data/engine/abuch/NETPD/meds.txt')+1
wins=10
subs=801:823

medind=1
s=1
for sub=subs
    cd(strcat('/data/engine/abuch/NETPD/',num2str(sub)))
    load('sess_1/mtd_commdet.mat')
    k=1;
    for i=1:t
        flex(:,k,s,meds(medind))=flexibility(c(:,i:floor((t)/wins)*k)');
        k=k+1;
        if k<(wins+1)
            i=i+floor((t)/wins);
            else
            break
        end
    end
    load('sess_2/mtd_commdet.mat')
    medind=medind+1
    k=1;
    for i=1:t
        flex(:,k,s,meds(medind))=flexibility(c(:,i:floor((t)/wins)*k)');
        k=k+1;
        if k<(wins+1)
            i=i+floor((t)/wins);
        else
            break
        end
    end
    medind=medind+1
    s=s+1
end

%%write out
%%longform csv for R
dim=size(flex)
h=1
for i=1:dim(4)
    for j=1:dim(3)
        for k=1:dim(2)
            for l=1:dim(1)
                flex_mat(h,1)=flex(l,k,j,i);
                flex_mat(h,2)=BT_bin(l,k,j,i);
                flex_mat(h,3)=WT_bin(l,k,j,i);
                flex_mat(h,4)=k;
                flex_mat(h,5)=j;
                flex_mat(h,6)=~(i-1);
                flex_mat(h,8)=l;
                flex_mat(h,9)=flex(l,k,j,i)-(flex(l,1,j,i));
                h=h+1;
            end
        end
    end
end
flex_mat(:,7)=~flex_mat(:,6);

dlmwrite('/data/engine/abuch/NETPD/flexmat_long.csv',flex_mat)
```



