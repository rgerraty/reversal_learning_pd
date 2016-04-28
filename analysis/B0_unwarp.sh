B0_unwarp.sh $1

dir_name=$(dirname $(readlink -f $1))

fslcomplex -complexsplit $1 complex_acq

fslcomplex -realabs complex_acq fieldmap_mag

fslcomplex -realphase complex_acq phase0_rad 0 1

fslcomplex -realphase complex_acq phase1_rad 1 1

prelude -a fieldmap_mag -p phase0_rad -o phase0_unwrapped_rad

prelude -a fieldmap_mag -p phase1_rad -o phase1_unwrapped_rad

fslmaths phase1_unwrapped_rad -sub phase0_unwrapped_rad -mul 1000 -div 2.65 fieldmap_rads -odt float 

fugue --loadfmap=fieldmap_rads -s 1 --savefmap=fieldmap_rads
fugue --loadfmap=fieldmap_rads --despike --savefmap=fieldmap_rads
fugue --loadfmap=fieldmap_rads -m --savefmap=fieldmap_rads