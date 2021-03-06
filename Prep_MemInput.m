% Preparing the Memory Test Inupt file. Script to be run for each
% participant after day 2

% Needed for the memory test:
% 1) list of ALL images shown on days 1 and 2, regardless of chosen and
% skipped responses. This will be used to select NEW images as foils

    %  This list is generated as part of the Day 1 script. It is saved in
    %  the main subject folder as a .csv


% 2) concatenate the csv output files from days 1 and 2 
% the outputs have already been pruned to include only the chosen images

% *** this is run from the terminal, notfrom matlab, though by starting off
% the commands with "!" we can execute these commands in matlab




%% ** use the commands below but MUST MANUALLY ENTER THE SUBJECT NUMBER

% make temp file from day 2 output, excluding the first line which is the
% header row
!grep -v subjectID ~/Documents/NETPD/Subjects/SubjectXXX/day2/XXX_2.csv > day2temp.csv

!cat ~/Documents/NETPD/Subjects/SubjectXXX/day1/XXX_1.csv day2temp.csv > ~/Documents/NETPD/Subjects/SubjectXXX/XXX.csv

day1=textscan(sprintf('~/Documents/NETPD/Subjects/Subject%d/day1/%d.csv',SubNum, SubNum));
day2=load(sprintf('~/Documents/NETPD/Subjects/Subject%d/day2/%d.csv',SubNum, SubNum));

