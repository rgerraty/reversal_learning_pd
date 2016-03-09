function Rest()

%%% Runs full session of experiment for scanner

%% set up
KbName('UnifyKeyNames');


% responses

okResp=KbName('1!');
ttl=KbName('t');

% peripherals
[trigger,kb,buttonBox]=getExternals;
error=0;
if trigger==0
    trigger=kb
end
    
if buttonBox==0
    buttonBox=kb;
end

try
    [window, windrect] = Screen('OpenWindow', 0); % get screen
    AssertOpenGL; % check for opengl compatability
    Screen('BlendFunction', window, GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);  %enables alpha bending
    HideCursor;
    black = BlackIndex(window);  % Retrieves the CLUT color code for black.
    white=WhiteIndex(window);
    Screen('FillRect', window, white ); % Colors the entire window white.
    priorityLevel=MaxPriority(window);  % set priority
    Priority(priorityLevel);
    Screen('TextSize', window, 36); %set test size
    Screen('TextColor', window, black);
    
    
    %%%%%%%%% done reading images - prepare instrucitions%%%%%%%%%%%%%%%%%%%%%%%%%
    DrawFormattedText(window, 'Now we will start a rest scan. \n\n Just close your eyes and try not to fall asleep. \n\n\n Click the THUMB KEY when you are ready to start','center', 'center');
    
    Screen('Flip', window); % show text
    
    allowKeys=okResp;
    endTime=0;
    KbQ_Func(buttonBox,allowKeys,endTime);
    
    DrawFormattedText('Please wait while we start the scan.', 'center','center')
    Screen('flip', window); % show text
    
    keysOfInterest=zeros(1,256);
    keysOfInterest(ttl)=1;
    KbQueueCreate(trigger, keysOfInterest);	%queue for trigger
    KbQueueStart(trigger);
    KbQueueWait(trigger); % Wait until the 't' key signal is sent
    KbQueueFlush(trigger);
    
    
    Screen('Flip', window);
    Screen('FillRect', window, black ); % Colors the entire window white.
    WaitSecs(3);
    Screen('Flip', window);
    
    keysOfInterest=zeros(1,256);
    keysOfInterest(KbName('q'))=1;
    KbQueueCreate(kb, keysOfInterest); %queue for trigger
    KbQueueStart(kb);
    KbQueueWait(kb); % Wait until the 't' key signal is sent
    KbQueueFlush(kb);
    

    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    
catch% catch error
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);
    
end

