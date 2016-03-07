% Behavioral Reversal Learning Task written by Amanda Buch
% Modified from shopping learning task written by Madeleine Sharp, MD
% in the lab of Daphna Shohamy, PhD at Columbia University
% Last Updated December 17, 2015

%MS changes (all changes labelled with MS in the script as well): 
%made all nTrials/2 into just nTrials -- i might be missing some strategy
%added strucure prefix to a bunch of variables eg. trialsS-->aq.trialsS
%changed scaned to 0/1 var
%added aq.optimal variable
%added a output matrix to save variables of interest in this format (easier
%for me for later)
%also saving out the space. just in case, useful especially in the
%beginning
%deleted save crashwork-maybe only causing me problems because not running as function

%what's up RTG?

function aq=ReversalTask_Aquisition(rewCat, day, med, scanned, folder_name, SubjectNumber,prob,blockLength, nTrials,trigger,buttonBox,kb)
Screen('Preference','SkipSyncTests',1); % change this to 0 when actually running, skips sync tests for troubleshooting purposes


% aq is the structure that contains all the matrices to be saved
% disp('line here') are tempory for troubleshooting purposes

%% Setting up the environment
    rand('state',sum(100*clock));  % reset the state of rand to a random value

%MS: changed scanned to 1/2 coding

    
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
   
%% Start psychtoolbox, open the screen, and set initial infromation

try
    
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
    [xPoints, yPoints]=RectSize(windrect);    
    disp(['Center is ',num2str(cx), ' ',num2str(cy), ' and winsize is ', num2str(xPoints), num2str(yPoints)])
    %pause
    
    scenesDir='~/Documents/NETPD/StimuliPD/Aquisition/300Scenes/';
    objectsDir='~/Documents/NETPD/StimuliPD/Aquisition/300Objects/';
    
    onsetlist=load('pilotonsets_1.mat'); % NEED TO FIX THIS
    onsetlist=onsetlist.onsetlist;

    maxtime=2.5;
    
if day == 1 %set and save randomized list    
    %% Locate and Choose the Stimuli

    
    allscenes=dir([scenesDir, '*.jpg']);
    allobjects=dir([objectsDir, '*.jpg']);
    ranS=randperm(numel(allscenes));
    ranO=randperm(numel(allobjects));
    aq.trialsS=ranS;
    aq.trialsO=ranO;
    ranScenes=allscenes(ranS);
    ranObjects=allobjects(ranO);
    %then take just the first 300 (=2*nTrials) to which the rest of the script will be
    %applied depending on if it's day 1 or 2
    aq.scenesList=ranScenes(1:nTrials*2);
    aq.objectsList=ranObjects(1:nTrials*2);
    
    %nTrials now set in main
    %% Probability of Reward
    aq.prob=prob;  %now probability distribution is set in main functino
    aq.rewProb=zeros(1,nTrials); %create zero matrix of numel(nTrials) 
    x=aq.prob*(nTrials); % determine number of rewarded trials based on probability and total trial number
    aq.rewProb(1:x)=1; % change the rewarded trials from 0 to 1
    aq.rewProb=aq.rewProb(randperm(numel(aq.rewProb))); %randomize order of rewarded trials
    disp(['# trials is ' num2str(nTrials) 'on line 107']);
    
    %% which is on left
    aq.stimOnLeft=ones(1,nTrials); %create matrix of ones to determine which category (1=scene, 2=object) will appear on the left
    x=nTrials/2; 
    aq.stimOnLeft(1:x)=2; %object =1/2 trials
    aq.stimOnLeft=aq.stimOnLeft(randperm(numel(aq.stimOnLeft))); % random ordering for Stimuli presented in stimBox1 on left (1=scene, 2=object)

%     %% randomize
%     nS=randperm(nTrials*2); %creates random order(permutation of nTrials) for scenes
%     aq.trialsS=nS;
%     nO=randperm(nTrials*2);  %a separate random list for objects
%     aq.trialsO=nO;
    
    %% choose first half to load
    %aq.scenesList= scenes(nS);  % apply random order to file name list
    scenesList=aq.scenesList; %had to duplicate because 'save' doesn't accept structure
    %aq.objectsList= scenes(nO);
    objectsList=aq.objectsList;
    
    aq.halfScenesList=scenesList(1:(floor(numel(scenesList)/2))); % choose only half to be presented per day
    aq.halfObjectsList=objectsList(1:(floor(numel(objectsList)/2)));
    halfScenesList=aq.halfScenesList; %duplicate save for use later
    halfObjectsList=aq.halfObjectsList;
    
    
    save(sprintf('%s/scenesList',folder_name),'scenesList'); % save total randomized directory list to load later
    save(sprintf('%s/objectsList',folder_name),'objectsList');
    save(sprintf('%s/trialsS',folder_name),'ranS');    
    save(sprintf('%s/trialsO',folder_name),'ranO');    
    
elseif day == 2  % load randomized lists for reward proability, scenes/objects order, and stimuli presented on left order and choose second half
    
    day1_folder=(sprintf('~/Documents/NETPD/Subjects/Subject%d/day1',SubjectNumber));
    load(sprintf('%s/scenesList',day1_folder)); %loads scenesList
    load(sprintf('%s/objectsList',day1_folder)); 
    load(sprintf('%s/trialsS',day1_folder));    
    load(sprintf('%s/trialsO',day1_folder));    
    
    aq.scenesList=scenesList;
    aq.objectsList=objectsList;
    aq.trialsS=ranS;
    aq.trialsO=ranO;
 
    %% Probability of Reward
    aq.prob=prob;  %now probability distribution is set in main functino
    aq.rewProb=zeros(1,nTrials); %create zero matrix of numel(nTrials) 
    x=aq.prob*nTrials; % determine number of rewarded trials based on probability and total trial number
    aq.rewProb(1:x)=1; % change the rewarded trials from 0 to 1
    aq.rewProb=aq.rewProb(randperm(numel(aq.rewProb))); %randomize order of rewarded trials
    %disp(['# trials is ' num2str(nTrials) 'on line 107']);
    
    %% which is on left
    aq.stimOnLeft=ones(1,nTrials); %create matrix of ones to determine which category (1=scene, 2=object) will appear on the left
    x=nTrials/2; 
    aq.stimOnLeft(1:x)=2; %object =1/2 trials
    aq.stimOnLeft=aq.stimOnLeft(randperm(numel(aq.stimOnLeft))); % random ordering for Stimuli presented in stimBox1 on left (1=scene, 2=object)
    
    aq.halfScenesList=scenesList((round(numel(scenesList)/2)+1):round(numel(scenesList)));
    halfScenesList=aq.halfScenesList; %duplicating save for use later
    aq.halfObjectsList=objectsList((round(numel(objectsList)/2)+1):round(numel(objectsList)));
    halfObjectsList=aq.halfObjectsList;
end

    aq.chosenSide=NaN(1,nTrials);%creates null matrix that will be populated by participant choices
    aq.chosenStim=aq.chosenSide;
    aq.chosenFileName=aq.chosenSide;
    aq.chosenFileName=mat2cell(aq.chosenFileName,1,repmat(1,1,nTrials));
    aq.chosenCat=aq.chosenSide;
    aq.rt=aq.chosenSide;

    aq.reversalAt=randi([80 100],1,1); % sets reversal at random value between 80 and 100, want to avoid block transition
    b=0;
    aq.blockLength=blockLength; %now set in main function
    aq.breaks=NaN(1,nTrials/aq.blockLength-1);
    aq.breaksLength=aq.breaks;
    aq.reward=aq.breaks;
    
    aq.scenes=cell(numel(aq.halfScenesList),1);
    aq.objects=aq.scenes;
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
        DrawFormattedText(window, ['Reading image #', num2str(i)], 'center','center', [0 0 0]); % temporary for coding purposes
        Screen('Flip', window);
    end  
    % will likely modify for stimuli to be added each block
    
    
    disp('line 67')
    % these can be modified depending on the size the stimuli should be
    % when presented on screen 
    StimRect=StimRect*(yPoints/6*2)./StimRect(3); %makes the StimRect a fraction of the size of the screen window, keeping same proportions
    
    StimX1=cx-(RectWidth(StimRect)/2)-((yPoints/2.5)-RectWidth(StimRect))/2;
    StimX2=cx+(RectWidth(StimRect)/2)+((yPoints/2.5)-RectWidth(StimRect))/2;
    
    StimBox1=CenterRectOnPoint(StimRect,StimX1,cy);
    StimBox2=CenterRectOnPoint(StimRect,StimX2,cy);
    StimBox1Frame=CenterRectOnPoint(StimRect*1.2,StimX1,cy);
    StimBox2Frame=CenterRectOnPoint(StimRect*1.2,StimX2,cy);

    StimBox=CenterRectOnPoint([0 0 xPoints/4 xPoints/4],cx,cy);  % to squeeze the image to square, which is 1/4 of screen x-dim
    StimBoxFrame=CenterRectOnPoint([0 0 xPoints/4 xPoints/4]*1.2,cx,cy);
    DrawFormattedText(window, ['Images prepared.'], 'center','center', [0 0 0]);
    Screen('Flip', window);

   %%  Write Instructions and check for escape key
    DrawFormattedText(window,['Which box has the points? \n\n Use the INDEX for Left \n use the MIDDLE finger for Right \n\n\n Press the THUMB to start'], 'center','center', [0 0 0]);
    Screen('Flip', window); % show text
    while(1)
        [keyIsDown,TimeStamp,keyCode] = KbCheck(buttonBox);
        if keyCode(okResp) %%allows examiner to press the space bar to pause the task if there is a problem, without terminating
            if scanned==1 || scanned==2
            DrawFormattedText(window,['Please wait while we start the scan'],'center','center',[0 0 0]);
            Screen('Flip',window);
            keysofint=zeros(1,256);
            keysofint(ttl)=1;
            KbQueueCreate(trigger,keysofint);
            KbQueueStart(trigger);
            KbQueueWait(trigger);
            DrawFormattedText(window,['Still more waiting...'],'center','center',[0 0 0]);
            Screen('Flip',window);
            WaitSecs(12.9)
            end
            break;
        end
        
    end

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
    for t=1:nTrials %MS: i'm probably missing something but I changed all the nTrials/2 to nTrials...
        if t>aq.reversalAt && reversal==0 % when trial number is greater than reversal point and reversal has not occured yet
            reversal=reversal+1;
            rewCat=abs(3-rewCat);
            disp(['reversing now for ', num2str(aq.reversalAt), ' and trial # ', num2str(t) ' out of ' num2str(nTrials/2) ...
                ' trials for reversal # ', num2str(reversal)])
        end
        [~, startTrial, KeyCode]=KbCheck;% initialize keys
        %Screen('FillRect', window, white); % Color the entire window grey
        Screen('TextSize',window, [50]);
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

 save(sprintf('%s/space',folder_name))
        
        if isequal(resp,KbName(leftResp))
            aq.chosenSide(t)=1; % i.e. Left
            aq.chosenStim(t)=img{t,aq.stimOnLeft(t)}; %MS: don't think this saves anything useful
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
            aq.chosenCat(t)=abs(aq.stimOnLeft(t)-3); %i.e the opposite of what's on the left
            
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
            %contains NANs in other spots, so don't need to add it
            resp=NaN; %there is no waitsecs here so that if no resp was recorded, go straight to next piece of code 
        end

 save(sprintf('%s/space',folder_name))
        %% Show Feedback Based on Choice
        % when chosen category = rewarded category, rewarded most of the
        % time (rewProb = 1)
        % when chosen category ~= rewarded category, rewarded some of the
        % time (rewProb = 0)
        if isnan(resp) % Does not respond in time?
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
                Screen('TextSize',window, [50]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);%put up crosshair after yellow frame is up for 0.5sec
                
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
                Screen('TextSize',window, [50]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);%put up crosshair after yellow frame is up for 0.5sec
                
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
                Screen('TextSize',window, [50]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5); %put up crosshair after yellow frame is up for 0.5sec
                
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
                Screen('TextSize',window, [50]);
                Screen('TextStyle',window,[2]);
                
                DrawFormattedText(window,'+','center','center',[0 0 0]);
                Screen('Flip',window, ExpStart+onsetlist(t)+aq.rt(t)+0.5);
                
                DrawFormattedText(window,'You won!!', 'center','center', [0 255 0]);
                %DrawFormattedText(window,'You won!!', 'center',cy-400, [0 255 0]);
                [VBLTimestamp startFB2(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+1.5); %put up FB after the crosshair has been on for 1sec
                aq.reward(t)=1;
                aq.optimal(t)=0;
                WaitSecs(1);
           end
        end
        
        DrawFormattedText(window,'+','center','center',[0 0 0]);
        [VBLTimestamp FBOffTime(t)]=Screen('Flip', window, ExpStart+onsetlist(t)+aq.rt(t)+2.5);    % remove feedback after 1sec (ie 2sec since
    
        
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
            if mod(t,aq.blockLength)==0 && t<nTrials %MS changed block length to 6 for testing
                b=b+1;
                aq.breaks(b)=GetSecs;
                Screen('TextSize',window, [30]);
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
                            WaitSecs(12.9)
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
        subNumCell=mat2cell(outputmat(:,1),repmat(1,1,150),repmat(1,1,1));
        imgCell=aq.chosenFileName';
        %use mat2cell to convert outputmat to cell format. Specificy to
        %subdivide into smaller arrays for each row and each col (1x1)
        restCell=mat2cell(outputmat(:,[12,11,2,4,3,9,10,13]),repmat(1,1,150),repmat(1,1,8));
        %concatenate along the row dimension
        memInputCell=cat(2,subNumCell,imgCell,restCell);
        %print to a output file by filling it row by row. So start with
        %header row (all strings) then add the cell rows (a mix of string
        %and numbers)
        fid = fopen(sprintf('%s/memInput.csv',folder_name),'w')

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
catch
    Screen('CloseAll');
    %save(sprintf('%s/crashwork',folder_name),'crashWork'); %this saves the workspace (minus those cells) in event of a crash, for debugging
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);
 end %end the while loop
end    
