#!/bin/bash

if [ -z $2 ];
	then
	echo script \for creating sensible directories from XNAT output
	echo usage:
	echo move_dicoms.sh \<input\> \<output\> \<session\>
	echo \<input\>	directory containing dicom files to be moved
	echo \<output\>	output directory
	echo \<session\>	session id \for multisession studies
	echo e\.g\.
	echo move_dicoms.sh DICOM/files/ /data/engine/abuch/NETPD/ 1



else
	#set dicom directory
	dicom_dir=$(readlink -f $1)

	if [[ -z $(ls $dicom_dir/*dcm) ]];
		then 
		echo no dcm files in $1
		exit 1
	fi

	output=$(readlink -f $2)

	#set session ID
	if [ -z $3 ];
		then 
		sess_id=1
	else
		sess_id=$3
	fi

	

	cd $dicom_dir
	pwd
	#set sequence ID from dicom header for name of directory
	seq_id=$(dicom_hdr $(ls | head -n 1)  | grep Series\ Description| awk 'BEGIN { FS = "//" } { print $3 }')
	seq_id=$(echo ${seq_id//[[:blank:]]/})

	#set subject ID from dicom header
	sub_id=$(dicom_hdr $(ls | head -n 1)  | grep Patient\ Name | awk 'BEGIN { FS = "//" } { print $3 }')
	sub_id=$(echo ${sub_id//[[:blank:]]/})

	if [[ -d $output/$sub_id/sess_$sess_id/$seq_id ]]
			then 
			echo $output/$sub_id/sess_$sess_id/$seq_id already exists\!
			echo please check directory and delete before continuing
		else 
			if [ ! -d $output ]
				then
				echo making $output folder
				mkdir $output

			elif [ ! -d $output/$sub_id ]
				then
				echo making $output/$sub_id folder
				mkdir $output/$sub_id
			elif [ ! -d $output/$sub_id/sess_$sess_id ]; 
				then
				mkdir $output/$sub_id/sess_$sess_id
				echo making $output/$sub_id/sess_$sess_id
			fi
			mkdir -p $output/$sub_id/sess_$sess_id/$seq_id/dicoms
			cp $dicom_dir/*dcm $output/$sub_id/sess_$sess_id/$seq_id/dicoms
			if [[ -d $dicom_dir/../../MUX/ ]];
				then
				mv $dicom_dir/../../MUX/files/* $output/$sub_id/sess_$sess_id/$seq_id/
			fi
	fi
fi
