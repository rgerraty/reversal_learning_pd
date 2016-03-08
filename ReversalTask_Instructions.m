% Behavioral Reversal Learning Task written by Amanda Buch
% Modified from shopping learning task written by Madeleine Sharp, MD
% in the lab of Daphna Shohamy, PhD at Columbia University
% Last Updated December 17, 2015
function ReversalTask_Instructions(rewCat,scanned,buttonBox)

KbName('UnifyKeyNames');
rand('state',sum(100*clock));

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

try

    [window, windrect] = Screen('OpenWindow', 0); % get screen

   

    AssertOpenGL; % check for opengl compatability
    Screen('BlendFunction', window, GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);  %enables alpha bending
    black = BlackIndex(window);  % Retrieves the CLUT color code for black.
    white=WhiteIndex(window);
    Screen('FillRect', window, white ); % Colors the entire window black.
    priorityLevel=MaxPriority(window);  % set priority - also set after Screen init
    Priority(priorityLevel);
    [KeyIsDown, time, KeyCode]=KbCheck;% initialize ksey
    Screen('TextSize', window, 30); %set test size
    Screen('TextColor', window, black);
    [cx,cy]=RectCenter(windrect); %center point of screen
    [xPoints, yPoints]=RectSize(windrect);

    instructions='~/Documents/NETPD/instructionsPD/inst_acq/';
  
    KeyTest(buttonBox,okResp,leftResp,rightResp,window)

    %read in images
    for i=1:3
        [o,map,alpha] = imread([instructions num2str(i) '.jpg'], 'jpg');
        imgRect{i}=RectOfMatrix(o); %gets rects of ImagesArrays
        imgCell{i}=cat(3,o,alpha); %combines RBG matrix and alpha (transperency)
        imgTexCell{i}=Screen('MakeTexture', window, imgCell{i});
disp('read all in instructions-main');
    end    

    %%%%%%%%% done reading images - prepare Display%%%%%%%%%%%%%%%%%%%%%%%

    %%% Display instructions
    
    for i=1:numel(imgTexCell) % these are the final instructions before the real game
        Screen('DrawTexture', window, imgTexCell{i});
        [VBLTimestamp startChoice]=Screen('Flip', window);
        [keyIsDown,TimeStamp,keyCode] = KbCheck(buttonBox);
disp('instructions-main display loop');        
        WaitSecs(.5);
        while(1)
            [keyIsDown,TimeStamp,keyCode] = KbCheck(buttonBox);
            
            if keyCode(okResp)
                
                break; %so move on to next screeen as soon as spacebar is pressed
            end
        end
disp('instructions-main display loop-post taking specebar press');
    end
    
    Screen('CloseAll');

catch% catch error
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);

end
