function [] = repatime_color_single_Final(subjectNumber,isMEG,is_debugging,use_eyetracker)
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
    colorboxSize = 450;
    whiteboxSize = 350;
    whitebox = 255.*ones(whiteboxSize,whiteboxSize,3); % generates the white box that item stimuli will be placed inside
    purpleRGB = [165 10 242];
    orangeRGB = [255 179 0];
    
    load([listdir 'primingTestAndLures_dec9.mat'])
    
    primingTestAndLures.sub{cbVersion}(primingTestAndLures.sub{cbVersion}(:,2)==0,:)=[];
    
    colorTest.eventItm = primingTestAndLures.sub{cbVersion}(:,1);
    colorTest.eventNum = primingTestAndLures.sub{cbVersion}(:,2);
    colorTest.eventCol = primingTestAndLures.sub{cbVersion}(:,3);
    colorTest.eventPos = primingTestAndLures.sub{cbVersion}(:,4);
    colorTest.eventPrA = primingTestAndLures.sub{cbVersion}(:,5);
    colorTest.eventPrF = primingTestAndLures.sub{cbVersion}(:,6);
    colorTest.eventPrR = primingTestAndLures.sub{cbVersion}(:,7);
    
    %initiate event output data
    colorTestDataFile = cell(length(colorTest.eventItm)+1,17);
    colorTestDataFile{1,1} = 'Subject_Number';
    colorTestDataFile{1,2} = 'Immediate_OR_Delay';
    colorTestDataFile{1,3} = 'Block_Number';
    colorTestDataFile{1,4} = 'Event_Number';
    colorTestDataFile{1,5} = 'Event_Color';
    colorTestDataFile{1,6} = 'WithinEvent_Position';
    colorTestDataFile{1,7} = 'Object_ID';
    colorTestDataFile{1,8}= 'AcrossBound_ObjPriming_Forward';
    colorTestDataFile{1,9}= 'WithinEvent_ObjPriming_Forward';
    colorTestDataFile{1,10}= 'WithinEvent_ObjPriming_Reverse';
    colorTestDataFile{1,11}= 'Trial_Onset'; % when the trial started
    colorTestDataFile{1,12}= 'Response_Time'; % when the response was made
    colorTestDataFile{1,13}= 'Reaction_Time'; % reaction time is response time - trial onset
    colorTestDataFile{1,14} = 'Response'; % this is when the trial started
    colorTestDataFile{1,15} = 'Correct Response';
    
    %% real experiment
    
    % display instructions
    instr = {'You have reached the source memory test in this experiment.','For this test, you will be asked: ''In which color background did the object appear?''', 'If you are sure that the object appeared in the color background shown on the LEFT,','press the H key. If you think the object appeared in the color backgrounud on the LEFT,','but are unsure, press the J key. If you are sure the object appeared in the color','background on the RIGHT, press the L key. If you think the object appeared','in the color background on the RIGHT, but are unsure, press the K key.','Hit any key to start the test.'};
    PTBDisplayParagraph(instr,{'center',30},{'any'});
    PTBDisplayBlank({2},'Blank');
    
    %Short Delay
    PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{2});
    
    %%% loop through encoding trials %%%
    for iTrial = 1:length(colorTest.eventItm)
        
        %reset write out test data variables
        trialOnset = [];
        respTime = [];
        RT = [];
        keyCode = [];
        resp =[];
        
        trial = [num2str(colorTest.eventItm(iTrial)) '.jpg'];
        
        % NOTE: correct color box is flipped. The color code for purple in
        % repatime_block_repeat = 1. As a result, participants responding
        % to the lure_colorbox are actually correct. To fix this error,
        % make colorTest.eventCol(iTrial)==1.
        % commented on Jan 5, 2015 by JQL
        if colorTest.eventCol(iTrial)==2 % this was updated on dec 8 2015 so that the correct color box is based on the number (purple == 2; orange == 1) in column 3 (eventCol) of the test list matrix.
            
            corr_colorbox = cat(3,ones(colorboxSize,colorboxSize).*purpleRGB(1), ...
                ones(colorboxSize,colorboxSize).*purpleRGB(2), ...
                ones(colorboxSize,colorboxSize).*purpleRGB(3));
            
            lure_colorbox = cat(3,ones(colorboxSize,colorboxSize).*orangeRGB(1), ...
                ones(colorboxSize,colorboxSize).*orangeRGB(2), ...
                ones(colorboxSize,colorboxSize).*orangeRGB(3));
            
        else
            
            lure_colorbox = cat(3,ones(colorboxSize,colorboxSize).*purpleRGB(1), ...
                ones(colorboxSize,colorboxSize).*purpleRGB(2), ...
                ones(colorboxSize,colorboxSize).*purpleRGB(3));
            
            corr_colorbox = cat(3,ones(colorboxSize,colorboxSize).*orangeRGB(1), ...
                ones(colorboxSize,colorboxSize).*orangeRGB(2), ...
                ones(colorboxSize,colorboxSize).*orangeRGB(3));
            
        end
        
        correctResp = round(rand);
        
        if correctResp==0
            
            
            PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.95]},{-1});
            PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.95]},{-1});
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]},{-1},'white');
           
            PTBDisplayPictures({trial},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]}, {1}, {-1},'Test TO');
            
            PTBDisplayMatrices({corr_colorbox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.7]},{-1},'white');
            PTBDisplayMatrices({lure_colorbox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.7]},{TestDur},'white');
            
            
        else
            
            
            PTBDisplayText('H - LEFT SURE     J - LEFT UNSURE',{[PTBScreenRes.width*.05 PTBScreenRes.height*.95]},{-1});
            PTBDisplayText('K - RIGHT UNSURE     L - RIGHT SURE',{[PTBScreenRes.width*.55 PTBScreenRes.height*.95]},{-1});
            PTBDisplayMatrices({whitebox},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]},{-1},'white');
            
            PTBDisplayPictures({trial},{[PTBScreenRes.width*.5 PTBScreenRes.height*.25]}, {1}, {-1},'Test TO');
            
            PTBDisplayMatrices({corr_colorbox},{[PTBScreenRes.width*.75 PTBScreenRes.height*.7]},{-1},'white');
            PTBDisplayMatrices({lure_colorbox},{[PTBScreenRes.width*.25 PTBScreenRes.height*.7]},{TestDur},'white');
            
            
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
        
%         %this was added on dec 8 2015 to indicate whether or not the
%         %correct response was made by the partipant
%         correctResp = [];
%         if (correctRespPos==0 & (resp=='h'|resp=='j'))|(correctRespPos~=0 & (resp=='k'|resp=='l'))
%             correctResp=1;
%         else
%             correctResp=0;
%         end
        
        
            
            
        colorTestDataFile{iTrial+1,1} = subjectNumber; % the subject number
%         colorTestDataFile{iTrial+1,2} = 0;%imdel; % immediate or delayed test was given (1 = immediate test; 2 = delayed test)
        colorTestDataFile{iTrial+1,3} = 0;%iBlock; % block number
        colorTestDataFile{iTrial+1,4} = colorTest.eventNum(iTrial); % this is the event number in the ith trial
        colorTestDataFile{iTrial+1,5} = colorTest.eventCol(iTrial); % this is the color id for the ith trial (purple = 1; orange = 2)??
        colorTestDataFile{iTrial+1,6} = colorTest.eventPos(iTrial); % within event position for the ith trial
        colorTestDataFile{iTrial+1,7} = colorTest.eventItm(iTrial); % object id for the ith trial
        colorTestDataFile{iTrial+1,8} = colorTest.eventPrA(iTrial); % forward object priming test pairs (0 = no test; 1 = first object; 2 = second object)
        colorTestDataFile{iTrial+1,9} = colorTest.eventPrF(iTrial);
        colorTestDataFile{iTrial+1,10} = colorTest.eventPrR(iTrial);
        colorTestDataFile{iTrial+1,11} = trialOnset; % this is when the trial started
        colorTestDataFile{iTrial+1,12} = respTime; % this is when the subject responded
        colorTestDataFile{iTrial+1,13} = RT; % this is the time between when the trial started and when the subject responded
        colorTestDataFile{iTrial+1,14} = resp; % this is how the subject responded
        colorTestDataFile{iTrial+1,15} = correctResp; % this the side that the correct response was on
        
        save([subdir '/colorTestDataFileSub' subjStr '.mat'],'colorTestDataFile')
        PTBDisplayText('+',{[PTBScreenRes.width*.5 PTBScreenRes.height*.33]},{.5});
        
    end % iTrial
  
    endblock = {'You have reached the end of this memory test' , 'Press any key to continue.'};
    PTBDisplayParagraph(endblock,{'center',30},{'any'});
    
    
    
catch
    PTBHandleError;
end

    PTBCleanupExperiment;
    fclose('all');
    sca;

return

