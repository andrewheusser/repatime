%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: PTBSendTrigger.m
%
% NOTE: Internal function. DO NOT CALL.
%
% Sends a trigger to the USBBox.
%
% Args:
%	- value: 0-255 trigger values to send
%   - trigger_delay: The delays to use for each trigger.
%
% Usage: PTBSendTrigger(30)
%
% Author: Doug Bemis
% Date: 2/3/10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PTBSendTrigger(triggers, triggers_delay)

% Check
global PTBUSBBoxInitialized;
if ~PTBUSBBoxInitialized
	disp('WARNING: No trigger sent.');
	return;
end

% Send the triggers
global PTBUSBBoxDeviceID;
global PTBTriggerLength;
global PTBEyeTrackerRecording;

% Schedule the triggers
curr_time = GetSecs;
for i = length(triggers_delay):-1:1
    triggers_delay(i) = triggers_delay(i) + sum(triggers_delay(1:i-1)) + curr_time;
end

% Account for the trigger length for any triggers after the first
% triggers_delay = triggers_delay - PTBTriggerLength;
% triggers_delay(1) = triggers_delay(1) + PTBTriggerLength;
for i = 1:length(triggers)

    % Sometimes need to delay, because it gets there before the screen
    while GetSecs < triggers_delay(i)
    end

    % Send the trigger
    trig_time = GetSecs;
    PsychHID('SetReport', PTBUSBBoxDeviceID, 2, hex2dec('32'), uint8(zeros(1,2)+triggers(i)));
	
	% If we're recording eye-tracking data, assume we want to send here as well.
	% TODO: What values can we send, and how?
	if PTBEyeTrackerRecording
        
        % Check recording status, stop display if error
        status = Eyelink('CheckRecording');
        disp(['Got status ' num2str(status) ' for command for check recording.']);
        if status ~= 0
            error('Eyetracker stopped recording.');
        end
        
        % If good, then send
		status = Eyelink('Message','MEG Trigger: %i', triggers(i));
        disp(['Got status ' num2str(status) ' for command for message.']);
        if status ~= 0
            error('Could not send message.');
        end
	end
	
    pause(PTBTriggerLength);
    PsychHID('SetReport', PTBUSBBoxDeviceID, 2, hex2dec('32'), uint8(zeros(1,2)));
end

% Want to record
global PTBLogFileID;
PTBWriteLog(PTBLogFileID, 'TRIGGER', 'USBBox', num2str(triggers), trig_time);	
if PTBEyeTrackerRecording
	PTBWriteLog(PTBLogFileID, 'TRIGGER', 'EyeLink', num2str(triggers), trig_time);	
end
    