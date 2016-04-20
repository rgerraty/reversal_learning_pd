if [ -z $2 ];
	then
	echo script for creating sensible directories from XNAT output
	echo usage:
	echo move_dicoms.sh \<input\> \<session\>
	echo \<input\>	directory containing dicom files to be moved
	echo \<output\>	output directory
	echo \<session\>	session id \for multisession studies
	echo e\.g\.
	echo move_dicoms.sh DICOM/files/ /data/engine/abuch/NETPD/ 1

else
	#set dicom directory
	dicom_dir=$(readlink -f $1)

	output=$2

	#set session ID
	if [ -z $3 ];
		then 
		sess_id=1
	else
		sess_id=$3
	fi

	#set sequence ID from dicom header for name of directory
	seq_id=$(dicom_hdr $(ls $dicom_dir | head -n 1)  | grep Series\ Description| awk 'BEGIN { FS = "//" } { print $3 }')

	#set subject ID from dicom header
	sub_id=$(dicom_hdr $(ls $dicom_dir | head -n 1)  | grep Patient\ Name | awk 'BEGIN { FS = "//" } { print $3 }')


	if [ -d $output/$sub_id/sess_$sess_id/$seq_id ]
			then 
			echo $output/$sub_id/sess_$sess_id/$seq_id already exists\!
			echo please check directory and delete before continuing
		else 
			if [ ! -d $output ]
				then
				mkdir $output
			elif [ ! -d $output/sess_$sess_id ]; 
				then
				mkdir $output/sess_$sess_id
			fi
		mkdir -p $output/sess_$sess_id/$seq_id/dicoms
		cp $dicom_dir/*dcm $output/sess_$sess_id/$seq_id/dicoms
	fi
fi