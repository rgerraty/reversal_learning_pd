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

%% Setting up the environment
    rand('state',sum(100*clock));  % reset the state of rand to a random value
    
    % Key Responses    
    KbName('UnifyKeyNames');
    escapeKey=KbName('q');
    if scanned==2
        leftResp=KbName('j');
        rightResp=KbName('k');
        okResp=KbName('space');
        ttl=KbName('t');
    else
        leftResp=KbName('2@');
        rightResp=KbName('3#');
        okResp=KbName('1!');
        ttl=KbName('t');
    end


     img=cell(numel(aq.halfScenesList),2); % the stimuli converted to a screen texture for presentation later in script
    for i=1:numel(aq.halfScenesList) % now size of objects and scenes arrays are both 1/2 the size
        [o,~,alpha]=imread([scenesDir aq.halfScenesList(i).name], 'jpg');
        StimCell=cat(3,o,alpha);
        img{i,1}=Screen('MakeTexture',window, StimCell);
        aq.scenes(i)=cellstr(aq.halfScenesList(i).name);        
        [o,~,alpha]=imread([objectsDir aq.halfObjectsList(i).name], 'jpg');
        StimRect=RectOfMatrix(o);
        StimCell=cat(3,o,alpha);
        img{i,2}=Screen('MakeTexture',window, StimCell);
        aq.objects(i)=cellstr(aq.halfObjectsList(i).name);
        Screen('TextSize',window, [30]);
        Screen('TextStyle',window,[2]);
        DrawFormattedText(window, ['Reading image #', num2str(i)], 'center','center', [0 0 0]); % temporary for coding purposes
        Screen('Flip', window);
    end  

    StimRect=StimRect*(yPoints/6*3)./StimRect(3); %to make stim larger, need to fix after
    
    StimX1=cx-360;
    StimX2=cx+360;
    
    StimBox1=CenterRectOnPoint(StimRect,StimX1,cy);
    StimBox2=CenterRectOnPoint(StimRect,StimX2,cy);
    StimBox1Frame=CenterRectOnPoint(StimRect*1.2,StimX1,cy);
    StimBox2Frame=CenterRectOnPoint(StimRect*1.2,StimX2,cy);

    StimBox=CenterRectOnPoint([0 0 xPoints/4 xPoints/4],cx,cy);  % to squeeze the image to square, which is 1/4 of screen x-dim
    StimBoxFrame=CenterRectOnPoint([0 0 xPoints/4 xPoints/4]*1.2,cx,cy);
    DrawFormattedText(window, ['Images prepared.'], 'center','center', [0 0 0]);
    Screen('Flip', window);

 Screen('TextSize',window, [50]);
    Screen('TextStyle',window,[2]);
    DrawFormattedText(window,['Which box has the points? \n\n Use the INDEX for Left \n use the MIDDLE finger for Right \n\n\n Press the THUMB to start'], 'center','center', [0 0 0]);
    Screen('Flip', window); % show text
    
   if scanned==1 || scanned==2
        DrawFormattedText(window,['Please wait while we prep the scanner\n\nExperimenter please press k when finished with prep scan'],'center','center',[0 0 0]);
        Screen('Flip',window);
        proc_key=zeros(1,256);
        proc_key(KbName('k'))=1;
        KbQueueCreate(kb,proc_key);
        KbQueueStart(kb);
        KbQueueWait(kb);
        KbQueueFlush(kb);

        DrawFormattedText(window,['Please wait while we start the scan'],'center','center',[0 0 0]);
        Screen('Flip',window);
        keysofint=zeros(1,256);
        keysofint(ttl)=1;
        KbQueueCreate(trigger,keysofint);
        KbQueueStart(trigger);
        KbQueueWait(trigger);

        DrawFormattedText(window,['Preparing the MRI...'],'center','center',[0 0 0]);
        Screen('Flip',window);
        WaitSecs(10.2)
    end     

save(sprintf('%s/aquisitionAQfin',folder_name),'aq')


