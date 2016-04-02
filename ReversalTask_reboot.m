function ReversalTask_reboot

KbName('UnifyKeyNames');
rand('state',sum(100*clock));
okResp=KbName('space'); 

SubjectNumber=input('Input Subject Number (e.g. 1, or 12 -- no leading zeros necessary):  ' );
day=input('Which day (1 or 2)?: '); %1st half list for 1st day; 2nd half list for 2nd day
scanned=input('Is this an fMRI experiment (1=yes, 2=no)?:  ');

folder_name=(sprintf('~/Documents/NETPD/Subjects/Subject%d/day%d',SubjectNumber,day));

KbName('UnifyKeyNames');
[trigger,kb,buttonBox]=getExternals; 

if scanned==2;
    trigger=kb;
    buttonBox=kb;
elseif scanned==1
     error=0;
     if trigger==0
         err=MException('AcctError:Incomplete', 'trigger box not detected');
         error=1;
     end
     if kb==0
         err=MException('AcctError:Incomplete', 'internal key board not detected');
         error=1;
     end
     if buttonBox==0
         err=MException('AcctError:Incomplete', 'Button Box not detected');
         error=1;
     end
     
     if error
         throw(err)
     end
end

load(strcat(num2str(folder_name),'/AQmat.mat'))
load(strcat(num2str(folder_name),'/aquisitionAQ.mat'))

trial=length(aq.chosenCat)



save(sprintf('%s/aquisitionAQfin',folder_name),'aq')


