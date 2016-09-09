function [] = repatime_block_single_Final(subjectNumber,iBlock,isMEG,is_debugging,use_eyetracker)
% repatime is an experiment based off of MEGbound where we test how
% boundaries influence various measures of memory at a delay and with
% repetition

%% create subject directory

if subjectNumber < 10
    subjStr = ['0' num2str(subjectNumber)];
else
    subjStr = num2str(subjectNumber);
end

%% set experiment paths

basedir = pwd; % home directory that we are in when script is running
listdir = [basedir '/lists/']; % where we store the encoding lists (e.g. for each subject)
imagedir = [basedir '/stimuli/']; addpath(genpath(imagedir)); % where all of the item pictures are stored
datadir = [basedir '/data/']; % this is where we write all of the behavioral data to look back at later
subdir = [datadir subjStr]; % telling Matlab what subject-specific folder datadir should go to
mkdir(subdir) % this simply makes the folder of subdir

%Add PTBWrapper if its not in the path
p = path; % variable for all of the paths up in matlab
s = strfind(p,'/MEGbound/PTBWrapper/'); % out of all the paths up in matlab, find the 'x' folder
if isempty(s) % if the folder is not found in "s = ", then add it.
    addpath(genpath([basedir '/PTBWrapper/']));
end

%% set stimulus durations

if is_debugging % if we just want to quickly run the experiment for debugging run everything on a compressed time scale
    Screen('Preference', 'SkipSyncTests', 1);
    StimDur = .01;
    ITI = .01;
    FixDur = .01;
    TestDur = .01;
    TestLoop=1;
else % if not debugging, run with normal timing
    debugmode = 0;
    StimDur = 1.5;
    ITI = 1.0;
    FixDur = .5;
    TestDur = 'any';
    TestLoop=1;
end

% if debugging, skip some stuff
%PTBVersionCheck(1,1,12,'at least');
PTBSetIsDebugging(is_debugging);

%% check for use of eye tracker

if use_eyetracker
    PTBInitEyeTracker();
    paragraph = {'Eyetracker initialized.','Get ready to calibrate.'};
    PTBDisplayParagraph(paragraph, GL_paragraph_pos, {'a'});
    PTBCalibrateEyeTracker;
    % actually starts the recording
    % name correponding to MEG file (can only be 8 characters!!, no extension)
    
    PTBStartEyeTrackerRecording(subject);
end

%% Set some PTB defaults

PTBSetExitKey('ESCAPE');
PTBSetBackgroundColor([128 128 128]);
PTBSetTextColor([255 255 255]);		% This defaults to white = (255, 255, 255).
PTBSetTextFont('Arial');		% This defaults to Arial.
PTBSetTextSize(30);				   % This defaults to 30.

% set output file stuff, we actually won't use these output files but still
% have to set them to get our program running in PTB
% PTBSetLogFiles(['S' SubjStr '_' num2str(iBlock) '_log_file.txt'], ['S' SubjStr '_' num2str(iBlock) '_data_file.txt']);
% PTBSetLogHeaders({'condition','item','itempos','itemcolor','targetloc'});

% set some global variables
global PTBLastPresentationTime;			%#ok<NUSED> % When the last display was presented.
global PTBLastKeyPressTime;				  %#ok<NUSED> % When the last response was given.
global PTBLastKeyPress;						   % The last response given.
global PTBScreenRes;
global PTBWaitForKey;% Has 'width' and 'height' of current display in pixels


%% set up counterbalancing

% load([basedir 'encodingLists_balance_nov20.mat'])
%%
try
    % start experiment
    PTBSetupExperiment('Repatime'); % sets up some essentials to run a PTB experiment, name is less relevant
    
    %% load and format encoding and test stimuli
    % go to encoding directory and load encoding sequence
    
    cbVersion = mod(subjectNumber,20);
    if cbVersion == 0
        cbVersion = 20;
    end
    
    % load in encoding sequences
    %load([listdir 'encodingSeq',num2str(cbVersion)])
    
    load([listdir 'encoding.mat'])
    encodingList.eventNum = [subEncod(cbVersion).block(iBlock).itrial.eventNum]';
    encodingList.eventCol = [subEncod(cbVersion).block(iBlock).itrial.eventCol]';
    encodingList.eventPos = [subEncod(cbVersion).block(iBlock).itrial.eventPos]';
    encodingList.eventItm = [subEncod(cbVersion).block(iBlock).itrial.eventItm]';
    encodingList.eventTOW = [subEncod(cbVersion).block(iBlock).itrial.eventTOW]';
    encodingList.eventTOA = [subEncod(cbVersion).block(iBlock).itrial.eventTOA]';
    encodingList.eventPrA = [subEncod(cbVersion).block(iBlock).itrial.eventPrA]';
    encodingList.eventPrF = [subEncod(cbVersion).block(iBlock).itrial.eventPrF]';
    encodingList.eventPrR = [subEncod(cbVersion).block(iBlock).itrial.eventPrR]';
    
    % load test lists
    load([listdir 'test.mat'])
    testList.TempOrder.eventNum = [subTests(cbVersion).block(iBlock).testListTempOrder.eventNum]';
    testList.TempOrder.eventCol = [subTests(cbVersion).block(iBlock).testListTempOrder.eventCol]';
    testList.TempOrder.eventPos = [subTests(cbVersion).block(iBlock).testListTempOrder.eventPos]';
    testList.TempOrder.eventItm = [subTests(cbVersion).block(iBlock).testListTempOrder.eventItm]';
    testList.TempOrder.eventWth = [subTests(cbVersion).block(iBlock).testListTempOrder.eventWth]';
    testList.TempOrder.eventAcr = [subTests(cbVersion).block(iBlock).testListTempOrder.eventAcr]';
    
    testList.testListItems.eventNum = [subTests(cbVersion).block(iBlock).testListItems.eventNum]';
    testList.testListItems.eventCol = [subTests(cbVersion).block(iBlock).testListItems.eventCol]';
    testList.testListItems.eventPos = [subTests(cbVersion).block(iBlock).testListItems.eventPos]';
    testList.testListItems.eventItm = [subTests(cbVersion).block(iBlock).testListItems.eventItm]';
    testList.testListItems.eventPrA = [subTests(cbVersion).block(iBlock).testListItems.eventPrA]';
    testList.testListItems.eventPrF = [subTests(cbVersion).block(iBlock).testListItems.eventPrF]';
    testList.testListItems.eventPrR = [subTests(cbVersion).block(iBlock).testListItems.eventPrR]';
    
    %%  variables to be used in experiment loops
    colorboxSize = 600;
    whiteboxSize = 350;
    whitebox = 255.*ones(whiteboxSize,whiteboxSize,3); % generates the white box that item stimuli will be placed inside
    practicetrials = {'661.bmp'; '662.bmp'; '663.bmp'; '664.bmp'; '665.bmp'; '666.bmp'; '667.bmp'; '668.bmp'; '669.bmp'; '670.bmp'; '671.bmp'; '672.bmp'}; % items appearing during practice run
    pfnum = 1; % variable to indicate which practice file should be referenced in while loop
    %encodingSeq = ; % this needs to be the individual event sequence matrix for each subject
    nTrials = length(encodingList.eventNum); % define the number of trials
    purpleRGB = [165 10 242];
    orangeRGB = [255 179 0];
    
    
    %initiate event output data
    encodingDataFile = cell(nTrials+1,16);
    encodingDataFile{1,1} = 'Subject_Number';
    encodingDataFile{1,2} = 'Immediate_OR_Delay';
    encodingDataFile{1,3} = 'Block_Number';
    encodingDataFile{1,4} = 'Event_Number';
    encodingDataFile{1,5} = 'Event_Color';
    encodingDataFile{1,6} = 'WithinEvent_Position';
    encodingDataFile{1,7} = 'Object_ID';
    encodingDataFile{1,8} = 'WithinEvent_TempOrder';
    encodingDataFile{1,9} = 'AcrossBound_TempOrder';
    encodingDataFile{1,10}= 'AcrossBound_ObjPriming_Forward';
    encodingDataFile{1,11}= 'WithinEvent_ObjPriming_Forward';
    encodingDataFile{1,12}= 'WithinEvent_ObjPriming_Reverse';
    encodingDataFile{1,13}= 'Trial_Onset'; % when the trial started
    encodingDataFile{1,14}= 'Response_Time'; % when the response was made
    encodingDataFile{1,15}= 'Reaction_Time'; % reaction time is response time - trial onset
    encodingDataFile{1,16} = 'Response'; % this is when the trial started
    
    %initiate test output data
    orderTestDataFile = cell(3,16);
    orderTestDataFile{1,1} = 'Subject_Number';
    orderTestDataFile{1,2} = 'Immediate_OR_Delay';
    orderTestDataFile{1,3} = 'Block_Number';
    orderTestDataFile{1,4} = 'Event_Number';
    orderTestDataFile{1,5} = 'Event_Color';
    orderTestDataFile{1,6} = 'WithinEvent_Position';
    orderTestDataFile{1,7} = 'Object1_ID';
    orderTestDataFile{1,8} = 'Object2_ID';
    orderTestDataFile{1,9} = 'WithinEvent_TempOrder';
    orderTestDataFile{1,10} = 'AcrossBound_TempOrder';
    orderTestDataFile{1,11}= 'Trial_Onset'; % when the trial started
    orderTestDataFile{1,12}= 'Response_Time'; % when the response was made
    orderTestDataFile{1,13}= 'Reaction_Time'; % reaction time is response time - trial onset
    orderTestDataFile{1,14} = 'Response'; % this is when the trial started
    orderTestDataFile{1,15} = 'Correct_Response'; % this is when the trial started
    
  
    %% practice run during first block
    if iBlock == 1
        
        % practice test
        instr = {'Welcome to the Memory Experiment!', 'In this task, you will view a series of objects embedded on a color background.','For each trial, please visualize the object in the color background and judge whether the', 'object/color background combination is pleasing to you. Then, you will be tested','on your memory for the objects and the order in which the objects were presented.','Press any key to go on.'};
        PTBDisplayParagraph(instr,{'center',30},{'any'}); % shows inst paragraph to participant and waits until keypress to move on
        PTBDisplayBlank({0.3},'Blank');
        
        instr = {'In this practice experiment, you will see 6 objects, one at a time.',' For each object, please judge whether the object/color combination is','pleasing to you (J - Pleasing; K - Unpleasing). Try to remember the color of the background',' for each object, as well as the order of the objects because you will be tested',' after this study period. Press any key to give it a try.'};
        PTBDisplayParagraph(instr,{'center',30},{'any'});
        PTBDisplayBlank({2},'Blank');
        
        % generate color borders for practice events
        currcolorbox = cat(3,ones(colorboxSize,colorboxSize).*purpleRGB(1), ...
            ones(colorboxSize,colorboxSize).*purpleRGB(2), ...
            ones(colorboxSize,colorboxSize).*purpleRGB(3));
        
        for itrial = 1:12 % loop over practice trials
            PTBDisplayText('J - PLEASING     K - UNPLEASING',{[PTBScreenRes.width*.32 PTBScreenRes.height*.8]},{-1});
            if itrial == 7 % change the color of the background at the event boundary
                
            currcolorbox = cat(3,ones(colorboxSize,colorboxSize).*orangeRGB(1), ...
            ones(colorboxSize,colorboxSize).*orangeRGB(2), ...
            ones(colorboxSize,colorboxSize).*orangeRGB(3));
                
            end
            
            % present the color background with the object
            PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {-1},'practice');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {-1},'practice')
            PTBDisplayPictures(practicetrials(itrial), {[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {1}, {StimDur},'practice');
            PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {-1},'practice');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {ITI},'practice');
            PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {-1},'practice');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {-1},'practice');
            PTBSetTextColor([1 1 1])
            PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{FixDur});
            PTBSetTextColor([255 255 255])
        end
        
        
        corr_colorbox = cat(3,ones(350,350).*purpleRGB(1), ...
            ones(350,350).*purpleRGB(2), ...
            ones(350,350).*purpleRGB(3));
        
        lure_colorbox = cat(3,ones(350,350).*orangeRGB(1), ...
            ones(350,350).*orangeRGB(2), ...
            ones(350,350).*orangeRGB(3));
        
        % item memory test
                
%         % source memory practice test
%         instr = {'Now, let''s try the practice test.','First, please indicate the color of the border that the item was studied with.', 'An item will appear on the screen with two different colors below it.','One of these two colors is the correct color that the item was studied with.','Please press the H key if you are sure it was the color on the left.','Please press the J key if you think it was the color on the left, but not sure.','Please press the L key if you are sure it was the color on the right.','Please press the K key if you think it was the color on the left, but not sure.','Press any key to start the practice color memory test.'};
%         PTBDisplayParagraph(instr,{'center',30},{'any'});
%         PTBDisplayBlank({2},'Blank');
%         
%         while pfnum <= 6
%             
%             PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]},{-1},'practice');
%             PTBDisplayMatrices({corr_colorbox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.75]},{-1},'practice');
%             PTBDisplayMatrices({lure_colorbox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.75]}, {-1},'practice');
%             
%             PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.95]},{-1});
%             PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.95]},{-1});
%             PTBDisplayPictures(practicefile(pfnum+1),{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]}, {1}, {'any'},'practice');
%             PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]},{1.5},'practice');
%             
%             pfnum = pfnum + 3
%             
%         end
        
        % temporal order memory test
        instr = {'Now, you''ll try the practice temporal order test.','You will be asked: ''Which object appeared first?''','Please press the H key if you are sure it was the object on the left.','Please press the J key if you think it was the object on the left, but not sure.','Please press the L key if you are sure it was the object on the right.','Please press the K key if you think it was the object on the left, but not sure.','Press any key to start the practice test.'};
        PTBDisplayParagraph(instr,{'center',30},{'any'});
        PTBDisplayBlank({2},'Blank');

        testTrials1 = [2 8];
        testTrials2 = [6 12];
        
        for itrial = 1:2
            PTBDisplayText('Which object appeared first?',{[PTBScreenRes.width*.35 PTBScreenRes.height*.2]},{-1});
            PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.7]},{-1});
            PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.7]},{-1});
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]},{-1},'practice');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]},{-1},'practice');
            PTBDisplayPictures(practicetrials(testTrials1(itrial)),{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]}, {1}, {-1},'practice');
            PTBDisplayPictures(practicetrials(testTrials2(itrial)),{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]}, {1}, {'any'},'practice')
            PTBDisplayBlank({2},'Blank');
          
        end
        
        instr = {'Any questions?  If so, please ask your experimenter at this time.','If not, please notify your experimenter that you understand the task and are ready to start!'};
        PTBDisplayParagraph(instr,{'center',30},{'any'});
        PTBDisplayBlank({2},'Blank');
    else
    end
    
    %% real experiment
    
    % display instructions
    if iBlock == 1;
    instr = {'You have reached the start of the fist study phase of the experiment.','A series of objects will appear three times.','For each object, please judge whether the object/color combination','is pleasing to you. Try to remember the color of the background for each object','and the order that the objects appear in. Press any key to proceed.', 'Remember to make a story linking the objects!'};
    PTBDisplayParagraph(instr,{'center',30},{'any'});
    end
    if iBlock>1;
    instr = {'You have next study phase. Press any key to continue.'};
    PTBDisplayParagraph(instr,{'center',30},{'any'});
    PTBDisplayBlank({2},'Blank');
    end
    
    %Short Delay
    PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{2});
    
    % repeate the presentation of items three times (original experiment)
%      for irep = 1:3
    
    %%% loop through encoding trials %%%
    for iTrial = 1:length(encodingList.eventNum)
        
        % create the color box
        if encodingList.eventCol(iTrial)==1
            currcolorbox = cat(3,ones(colorboxSize,colorboxSize).*purpleRGB(1), ...
            ones(colorboxSize,colorboxSize).*purpleRGB(2), ...
            ones(colorboxSize,colorboxSize).*purpleRGB(3));
        else
            currcolorbox = cat(3,ones(colorboxSize,colorboxSize).*orangeRGB(1), ...
            ones(colorboxSize,colorboxSize).*orangeRGB(2), ...
            ones(colorboxSize,colorboxSize).*orangeRGB(3));
        end
        
        % display color and white boxes, but use different trigger if a
        % color switch trial

        PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'color',100);
        PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'white')
        
        % display the item
        PTBDisplayPictures({[num2str(encodingList.eventItm(iTrial)) '.jpg']}, {[PTBScreenRes.width*.5 PTBScreenRes.height*.33]}, {1}, {StimDur}, 'Encoding Picture');
        trialOnset = GetSecs;
        respTime = [];
        RT= [];
        resp = [];
        
        %get response - we are going to collect responses during encoding
        %to ensure that the subjects included in analysis are engaging in
        %the task appropriately.
        while GetSecs - trialOnset < StimDur
            
            
            [keyIsDown,TimeSecs,keyCode] = KbCheck;
            
            if keyIsDown
                
                if sum(keyCode)==1
                    
                    resp = KbName(keyCode);
                else
                    resp = 'm';
                end
                respTime = TimeSecs;
                RT = TimeSecs - trialOnset;
                clear keyIsDown
            end
            
        end
        
        
        % redraw the color border
        PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'color',100);
        PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'white');
        
        % display the ITI
        PTBDisplayText(' ',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{ITI});
        ITIOnset = GetSecs;
        
        while GetSecs - ITIOnset < ITI
            
            [keyIsDown,TimeSecs,keyCode] = KbCheck;
            
            if keyIsDown
                
                resp = KbName(keyCode);
                respTime = TimeSecs;
                RT = TimeSecs - trialOnset;
                clear keyIsDown
            end
            
        end
        
        
        PTBDisplayMatrices({currcolorbox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'color',100);
        PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{-1},'white');
        PTBSetTextColor([1 1 1])
        PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{FixDur});
        PTBSetTextColor([255 255 255])
        
        %write out encoding data after every trial
        
        encodingDataFile{iTrial+1,1} = subjectNumber; % the subject number
%         encodingDataFile{iTrial+1,2} = imdel; % immediate or delayed test was given (1 = immediate test; 2 = delayed test)
        encodingDataFile{iTrial+1,3} = iBlock; % block number
        encodingDataFile{iTrial+1,4} = encodingList.eventNum(iTrial); % this is the event number in the ith trial
        encodingDataFile{iTrial+1,5} = encodingList.eventCol(iTrial); % this is the color id for the ith trial (purple = 1; orange = 2)
        encodingDataFile{iTrial+1,6} = encodingList.eventPos(iTrial); % within event position for the ith trial
        encodingDataFile{iTrial+1,7} = encodingList.eventItm(iTrial); % object id for the ith trial
        encodingDataFile{iTrial+1,8} = encodingList.eventTOW(iTrial); % within event temporal order test (0 = no test; 1 = first object; 2 = second object)
        encodingDataFile{iTrial+1,9} = encodingList.eventTOA(iTrial); % across boundary temporal order test (")
        encodingDataFile{iTrial+1,10} = encodingList.eventPrA(iTrial); % forward object priming test pairs (0 = no test; 1 = first object; 2 = second object)
        encodingDataFile{iTrial+1,11} = encodingList.eventPrF(iTrial);
        encodingDataFile{iTrial+1,12} = encodingList.eventPrR(iTrial);
        encodingDataFile{iTrial+1,13} = trialOnset; % this is when the trial started
        encodingDataFile{iTrial+1,14} = respTime; % this is when the subject responded
        encodingDataFile{iTrial+1,15} = RT; % this is the time between when the trial started and when the subject responded
        encodingDataFile{iTrial+1,16} = resp; % this is how the subject responded
       
    
        save([subdir '/encodingDataFileSub' subjStr 'Block' num2str(iBlock) 'rep' num2str(irep) '.mat'],'encodingDataFile')
        
        %reset write out encoding data variables
        trialOnset = [];
        respTime = [];
        RT = [];
        keyCode = [];
        resp =[];
    end % iTrial
        endevent = {' '}; % inserts a brief blank window period between repitions of the block to make clear when the list is repeating so that subjects can correctly answer which item appeared first in the list.
        PTBDisplayParagraph(endevent,{'center',30},{2.5});
        
% (ending line for irep = 1:3 in original experiment with repetitions)    
% end
    
    %End of encoding stuff
    endblock = {'You have reached the end of the study phase for this block.', 'Get ready for the test phase.', 'Hit any key to proceed.'};
    PTBDisplayParagraph(endblock,{'center',30},{'any'});
    
    %Short Delay
    PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{2});
    
    sourceblock = {'Temporal Order Memory Test.','Please indicate which object appeared first.','Remember to use all 4 buttons!'};
    PTBDisplayParagraph(sourceblock,{'center',30},{2});
    
    %% loop through test trials %%%
    
    
    for iTrial = 1:3
        if iTrial==1 | iTrial==3
        %reset write out test data variables
        trialOnset = [];
        respTime = [];
        RT = [];
        keyCode = [];
        resp =[];
        
        trial1 = [num2str(testList.TempOrder.eventItm(iTrial)) '.jpg'];
        
        trial2 = [num2str(testList.TempOrder.eventItm(iTrial+1)) '.jpg'];
        
        correctResp = round(rand);
        
        % display test images
        if correctResp==0
            PTBDisplayText('Which object appeared first?',{[PTBScreenRes.width*.35 PTBScreenRes.height*.2]},{-1});
            PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.7]},{-1});
            PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.7]},{-1});
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]},{-1},'white');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]},{-1},'white');
            PTBDisplayPictures({trial1},{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]}, {1}, {-1},'Test TO');
            PTBDisplayPictures({trial2},{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]}, {1}, {TestDur}, 'Test TO')
            
        elseif correctResp==1
            PTBDisplayText('Which object appeared first?',{[PTBScreenRes.width*.35 PTBScreenRes.height*.2]},{-1});
            PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.7]},{-1});
            PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.7]},{-1});
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]},{-1},'white');
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]},{-1},'white');
            PTBDisplayPictures({trial1},{[PTBScreenRes.width*.75 PTBScreenRes.height*.5]}, {1}, {-1},'Test TO');
            PTBDisplayPictures({trial2},{[PTBScreenRes.width*.25 PTBScreenRes.height*.5]}, {1}, {TestDur}, 'Test TO')
            
        end
        
        trialOnset = GetSecs;
        
        %get responses
        while TestLoop
            
            [keyIsDown,TimeSecs,keyCode] = KbCheck;
            
            if keyIsDown
                
                resp = KbName(keyCode);
                respTime = TimeSecs;
                RT = TimeSecs - trialOnset;
                clear keyIsDown
                break
            end
            
        end
        if iTrial ==1||iTrial==3
        orderTestDataFile{iTrial+1,1} = subjectNumber; % the subject number
%         orderTestDataFile{iTrial+1,2} = imdel; % immediate or delayed test was given (1 = immediate test; 2 = delayed test)
        orderTestDataFile{iTrial+1,3} = iBlock; % block number
        orderTestDataFile{iTrial+1,4} = testList.TempOrder.eventNum(iTrial); % this is the event number in the ith trial
        orderTestDataFile{iTrial+1,5} = testList.TempOrder.eventCol(iTrial); % this is the color id for the ith trial (purple = 1; orange = 2)
        orderTestDataFile{iTrial+1,6} = testList.TempOrder.eventPos(iTrial); % within event position for the ith trial
        orderTestDataFile{iTrial+1,7} = testList.TempOrder.eventItm(iTrial); % object id for the ith trial
        orderTestDataFile{iTrial+1,8} = testList.TempOrder.eventItm(iTrial+1); % object id for the ith trial
        orderTestDataFile{iTrial+1,9} = testList.TempOrder.eventWth(iTrial); % within event temporal order test (0 = no test; 1 = first object; 2 = second object)
        orderTestDataFile{iTrial+1,10} = testList.TempOrder.eventAcr(iTrial); % across boundary temporal order test (")
        orderTestDataFile{iTrial+1,11} = trialOnset; % this is when the trial started
        orderTestDataFile{iTrial+1,12} = respTime; % this is when the subject responded
        orderTestDataFile{iTrial+1,13} = RT; % this is the time between when the trial started and when the subject responded
        orderTestDataFile{iTrial+1,14} = resp; % this is how the subject responded
        orderTestDataFile{iTrial+1,15} = correctResp; % this is how the subject responded
        end
        

        %reset write out test data variables
        trialOnset = [];
        respTime = [];
        RT = [];
        keyCode = [];
        resp =[];
        
        PTBDisplayText('+',{'center'},{FixDur});
        
        
        end
        
        
        
    end % iTrial
    
    save([subdir '/orderTestDataFileSub' subjStr 'Block' num2str(iBlock) '.mat'],'orderTestDataFile')

    %     %Feedback!!!
    
    load([subdir '/orderTestDataFileSub' subjStr 'Block' num2str(iBlock) '.mat']);
    testAcc=[];
    if length(orderTestDataFile{2,14})>1
        orderTestDataFile{2,14}=orderTestDataFile{2,14}(1);
    end     
    
    if ((strcmp('h',orderTestDataFile{2,14})||strcmp('j',orderTestDataFile{2,14}))&&(orderTestDataFile{2,15}==0))||...
            ((strcmp('k',orderTestDataFile{2,14})||strcmp('l',orderTestDataFile{2,14}))&&(orderTestDataFile{2,15}==1))
        testAcc(1) = 1;
    else
        testAcc(1)=0;
    end
    
    if length(orderTestDataFile{4,14})>1
        orderTestDataFile{4,14}=orderTestDataFile{4,14}(1);
    end   
    
    if ((strcmp('h',orderTestDataFile{4,14})||strcmp('j',orderTestDataFile{4,14}))&&(orderTestDataFile{4,15}==0))||...
            ((strcmp('k',orderTestDataFile{4,14})||strcmp('l',orderTestDataFile{4,14}))&&(orderTestDataFile{4,15}==1))
        testAcc(2) = 1;
    else
        testAcc(2)=0;
    end
    
    if mean(testAcc)==1
        endblock = {'You got both right!','Great Job!'};
        PTBDisplayParagraph(endblock,{'center',30},{2});
    elseif mean(testAcc)==.5
        endblock = {'You got 1 out of 2 correct.','Good.'};
        PTBDisplayParagraph(endblock,{'center',30},{2});
    else
        endblock = {'You got 0 out of 2 correct.'};
        PTBDisplayParagraph(endblock,{'center',30},{2});
    end
        
    if iBlock <10
    blocknum = [num2str(iBlock) '/10'];
    endblock = {'You have reached the end of study block' blocknum, 'Press any key to continue.'};
    PTBDisplayParagraph(endblock,{'center',30},{'any'});
    end
    if iBlock==10
    endblock = {'You have reached the end of the study phase.', 'Please inform the experimenter.'};
    PTBDisplayParagraph(endblock,{'center',30},{'any'});
    end
    
    
    
catch
    PTBHandleError;
end



return