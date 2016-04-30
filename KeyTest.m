function KeyTest(buttonBox,okResp,leftResp,rightResp,window)


DrawFormattedText(window, 'Please click the INDEX finger button','center', 'center');
Screen('flip',window)
proc_key=zeros(1,256);
proc_key(leftResp)=1;
KbQueueCreate(buttonBox,proc_key);
KbQueueStart(buttonBox);
KbQueueWait(buttonBox);
KbQueueFlush(buttonBox);


DrawFormattedText(window, 'Please click the MIDDLE finger button','center', 'center');
Screen('flip',window)
proc_key=zeros(1,256);
proc_key(rightResp)=1;
KbQueueCreate(buttonBox,proc_key);
KbQueueStart(buttonBox);
KbQueueWait(buttonBox);
KbQueueFlush(buttonBox);


DrawFormattedText(window, 'Please click the THUMB button','center', 'center');
Screen('flip',window)
proc_key=zeros(1,256);
proc_key(okResp)=1;
KbQueueCreate(buttonBox,proc_key);
KbQueueStart(buttonBox);
KbQueueWait(buttonBox);
KbQueueFlush(buttonBox);