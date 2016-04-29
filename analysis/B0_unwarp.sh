dir_name=$(dirname $(readlink -f $1))
file_name=$(basename $1)

echo converting to complex image from $1

cd $dir_name
fslcomplex -complexsplit $file_name complex_acq

fslcomplex -realabs complex_acq fieldmap_mag

echo generating phase images
fslcomplex -realphase complex_acq phase0_rad 0 1

fslcomplex -realphase complex_acq phase1_rad 1 1

echo unwrapping phase images
prelude -a fieldmap_mag -p phase0_rad -o phase0_unwrapped_rad

prelude -a fieldmap_mag -p phase1_rad -o phase1_unwrapped_rad

echo generating field map
fslmaths phase1_unwrapped_rad -sub phase0_unwrapped_rad -mul 1000 -div 2.65 fieldmap_rads -odt float 

fugue --loadfmap=fieldmap_rads -s 1 --savefmap=fieldmap_rads
fugue --loadfmap=fieldmap_rads --despike --savefmap=fieldmap_rads
fugue --loadfmap=fieldmap_rads -m --savefmap=fieldmap_rads