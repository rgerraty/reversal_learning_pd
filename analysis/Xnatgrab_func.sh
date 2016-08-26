#!/bin/bash
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt 

# to use Xnatgrab.sh [username] [password] [project] [subject] [sessions.txt]

username=$1
password=$2
project=$3
subject=$4
session=$5

if [ -z $1 ];
then 
echo  to use Xnatgrab.sh [username] [password] [project] [subject] [sessions.txt]
exit
fi


echo $username and $password

echo project $project  subject $subject  session $session
filename=${subject}_${session}
echo setting filename to $filename
curl -u ${username}:${password} https://xnat.nyspi.org/data/archive/projects/${project}/subjects/${subject}/experiments/${session}/scans/ALL/files?format=zip > $filename.zip
unzip ${filename}.zip $filename

