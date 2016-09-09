%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: PTBSaveSoundKeyData.m
%
% Save any sound key data that was recorded during the experiment.
%
% Args:
%
% Usage: PTBSaveSoundKeyData
%
% Author: Doug Bemis
% Date: 4/23/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: Possibly allow changing during the experiment.
function PTBSaveSoundKeyData

global PTBSoundKeyData;
global PTBRecordAudio;
global PTBRecordAudioFileNames

% If we have none, get out of here
if isempty(PTBSoundKeyData)
	return;
end

% We're done recording...
if isempty(PTBRecordAudioFileNames)
    sound_file_name = 'No_Name';
else
    sound_file_name = PTBRecordAudioFileNames{1};
    PTBRecordAudioFileNames = {PTBRecordAudioFileNames{2:end}}; %#ok<CCAT1>
end
PTBRecordAudio = PTBRecordAudio(2:end,:);

% Otherwise, write it to the file.
% Name it by date to avoid overwriting
t = fix(clock);
file_name = '';
for i = 1:6
    file_name = [file_name num2str(t(i)) '_']; %#ok<AGROW>
end
file_name = [file_name sound_file_name '.wav'];
wavwrite(transpose(PTBSoundKeyData), 44100, 16, file_name);

% Clear the buffer
PTBSoundKeyData = [];

