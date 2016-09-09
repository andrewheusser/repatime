function [] = repatime_priming_single_Final(subjectNumber,iBlock,isMEG,is_debugging,use_eyetracker)
% repatime is an experiment based off of MEGbound where we test how
% boundaries influence various measures of memory at a delay and with
% repetition
addpath scripts/PTBWrapper/

%% create subject directory

if subjectNumber < 10
    subjStr = ['0' num2str(subjectNumber)];
else
    subjStr = num2str(subjectNumber);
end

%% set experiment paths

basedir = pwd; % home directory that we are in when script is running
listdir = [basedir '/lists/']; % where we store the encoding lists (e.g. for each subject)
imagedir = [basedir '/repatimeStimuli_resized/']; addpath(genpath(imagedir)); % where all of the item pictures are stored
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
    StimDur = 2.5;
    ITI = 1.0;
    FixDur = 1.5;
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
    PTBSetupExperiment('Repatime Test 1'); % sets up some essentials to run a PTB experiment, name is less relevant
    
    %% load and format encoding and test stimuli
    % go to encoding directory and load encoding sequence
    
    cbVersion = mod(subjectNumber,20);
    if cbVersion == 0
        cbVersion = 20;
    end
    
    %%  variables to be used in experiment loops
    colorboxSize = 600;
    whiteboxSize = 350;
    whitebox = 255.*ones(whiteboxSize,whiteboxSize,3); % generates the white box that item stimuli will be placed inside
    practicetrials = {'661.bmp'; '662.bmp'; '663.bmp'; '664.bmp'; '665.bmp'; '666.bmp'; '667.bmp'; '668.bmp'; '669.bmp'; '670.bmp'; '671.bmp'; '672.bmp'}; % items appearing during practice run
    pfnum = 1; % variable to indicate which practice file should be referenced in while loop
    %encodingSeq = ; % this needs to be the individual event sequence matrix for each subject
    %nTrials = length(encodingList.eventNum); % define the number of trials
    purpleRGB = [165 10 242];
    orangeRGB = [255 179 0];
    
    load([listdir 'primingTestAndLures_dec9.mat'])
    
    primingTest.eventItm = primingTestAndLures.sub{cbVersion}(:,1);
    primingTest.eventNum = primingTestAndLures.sub{cbVersion}(:,2);
    primingTest.eventCol = primingTestAndLures.sub{cbVersion}(:,3);
    primingTest.eventPos = primingTestAndLures.sub{cbVersion}(:,4);
    primingTest.eventPrA = primingTestAndLures.sub{cbVersion}(:,5);
    primingTest.eventPrF = primingTestAndLures.sub{cbVersion}(:,6);
    primingTest.eventPrR = primingTestAndLures.sub{cbVersion}(:,7);
    
    %initiate event output data
    primingTestDataFile = cell(length(primingTest.eventItm)+1,16);
    primingTestDataFile{1,1} = 'Subject_Number';
    primingTestDataFile{1,2} = 'Immediate_OR_Delay';
    primingTestDataFile{1,3} = 'Block_Number';
    primingTestDataFile{1,4} = 'Event_Number';
    primingTestDataFile{1,5} = 'Event_Color';
    primingTestDataFile{1,6} = 'WithinEvent_Position';
    primingTestDataFile{1,7} = 'Object_ID';
    primingTestDataFile{1,10}= 'AcrossBound_ObjPriming_Forward';
    primingTestDataFile{1,11}= 'WithinEvent_ObjPriming_Forward';
    primingTestDataFile{1,12}= 'WithinEvent_ObjPriming_Reverse';
    primingTestDataFile{1,13}= 'Trial_Onset'; % when the trial started
    primingTestDataFile{1,14}= 'Response_Time'; % when the response was made
    primingTestDataFile{1,15}= 'Reaction_Time'; % reaction time is response time - trial onset
    primingTestDataFile{1,16} = 'Response'; % this is when the trial started
    
    %% real experiment
    
    % display instructions
    instr = {'You have now reached the object memory test.', 'You will be asked: ''Is the item old or new?''', 'Please press the H key if you are sure the object was shown before (OLD SURE).','Press the J key if you think the the object was shown before, but are',' not sure (OLD UNSURE). Please press the L key if you are sure the object is new,',' and was not shown before (NEW SURE). Please press the K key if you think the object',' was not shown before, but are unsure (NEW UNSURE). Press any key to continue.'};
    PTBDisplayParagraph(instr,{'center',30},{'any'});
    PTBDisplayBlank({2},'Blank');
    
    %Short Delay
    PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{2});
    
    %%% loop through encoding trials %%%
    for iTrial = 1:length(primingTest.eventItm)
        %reset write out test data variables
        trialOnset = [];
        respTime = [];
        RT = [];
        keyCode = [];
        resp =[];
       
        % display the item
        
        
        PTBDisplayText('H - OLD SURE     J - OLD UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.95]},{-1});
        PTBDisplayText('K - NEW UNSURE     L - NEW SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.95]},{-1});
        PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]},{-1},'white');
        trialOnset = GetSecs;
        PTBDisplayPictures({[num2str(primingTest.eventItm(iTrial)) '.jpg']},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]}, {1}, {'any'},'Test TO');
        
        
        %get response - we are going to collect responses during encoding
        %to ensure that the subjects included in analysis are engaging in
        %the task appropriately.

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
        
        
        
        primingTestDataFile{iTrial+1,1} = subjectNumber; % the subject number
%         primingTestDataFile{iTrial+1,2} = imdel; % immediate or delayed test was given (1 = immediate test; 2 = delayed test)
        primingTestDataFile{iTrial+1,3} = iBlock; % block number
        primingTestDataFile{iTrial+1,4} = primingTest.eventNum(iTrial); % this is the event number in the ith trial
        primingTestDataFile{iTrial+1,5} = primingTest.eventCol(iTrial); % this is the color id for the ith trial (purple = 1; orange = 2)
        primingTestDataFile{iTrial+1,6} = primingTest.eventPos(iTrial); % within event position for the ith trial
        primingTestDataFile{iTrial+1,7} = primingTest.eventItm(iTrial); % object id for the ith trial
        primingTestDataFile{iTrial+1,10} = primingTest.eventPrA(iTrial); % forward object priming test pairs (0 = no test; 1 = first object; 2 = second object)
        primingTestDataFile{iTrial+1,11} = primingTest.eventPrF(iTrial);
        primingTestDataFile{iTrial+1,12} = primingTest.eventPrR(iTrial);
        primingTestDataFile{iTrial+1,13} = trialOnset; % this is when the trial started
        primingTestDataFile{iTrial+1,14} = respTime; % this is when the subject responded
        primingTestDataFile{iTrial+1,15} = RT; % this is the time between when the trial started and when the subject responded
        primingTestDataFile{iTrial+1,16} = resp; % this is how the subject responded
        
        
        save([subdir '/primingTestDataFileSub' subjStr '.mat'],'primingTestDataFile')
        PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{.25});
        
        
        
    end % iTrial
    
    
  
    endblock = {'You have reached the end of this memory test.' , 'Please inform the experimenter.'};
    PTBDisplayParagraph(endblock,{'center',30},{'any'});
    
    
    
catch
    PTBHandleError;
end

    PTBCleanupExperiment;
    fclose('all');
    sca;

return

