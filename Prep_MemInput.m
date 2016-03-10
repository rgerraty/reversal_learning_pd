% Preparing the Memory Test Inupt file. Script to be run fr each
% participant after day 2

% concatenate the output from days 1 and 2 and select the trials to be used
% for memory testing

% take every 2nd trial and, additionally, take ALL 10 trials pre and post
% reversal
% so given 150 trials on each day (i.e. 150 chosen images on each day), we
% will take 75+5+5 for a total of 85/day = 170 total

% at memory test, will be shown 170 old and 170 new = total 340

SubNum=input('Input Subject Number (e.g. 1, or 12 -- no leading zeros necessary):  ' )

day1=load(sprintf('~/Documents/NETPD/Subjects/Subject%d/day1/%d.csv',SubNum, SubNum));
day2=load(sprintf('~/Documents/NETPD/Subjects/Subject%d/day2',SubNum));