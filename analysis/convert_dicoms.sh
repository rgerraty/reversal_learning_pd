dicom_dir=$(readlink -f $1)
niftis=$(ls $dicom_dir/../*nii.gz 2>/dev/null)

if [[ -z $(ls $dicom_dir/*dcm) ]];
	then 
	echo no dcm files in $1
elif [[ ! -z $niftis ]]
	then
	echo nifti files already exist for $1
	echo please check directory and delete nifti before continuing
else 
	echo converting dicoms in $dicom_dir
	dcm2nii $dicom_dir/*
	mv $dicom_dir/*nii.gz $dicom_dir/..
	for i in $dicom_dir/../*nii.gz;
	do
		fslreorient2std $i $i;
	done
fi
