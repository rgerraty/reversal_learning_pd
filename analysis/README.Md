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


#after manual inspection re-extract brains with lower
#fractional intensity in cases with too much non-brain
for i in {812/sess_1,812/sess_2}
do
  cd /data/engoine/abuch/NETPD/$i;
  bet T1/bravo.anat/T1_biascorr.nii.gz T1/bravo.anat/T1_biascorr_brain -R -f .3
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
	bash /home/rgerraty/GitHub/reversal_learning_pd/analysis/run_preproc.sh $i \
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


###Combine ROI timecourses accross runs
```{.bash}
for i in /data/engine/abuch/NETPD/8??
  do
  for j in $i/sess_?;
    do 
    touch $j/all_rois_all_runs.txt
    touch $j/missing_runs.txt
    for k in $j/RUN_*
      do 
      if [ -e $k/preproc_5mm_5del_100s_mc.feat/36par+spikes.feat/H-O_rois/all_rois.txt ]
        then 
        cat $k/preproc_5mm_5del_100s_mc.feat/36par+spikes.feat/H-O_rois/all_rois.txt>>$j/all_rois_all_runs.txt
      else
        echo no ROI data for $k
        echo $k | cut -d_ -f3 >> $j/missing_runs.txt
      fi
    done
  done
done
```

###Multiplication of temporal derivatives for time-resolved connectivity and multislice community detection
Taken from Shine et al. 2015 (http://dx.doi.org/10.1016/j.neuroimage.2015.07.064)

```{.matlab}
addpath ~/scripts/MATLAB/  
addpath ~/scripts/MATLAB/GenLouvain_for_Raphael/
addpath ~/scripts/MATLAB/Bassett_Code
addpath ~/scripts/MATLAB/2013_12_25' BCT'/

[a,b]=system('ls -d /data/engine/abuch/NETPD/8*/sess_?/all_rois_all_runs.txt');
tsslist=strread(b,'%s');

for i=1:size(tsslist,1)
    tsslist(i)
    learnfile=char(tsslist(i));
    base=tsslist{i}(1:end-21);
    if exist(strcat(base,'mtd_commdet.mat'),'file')==0
      tss=dlmread(learnfile);
      if ~isempty(find(sum(tss==0)==size(tss,1)))
        empty_rois=find(sum(tss==0)==size(tss,1)) 
        tss(:,empty_rois)=[];
      end
      a=coupling(tss,13);
      a_mean=mean(a,3);
      a_z=weight_conversion(a_mean,'normalize');
      [m n t]=size(a);
      conn_cell=mat2cell(a,m,n,[ones(1,t)]);
      [c,Q]=multiord_res_norm(conn_cell,1,1);
    
      save(char(strcat(base,'mtd_commdet.mat')));
    else 
      sprintf('MTD already completed for:\n%s',base)
    end

end
end
```

###Compute flexibility statistics for each time bin
####Load in data and libraries
```{.matlab}
addpath ~/scripts/MATLAB/Bassett_Code
str_ind=[49,51,54,104,106,109];
wb_ind=1:110;
blocks=5;
block_lengths=[278 264 264 263 311]';
medsfull=dlmread('/data/engine/abuch/NETPD/medlist.txt');
meds=~medsfull(:,3)+1;
bins=10;
subs=unique(medsfull(:,1));
```
####Compute flexibility for ON and OFF states at each time bin
```{.matlab}
medind=1
for s=1:size(subs,1)
  sub=subs(s)
  cd(strcat('/data/engine/abuch/NETPD/',num2str(sub)))
  load('sess_1/mtd_commdet.mat')
  missing=textread('sess_1/missing_runs.txt');  

  n=1;
  if exist('empty_rois')
    for e=1:length(empty_rois)
      c=[c(1:empty_rois(e)-1,:);repmat(NaN,1,size(c,2));c(empty_rois(e):end,:)];
    end
    clear empty_rois
  end
  for b=1:blocks
    k=(bins/blocks*b)-((bins/blocks)-1):(bins/blocks*b);
    if any(b==missing)
      flex(:,k,s,meds(medind))=NaN;
    else
      for i=k(1):k(end)
        flex(:,i,s,meds(medind))=flexibility(c(:,n:n+floor(block_lengths(b)/(bins/blocks))-1)');
        n=n+floor(block_lengths(b)/(bins/blocks))
      end
    end
  end

  load('sess_2/mtd_commdet.mat')
  missing=textread('sess_2/missing_runs.txt');  
  medind=medind+1
  n=1;
  if exist('empty_rois')
    for e=1:length(empty_rois)
      c=[c(1:empty_rois(e)-1,:);repmat(NaN,1,size(c,2));c(empty_rois(e):end,:)];
    end
    clear empty_rois
  end
  for b=1:blocks
    k=(bins/blocks*b)-((bins/blocks)-1):(bins/blocks*b);
    if any(b==missing)
      flex(:,k,s,meds(medind))=NaN;
    else
      for i=k(1):k(end)
        flex(:,i,s,meds(medind))=flexibility(c(:,n:n+floor(block_lengths(b)/(bins/blocks))-1)');
        n=n+floor(block_lengths(b)/(bins/blocks))
      end
    end
  end
  medind=medind+1
end
```

####Write out in long form csv for analyzing in R
```{.matlab}
%change any rois with flexibilty of 1 to NaN
%1 results from missing data

flex(sub2ind(size(flex),find(flex==1)))=NaN  
dim=size(flex)
h=1
for i=1:dim(4)
    for j=1:dim(3)
        for k=1:dim(2)
            for l=1:dim(1)
                flex_mat(h,1)=flex(l,k,j,i);
                flex_mat(h,2)=k;
                flex_mat(h,3)=j;
                flex_mat(h,4)=~(i-1);
                flex_mat(h,6)=l;
                flex_mat(h,7)=flex(l,k,j,i)-(flex(l,1,j,i));
                h=h+1;
            end
        end
    end
end
flex_mat(:,5)=~flex_mat(:,4);

dlmwrite('/data/engine/abuch/NETPD/flexmat_long.csv',flex_mat)
```

###Multilevel models of flexibility in R
For now these are ML estimates, will eventually run fully bayesian models

####Load data and libraries
```{.R}
#R code 
library(lme4)
library(doBy)
library(ggplot2)
library(reshape2)

flexdat<-read.csv('/data/engine/abuch/NETPD/flexmat_long.csv',header=F)
names(flexdat)<-c("flex","bin","sub","on","off","ROI","flex_debase")
str_ind<-c(49,51,54,104,106,109);
```


####Fit ML approximations
```{.R}
#whole-brain (contains all ROIs varying randomly by average flexibility)
#estimate on and off effects separately
m1<-lmer(flex~0+on+off+(0+on+off|sub)+(0+on+off|bin)+(0+on+off|ROI),data=flexdat)
#estimate med difference
m1_diff<-lmer(flex~I(on-off)+(I(on-off)|sub)+(I(on-off)|bin)+(I(on-off)|ROI),data=flexdat)


#striatum (contains striatal ROIs varying randomly by average flexibility)
m1_str<-lmer(flex~0+on+off+(0+on+off|sub)+(0+on+off|bin)+(0+on+off|ROI),data=flexdat,
    subset=ROI%in%str_ind)
#estimate med difference
m1_str_diff<-lmer(flex~I(on-off)+(I(on-off)|sub)+(I(on-off)|bin)+(I(on-off)|ROI),data=flexdat,
    subset=ROI%in%str_ind)


#same as above (striatum), but for baseline subtracted flexibility
m1_str_debase<-lmer(flex_debase~0+on+off+(0+on+off|sub)+(0+on+off|bin)+(0+on+off|ROI),data=flexdat,
    subset=ROI%in%str_ind & bin>1)
m1_str_diff_debase<-lmer(flex_debase~I(on-off)+(I(on-off)|sub)+(I(on-off)|bin)+(I(on-off)|ROI),data=flexdat,
    subset=ROI%in%str_ind & bin>1)

#whole-brain baseline subtracted
m1_debase<-lmer(flex_debase~0+on+off+(0+on+off|sub)+(0+on+off|bin)+(0+on+off|ROI),data=flexdat, subset=bin>1)
m1_diff_debase<-lmer(flex_debase~I(on-off)+(I(on-off)|sub)+(I(on-off)|bin)+(I(on-off)|ROI),data=flexdat,subset=bin>1)
```

####Bootstrap uncertainty for varying estimates ("random" effects)
```{.R}
#Bootstrap ON estimates for each time Bin
myfun<-function(.){
coef(.)$bin$on 
}
#whole-brain
boot_on<-bootMer(m1,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum
boot_on_str<-bootMer(m1_str,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum baseline-subtracted
boot_on_str_debase<-bootMer(m1_str_debase,myfun,use.u=TRUE,type="parametric",nsim=100)

#Bootstrap OFF estimates for each time Bin
myfun<-function(.){
coef(.)$bin$off 
}
#whole-brain
boot_off<-bootMer(m1,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum
boot_off_str<-bootMer(m1_str,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum baseline-subtracted
boot_off_str_debase<-bootMer(m1_str_debase,myfun,use.u=TRUE,type="parametric",nsim=100)

#Bootstrap mean estimate for each time bin
myfun<-function(.){
coef(.)$bin$"(Intercept)"
}
#whole-brain
boot_mean<-bootMer(m1_diff,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum
boot_mean_str<-bootMer(m1_str_diff,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum baseline-subtracted
boot_mean_str_debase<-bootMer(m1_str_diff_debase,myfun,use.u=TRUE,type="parametric",nsim=100)

#Bootstrap medication effect estimates for each time bin
myfun<-function(.){
coef(.)$bin$"I(on - off)"
}
#whole-brain
boot_onvoff<-bootMer(m1_diff,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum
boot_onvoff_str<-bootMer(m1_str_diff,myfun,use.u=TRUE,type="parametric",nsim=100)
#striatum baseline-subtracted
boot_onvoff_str_debase<-bootMer(m1_str_diff_debase,myfun,use.u=TRUE,type="parametric",nsim=100)

#Bootstrap medication effect estimates for each ROI
#estimate med difference
m1_diff_debase<-lmer(flex_debase~I(on-off)+(I(on-off)|sub)+(I(on-off)|bin)+(I(on-off)|ROI),data=flexdat)
myfun<-function(.){
coef(.)$ROI$"I(on - off)"
}
boot_onvoff_debase_ROIs<-bootMer(m1_diff_debase,myfun,use.u=TRUE,type="parametric",nsim=100)
```

####Save and write out results
```{.R}
#save workspace
save.image(file="/data/engine/abuch/NETPD/flex_boots.RData")

#write out ROI files for brain map
roi_inds<-which((apply(boot_onvoff_debase_ROIs$t>0,2,sum)/100)>=.99)
roi_coeffs<-coef(m1_diff_debase)$ROI[,2]
write(roi_inds,"/data/engine/abuch/NETPD/whole_brain/flex_med_roi_inds.txt",ncolumns=1)
write(roi_coeffs,"/data/engine/abuch/NETPD/whole_brain/flex_med_roi_coefs.txt",ncolumns=1)
```

###Plot flexibility over time

####Libraries and functions for plots
```{.R}
library(ggplot2)
library(gridExtra)
library(reshape2)

stat_sum_single <- function(fun, geom="point",color="black", ...) {
  stat_summary(fun.y=fun, colour=color, geom=geom, size = 2, ...)
}

hi_ci<-function(.){
  quantile(x=.,.84)
}
lo_ci<-function(.){
  quantile(x=.,.16)
}
load(file="/data/engine/abuch/NETPD/flex_boots.RData")
```

####Plot mean flexibility 
```{.R}
#(delete _str from next line for whole-brain)
mean_re<-melt(boot_mean_str$t)
names(mean_re)<-c(" ","LearnignBlock","Flexibility")
ggplot(mean_re,aes(x=LearnignBlock,y=Flexibility))+
  stat_summary(fun.ymin=lo_ci,fun.ymax=hi_ci,geom="ribbon",
               position=position_dodge(.4),color = NA, size=.5,fill="darkorchid4",alpha=.5)  +
  theme_classic()+
  stat_sum_single(mean,geom="line")+
  theme(legend.position="none",
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 18),
        axis.line.x = element_line(colour = 'black', size=0.5, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.5, linetype='solid'))+
  xlab("Learning Block")+
  ylab("Striatum Flexibility")+#ylim(c(0.18,0.2))+
  scale_x_continuous(expand=c(0,0),breaks=seq(2,10,2),labels=seq(2,10,2))
```
####Plot flexibility ON and OFF L-Dopa
```{.R}
#ON
#(delete _str from next line for whole-brain)
on_re<-melt(boot_on_str$t)
names(on_re)<-c(" ","LearningBlock","Flexibility")

#uncomment to subtract baseline
#on_re$Flexibility<-(on_re$Flexibility-
    rep(on_re$Flexibility[on_re$LearningBlock==1],times=length(unique(on_re$LearningBlock))))


g1<-ggplot(on_re,aes(x=LearningBlock,y=Flexibility))+
  stat_summary(fun.ymin=lo_ci,fun.ymax=hi_ci,geom="ribbon",
               position=position_dodge(0),color = NA, size=.5,
               fill="darkturquoise",alpha=.5)  +
  theme_classic()+
  stat_sum_single(mean,geom="line")+
  theme(legend.position="none",
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 18),
        axis.line.x = element_line(colour = 'black', size=0.5, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.5, linetype='solid'))+
  xlab("Learning Block")+
  ylab("Striatum Flexibility")+ylim(c(0,.025))+xlim(2,10)+ ggtitle("On L-Dopa")+
  scale_x_continuous(expand=c(0,.2),breaks=seq(2,10,2),labels=seq(2,10,2))


#OFF
#(delete _str from next line for whole-brain)
off_re<-melt(boot_off_str$t)
names(off_re)<-c(" ","LearningBlock","Flexibility")

#uncomment to subtract baseline
#off_re$Flexibility<-off_re$Flexibility-
    rep(off_re$Flexibility[off_re$LearningBlock==1],times=length(unique(off_re$LearningBlock)))

g2<-ggplot(off_re,aes(x=LearningBlock,y=Flexibility))+
  stat_summary(fun.ymin=lo_ci,fun.ymax=hi_ci,geom="ribbon",
               position=position_dodge(0),color = NA, size=.5,fill="red",alpha=.5)  +
  theme_classic()+
  stat_sum_single(mean,geom="line")+
  theme(legend.position="none",
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 18),
        axis.line.x = element_line(colour = 'black', size=0.5, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.5, linetype='solid'))+
  xlab("Learning Block")+
  ylab("Striatum Flexibility")+ylim(c(0,.025))+xlim(2,10)+  ggtitle("Off L-Dopa")+
  scale_x_continuous(expand=c(0,.2),breaks=seq(2,10,2),labels=seq(2,10,2))

grid.arrange( g2, g1, ncol=2)
```

####Plot baseline-subtracted flexibility ON and OFF L-Dopa
```{.R}
#ON
#(delete _str from next line for whole-brain)
on_re<-melt(boot_on_str_debase$t)
names(on_re)<-c(" ","LearningBlock","Flexibility")
on_re$Flexibility<-(on_re$Flexibility-
    rep(on_re$Flexibility[on_re$LearningBlock==1],times=length(unique(on_re$LearningBlock))))


g1<-ggplot(on_re,aes(x=LearningBlock,y=Flexibility))+
  stat_summary(fun.ymin=lo_ci,fun.ymax=hi_ci,geom="ribbon",
               position=position_dodge(0),color = NA, size=.5,
               fill="darkturquoise",alpha=.5)  +
  theme_classic()+
  stat_sum_single(mean,geom="line")+
  theme(legend.position="none",
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 18),
        axis.line.x = element_line(colour = 'black', size=0.5, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.5, linetype='solid'))+
  xlab("Learning Block")+
  ylab("Striatum Flexibility")+ylim(c(0,.025))+xlim(2,10)+ ggtitle("On L-Dopa")+
  scale_x_continuous(expand=c(0,.2),breaks=seq(2,10,2),labels=seq(2,10,2))


#OFF
#(delete _str from next line for whole-brain)
off_re<-melt(boot_off_str_debase$t)
names(off_re)<-c(" ","LearningBlock","Flexibility")
off_re$Flexibility<-off_re$Flexibility-
    rep(off_re$Flexibility[off_re$LearningBlock==1],times=length(unique(off_re$LearningBlock)))

g2<-ggplot(off_re,aes(x=LearningBlock,y=Flexibility))+
  stat_summary(fun.ymin=lo_ci,fun.ymax=hi_ci,geom="ribbon",
               position=position_dodge(0),color = NA, size=.5,fill="red",alpha=.5)  +
  theme_classic()+
  stat_sum_single(mean,geom="line")+
  theme(legend.position="none",
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 18),
        axis.line.x = element_line(colour = 'black', size=0.5, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.5, linetype='solid'))+
  xlab("Learning Block")+
  ylab("Striatum Flexibility")+ylim(c(0,.025))+xlim(2,10)+  ggtitle("Off L-Dopa")+
  scale_x_continuous(expand=c(0,.2),breaks=seq(2,10,2),labels=seq(2,10,2))

grid.arrange( g2, g1, ncol=2)
```