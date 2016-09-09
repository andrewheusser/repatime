%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: PTBCleanupExperiment.m
%
% Does the cleanup for a PTBExperiment. Call this
% if the screen is still up and you don't want it to be.
%
% Args:
%
% Usage: PTBCleanupExperiment
%
% Author: Doug Bemis
% Date: 7/3/09
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PTBCleanupExperiment

return
% Make sure the last screen stays up for the desired time,
% if there is one.
PTBDisplayBlank({.1},'Final Screen.');

% Write the keystrokes, if necessary
global PTBKeyFileName;
if ischar(PTBKeyFileName)
	PTBLogKeyStrokes;
end

% Shutdown the sound
PTBShutDownSound;

% Save any sound
PTBSaveSoundKeyData;

% Shutdown the eyetracker
PTBCloseEyeTracker;

% Clear the screen.
global PTBNextPresentationTime;
global PTBVisualStimulus;
global PTBAudioStimulus;
global PTBEventQueue;
global PTBKeyQueue;
global PTBWaitingForKey;
global PTBInputCollection;
if ~isempty(Screen('Windows'))
	
	% And clear
	PTBEventQueue = {};
	PTBKeyQueue = {};
    if strcmp(PTBInputCollection, 'Queue')
        KbQueueRelease;
    end
	if PTBNextPresentationTime - GetSecs > 1000
		PTBNextPresentationTime = 0;
	end
	PTBVisualStimulus = 1;
	PTBAudioStimulus = 0;
	PTBSetLogAppend(0,'clear',{});
    PTBWaitingForKey = 0;
    PTBPresentStimulus({0},'Cleanup', '',[],[],'');
end

% Restore preferences
global PTBOldVisualDebugLevel;
global PTBOldSupressAllWarnings;
if ~isempty(PTBOldVisualDebugLevel)
	Screen('Preference', 'VisualDebugLevel', PTBOldVisualDebugLevel);
	Screen('Preference', 'SuppressAllWarnings', PTBOldSupressAllWarnings);
end

% TODO: Look into garbage collection here.
global PTBCurrComputerSpecs;
if ~isempty(PTBCurrComputerSpecs)
	if PTBCurrComputerSpecs.osx
		KbQueueRelease;
	end
end
Priority(0);
ListenChar(0);
ShowCursor
Screen('CloseAll');
fclose('all');
clear all;

