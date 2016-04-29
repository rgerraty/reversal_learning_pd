dir_name=$(dirname $(readlink -f $1))
file_name=$(basename $1)

if [ -e $dir_name/fieldmap_rads.nii.gz ]
	then
	echo field map files already exist for $1
	echo please check directory and delete files before continuing

else
	#note this will only work for very specific B0 images already in phase/magnitide 
	echo splitting $1 into phase and magnitude images
	fslsplit $1 $dir_name/vol
	mv $dir_name/vol0000.nii.gz $dir_name/fieldmap_rads.nii.gz
	mv $dir_name/vol0001.nii.gz $dir_name/fieldmap_mag.nii.gz

	echo regularizing field map
	fugue --loadfmap=$dir_name/fieldmap_rads -s 2 --savefmap=$dir_name/fieldmap_rads
	fugue --loadfmap=$dir_name/fieldmap_rads --despike --savefmap=$dir_name/fieldmap_rads
	fugue --loadfmap=$dir_name/fieldmap_rads -m --savefmap=$dir_name/fieldmap_rads
fi