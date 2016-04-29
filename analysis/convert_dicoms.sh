dicom_dir=$(readlink -f $1)

if [[ -z $(ls $dicom_dir/*dcm) ]];
	then 
	echo no dcm files in $1
elif [[ -z $dicom_dir/../nifti/*nii.gz ]]
	then
	echo nifti files already exist for $1
	echo please check directory and delete nifti before continuing
else 
	cd $dicom_dir
	echo converting dicoms in $dicom_dir
	dcm2nii *
	mkdir -p ../nifti/
	mv *nii.gz ../nifti/
	for i in ../nifti/*nii.gz;
	do
		fslreorient2std $i;
	done
fi
