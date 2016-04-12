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
load(strcat(num2str(folder_name),'/inputP.mat'))


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

scenesDir='~/Documents/NETPD/StimuliPD/Aquisition/300Scenes/';
objectsDir='~/Documents/NETPD/StimuliPD/Aquisition/300Objects/';
    
    
onsetlist=load(sprintf('pilotonsets_%d.mat',p.list));
onsetlist=onsetlist.onsetlist;

maxtime=2.5;

[window, windrect] = Screen('OpenWindow', 0); % get screen
AssertOpenGL; % check for opengl compatability
Screen('BlendFunction', window, GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);  %enables alpha blending for online image processing
HideCursor;
    
black = BlackIndex(window);  % Retrieves the CLUT color code for black.
white=WhiteIndex(window);
Screen('FillRect', window, white ); % Colors the entire window white.
    
priorityLevel=MaxPriority(window);  % set priority
Priority(priorityLevel);
    
Screen('TextSize', window, 36); %set text size
Screen('TextColor', window, black);
    
[cx,cy]=RectCenter(windrect); %center point of screen



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

startTime=datestr(now);
ExpStart=GetSecs;
        
 
escape=0;
while escape==0
    if escape==1;
        break % also provides an escape mechanism to stop the task
    end
    
 % preparing for first trial  
%  DrawFormattedText(window,'+','center','center',[0 0 0]);
%  Screen('Flip',window);

    %%
    startTime=datestr(now);
    ExpStart=GetSecs;
        
    %% Start of Trial Aquisition %%
    reversal=0;
    for t=trial:nTrials %MS: i''m probably missing something but I changed all the nTrials/2 to nTrials...
        if t>aq.reversalAt && reversal==0 % when trial number is greater than reversal point and reversal has not occured yet
            reversal=reversal+1;
            rewCat=abs(3-p.versionRewardCat);
            disp(['reversing now for ', num2str(aq.reversalAt), ' and trial # ', num2str(t) ' out of ' num2str(nTrials/2) ...
                ' trials for reversal # ', num2str(reversal)])
        end
        [~, startTrial, KeyCode]=KbCheck;% initialize keys
        %Screen('FillRect', window, white); % Color the entire window grey
        Screen('TextSize',window, [100]);
        Screen('TextStyle',window,[2]);
        DrawFormattedText(window,'+','center','center',[0 0 0]);
        Screen('Flip', window);
        
        while (GetSecs-startTrial)<=.5 %checks each loop for held escape key
            if ~(KeyCode(escapeKey))
                [~, ~, KeyCode]=KbCheck(buttonBox);
                WaitSecs(0.001);
            else
                escape=1;
            end
        end
        if escape==1
            break
        end
        
        if aq.stimOnLeft(t) == 1 % Place scene in stimBox1 on Left
            trials1=aq.trialsS(t); %MS: added aq.
            trials2=aq.trialsO(t);
        elseif aq.stimOnLeft(t) == 2 % Place object in stimBox1 on Left
            trials1=aq.trialsO(t);
            trials2=aq.trialsS(t);
        end
        %%%% SHOW STIMULI %%%%
        %disp(['t is ' num2str(t) 'and trials1 is ' num2str(trials1) ' and stimOnLeft is' num2str(aq.stimOnLeft(t)) ' and size of img' num2str(size(img))])
        disp(['t is ' num2str(t) ' and stimOnLeft is' num2str(aq.stimOnLeft(t)) ' and size of img' num2str(size(img))])
        
        Screen('DrawTexture', window, img{t,aq.stimOnLeft(t)}, [], StimBox1); % render stimuli image in StimBox1 (L); img{i,j} category chosen by stimOnLeft and image in list by j
        Screen('FrameRect',window, black, StimBox1, 4);
        Screen('DrawTexture', window, img{t,abs(aq.stimOnLeft(t)-3)}, [], StimBox2);
        Screen('FrameRect',window, black, StimBox2, 4);  
        [VBLTimestamp startChoice(t)]=Screen('Flip', window,ExpStart+onsetlist(t)); % displays on screen and starts choice timing    
        
        %% Response
       allowKeys=[leftResp rightResp];
       endTime=startChoice(t)+maxtime;
       
       if 0
            keyDown=1; %assume first that key is down
       
       		%this is checking that key isnt down and must be the same length as the respnse while loop
            [keyDown,RT_Response,keyCode] = KbQ_Func(buttonBox,allowKeys,endTime)
            if isempty(KbName(keyCode))
                keyDown=0;
                break;
            end
            WaitSecs(.001) %do this loop or the first msec to make sure that key isnt held down
        end

            
        [keyDown,RT_Response,keyCode] = KbQ_Func(buttonBox,allowKeys,endTime);
        %if KbName(keyCode)==leftResp || KbName(keyCode)==rightResp %checks if left or right key was pressed
        %   break;
        %end
        WaitSecs(.001);
                           
       
        disp('line 198')

        
        

        resp=keyCode; %find name of key that was pressed **however KbQ_Func now takes care of this, we think
        if isempty(resp)
            resp=NaN;
            aq.rt(t)=maxtime; 
            aq.keyPressed(t)=resp;
        else
            aq.rt(t)=RT_Response-startChoice(t);% compute response time in sec
            aq.keyPressed(t)=KbName(resp);
        end
        
        
        %if iscell(resp) %checking if 2 keys were pressed and keeping 2nd
         %   resp=resp{2};
        %end
        
        %this has been causing us problems, in the scanner the keycode is
        %2@, which has length>1
        %We may want to flag dual presses, but will have to do it
        %differently
        
        %if length(resp)>1
         %   resp=NaN;
        %end
        
        

        % Add Yellow Frame to Chosen Stimuli
        Screen('DrawTexture', window, img{t,aq.stimOnLeft(t)}, [], StimBox1);
        Screen('FrameRect',window, black, StimBox1, 4);
        Screen('DrawTexture', window, img{t,abs(aq.stimOnLeft(t)-3)}, [], StimBox2);
        Screen('FrameRect',window, black, StimBox2, 4);  

        
        if isequal(resp,KbName(leftResp))
            aq.chosenSide(t)=1; % i.e. Left
            aq.chosenStim(t)=img{t,aq.stimOnLeft(t)}; %MS: don''t think this saves anything useful
            aq.chosenCat(t)=aq.stimOnLeft(t);
            
            %saving out the image filename stimOnLeft=1 is Scene
            if aq.stimOnLeft(t)==1
                aq.chosenFileName(t)=aq.scenes(t);
            elseif aq.stimOnLeft(t)==2
                aq.chosenFileName(t)=aq.objects(t);
            end
            
            Screen('FrameRect',window, [255 255 0], StimBox1Frame, 6);
            Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)); % show response
            %WaitSecs(.5); %so show the feedback for 0.5sec
            resp=1;
        elseif isequal(resp,KbName(rightResp))
            aq.chosenSide(t)=2; % i.e. Right
            aq.chosenStim(t)=img{t,abs(aq.stimOnLeft(t)-3)};
            aq.chosenCat(t)=abs(aq.stimOnLeft(t)-3); %i.e the opposite of what''s on the left
            
            %saving out the image filename stimOnLeft=1 is Scene
            if aq.stimOnLeft(t)==1 %i.e. scene
                aq.chosenFileName(t)=aq.objects(t); %then take opposite since chose Right
            elseif aq.stimOnLeft(t)==2
                aq.chosenFileName(t)=aq.scenes(t);
            end
            
            Screen('FrameRect',window, [255 255 0], StimBox2Frame, 6);
            Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)); % show response
            %WaitSecs(.5);
            resp=2;
        else
            aq.chosenSide(t)=NaN;
            aq.chosenStim(t)=NaN;   
            %aq.chosenFileName(t)=0; If no choice is made, the cell already
            %contains NANs in other spots, so don''t need to add it
            resp=NaN; %there is no waitsecs here so that if no resp was recorded, go straight to next piece of code 
        end


        %% Show Feedback Based on Choice
        % when chosen category = rewarded category, rewarded most of the
        % time (rewProb = 1)
        % when chosen category ~= rewarded category, rewarded some of the
        % time (rewProb = 0)
        if isnan(resp) % Does not respond in time?
            Screen('TextSize',window, [100]);
            Screen('TextStyle',window,[2]);
            
            [nx, ny,TB]=DrawFormattedText(window,' Too Slow! ', 'center','center', [0 0 0]);
            Screen('FillRect', window, white, [TB(1)+2 TB(2)+3 TB(3)+2 TB(4)+3]);
            DrawFormattedText(window,' Too Slow! ', 'center','center', [0 0 0]);
            [VBLTimestamp startFB(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)); %in this case aq.rt is the Maxtime
            aq.reward(t)=NaN;
            aq.optimal(t)=NaN;
            %WaitSecs(.5);
        elseif aq.rewProb(t)==1
            if (resp==1 && aq.stimOnLeft(t)==rewCat) || (resp==2 && abs(3-aq.stimOnLeft(t))==rewCat)
%                 if resp==1
%                     Screen('DrawTexture', window, img{trials1,rewCat}, [], StimBox); %%%% 
%                 elseif resp==2
%                     Screen('DrawTexture', window, img{trials2,rewCat}, [], StimBox); %%%% 
%                 end
%                 Screen('FrameRect',window, [0 255 0], StimBoxFrame, 6); %make frame green
                Screen('TextSize',window, [100]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);%put up crosshair after yellow frame is up for 0.5sec
                
                Screen('TextSize',window, [150]);
                Screen('TextStyle',window,[2]);
                DrawFormattedText(window,'You won!!', 'center','center', [0 255 0]);
                %DrawFormattedText(window,'You won!!', 'center',cy-400, [0 255 0]);
                [VBLTimestamp startFB2(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+1.5);%put up FB after the crosshair has been on for 1sec
                aq.reward(t)=1;
                aq.optimal(t)=1;
                WaitSecs(1);
            else % rewprob = 1 but chosen category ~= rewarded category
%                 if resp==1
%                     Screen('DrawTexture', window, img{trials1,abs(3-rewCat)}, [], StimBox); %%%% 
%                 elseif resp==2
%                     Screen('DrawTexture', window, img{trials2,abs(3-rewCat)}, [], StimBox); %%%% 
%                 end
%                 Screen('FrameRect',window, [255 0 0], StimBoxFrame, 6); %make frame red               
                Screen('TextSize',window, [100]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);%put up crosshair after yellow frame is up for 0.5sec
                
                Screen('TextSize',window, [150]);
                Screen('TextStyle',window,[2]);
                DrawFormattedText(window,'Wrong!!', 'center','center', [255 0 0]);
                %DrawFormattedText(window,'Wrong!!', 'center',cy-400, [255 0 0]);
                [VBLTimestamp startFB2(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+1.5);%put up FB after the crosshair has been on for 1sec
                aq.reward(t)=0;
                aq.optimal(t)=0;
                WaitSecs(1);
            end
        elseif aq.rewProb(t)==0
           if (resp==1 && aq.stimOnLeft(t)==rewCat) || (resp==2 &&  abs(3-aq.stimOnLeft(t))==rewCat)
%                if resp==1
%                 Screen('DrawTexture', window, img{trials1,rewCat}, [], StimBox); %%%% 
%                elseif resp==2
%                 Screen('DrawTexture', window, img{trials2,rewCat}, [], StimBox); %%%% 
%                end
%                 Screen('FrameRect',window, [255 0 0], StimBoxFrame, 6); %make frame red               
                Screen('TextSize',window, [100]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5); %put up crosshair after yellow frame is up for 0.5sec
                
                Screen('TextSize',window, [150]);
                Screen('TextStyle',window,[2]);
                DrawFormattedText(window,'Wrong!!', 'center','center', [255 0 0]);
                %DrawFormattedText(window,'Wrong!!', 'center',cy-400, [255 0 0]);
                [VBLTimestamp startFB2(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+1.5);%put up FB after the crosshair has been on for 1sec
                aq.reward(t)=0;
                aq.optimal(t)=1;
                WaitSecs(1);
           elseif (resp==1 && aq.stimOnLeft(t)~=rewCat) || (resp==2 &&  abs(3-aq.stimOnLeft(t))~=rewCat)
%                 if resp==1
%                     Screen('DrawTexture', window, img{trials1,abs(3-rewCat)}, [], StimBox); %%%% 
%                 elseif resp==2
%                     Screen('DrawTexture', window, img{trials2,abs(3-rewCat)}, [], StimBox); %%%% 
%                 end
%                 Screen('FrameRect',window, [0 255 0], StimBoxFrame, 6); %make frame green
                Screen('TextSize',window, [100]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);
                
                Screen('TextSize',window, [150]);
                Screen('TextStyle',window,[2]);
                DrawFormattedText(window,'You won!!', 'center','center', [0 255 0]);
                %DrawFormattedText(window,'You won!!', 'center',cy-400, [0 255 0]);
                [VBLTimestamp startFB2(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+1.5); %put up FB after the crosshair has been on for 1sec
                aq.reward(t)=1;
                aq.optimal(t)=0;
                WaitSecs(1);
           end
        end
        Screen('TextSize',window, [100]);
        Screen('TextStyle',window,[2]);
        DrawFormattedText(window,'+','center','center',[0 0 0]);
        [VBLTimestamp FBOffTime(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+2.5);    % remove feedback after 1sec (ie 2.5sec since =0.5+1+1)
    
        
    %% MS: create an output matrix
    
        outputmat(t,1)=SubjectNumber;
        outputmat(t,2)=t;
        outputmat(t,3)=day;
        outputmat(t,4)=med;
        outputmat(t,5)=aq.stimOnLeft(t); %this is image category on Left: 1=scene, 2=obj
        outputmat(t,6)=rewCat;
        outputmat(t,7)=resp; %1=left, 2=right
        outputmat(t,8)=aq.rewProb(t);
        outputmat(t,9)=aq.reward(t); %feedback they were acually given
        outputmat(t,10)=aq.optimal(t);
        outputmat(t,11)=aq.chosenCat(t); %1=scene
        outputmat(t,12)=1; %1=old, all are old (for use in memory test
        outputmat(t,13)=aq.rt(t);
     
    
    %%
        
    %% Save frequently and set blocks
            if mod(t,10)==1
                save(sprintf('%s/aquisitionAQ',folder_name),'aq');
                save(sprintf('%s/AQmat',folder_name),'outputmat');
            end
            % below is where we could move the image loading to
            if mod(t,aq.blockLength)==0 && t<nTrials 
                b=b+1;
                aq.breaks(b)=GetSecs;
                Screen('TextSize',window, [50]);
                Screen('TextStyle',window,[2]);
                DrawFormattedText(window,'Please take a break for as long as you need. \n\n Press the SPACE BAR when you are ready to start again.', 'center','center', [0 0 0]);            
                Screen('Flip',window);
                while(1)
                    [keyIsDown,TimeStamp,keyCode] = KbCheck;
                    if keyCode(okResp) %end the break when spacebar is pressed
                        if scanned==1 || scanned==2
                            DrawFormattedText(window,['Please wait while we re-boot the scanner\n\nExperimenter please press k when finished with prep scan'],'center','center',[0 0 0]);
                            Screen('Flip',window);
                            proc_key=zeros(1,256);
                            proc_key(KbName('k'))=1;
                            KbQueueCreate(kb,proc_key);
                            KbQueueStart(kb);
                            KbQueueWait(kb);
                            KbQueueFlush(kb);
                            DrawFormattedText(window,['Warming up...'],'center','center',[0 0 0]);
                            Screen('Flip',window);
                            keysofint=zeros(1,256);
                            keysofint(ttl)=1;
                            KbQueueCreate(trigger,keysofint);
                            KbQueueStart(trigger);
                            KbQueueWait(trigger);
                            KbQueueFlush(trigger);
                            DrawFormattedText(window,['Still warming up...'],'center','center',[0 0 0]);
                            Screen('Flip',window);
                            WaitSecs(10.2)
                        end
                        break;
                    end
                end
                aq.breaksLength(b)=GetSecs-aq.breaks(b);
                ExpStart=ExpStart+aq.breaksLength(b);
            end
            
    end % end trial loop
        save(sprintf('%s/aquisitionAQ',folder_name),'aq')
        save(sprintf('%s/AQmat',folder_name),'outputmat');
        save(sprintf('%s/space',folder_name))
        
        %% create output cell for use in the memory test: contains strings and num
        % (we will concatenate day 1 and day 2 in seperate script to be rn
        % after day 2 for each ppant individually)
        
        % first, prune the output mat 
        % take every 2nd trial and, additionally, take ALL 10 trials pre and post reversal
        % so given 150 trials on each day (i.e. 150 chosen images on each day), we
        % will take 75+5+5 for a total of 85/day = 170 total
        % at memory test, will be shown 170 old and 170 new = total 340

        ind=[2:2:(aq.reversalAt-11),(aq.reversalAt-9):1:(aq.reversalAt+11),(aq.reversalAt+13):2:nTrials];;
        
        %use mat2cell to convert outputmat to cell format. Specificy to
        %subdivide into smaller arrays for each row and each col (1x1)
        subNumCell=mat2cell(outputmat(ind,1),repmat(1,1,length(ind)),repmat(1,1,1));
        imgCell=aq.chosenFileName(ind)';
        
        restCell=mat2cell(outputmat(ind,[12,11,2,4,3,9,10,13]),repmat(1,1,length(ind)),repmat(1,1,8));
        %concatenate along the row dimension
        memInputCell=cat(2,subNumCell,imgCell,restCell);
        %print to a output file by filling it row by row. So start with
        %header row (all strings) then add the cell rows (a mix of string
        %and numbers)
        fid = fopen(sprintf('%s/%d_%d.csv',folder_name,SubjectNumber,day),'w')

        numColumns = size(memInputCell,2);
        rowFmt = ['%f,' '%s,' repmat('%f,',1,numColumns-3), '%f\n']; %last one, which doesn't need the extra comma
        fprintf(fid,'%s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n', 'subjectID','stimID','old','category','scannerTrialNum','med','day','scannerFB','scannerOptimal','scannerRT'); %header, first row
        for i=1:size(memInputCell,1)
            fprintf(fid,rowFmt,memInputCell{i,1:end});
        end
        
        fclose(fid)
        
        %%
        escape=1;
 end
 
    aq.totalPoints=nansum(aq.reward)*10;
    Screen('TextSize',window, [50]);
    Screen('TextStyle',window,[2]);
    DrawFormattedText(window,['You are finished! \n\n You won ' num2str(aq.totalPoints,'%1.0f') ' points \n\n Please inform the experimenter.'], 'center','center', [0 0 0]);    
    Screen('Flip', window);    
    WaitSecs(5);   
    while(1)
        [~,~,keyCode] = KbCheck(kb);
        if keyCode(okResp)
            break;
        end
    end
    Screen('CloseAll');
    escape=1;          %#ok<NASGU> % Exit after last trial
    Screen('CloseAll');
    %save(sprintf('%s/crashwork',folder_name),'crashWork'); %this saves the workspace (minus those cells) in event of a crash, for debugging
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);
 end %end the while loop
end    


save(sprintf('%s/aquisitionAQfin',folder_name),'aq')


