% function [] = repatime_wrapper_repeat_Final(SubjectNumber,imdel)
% original repeat lists version
function [] = repatime_wrapper_single_Final(SubjectNumber)

addpath scripts/PTBWrapper/
%addpath(genpath('/Volumes/davachilab/MEGbound/Psychtoolbox'))
blocks = 1:10; % changed due to error messages that said the index in the block script was out of matrix dimensions and that there are not enough blocks being referenced
isMEG = 0;
is_debugging = 0;
use_eyetracker = 0;

% imdel=2;
% remove the imdel component that was orignially to separate the two
% testing days in original repeat version of study

for iBlock = blocks
    
%     repatime_block_repeat_Final(SubjectNumber,imdel,blocks(iBlock),isMEG,is_debugging,use_eyetracker)
%     original repeat version
    repatime_block_repeat_Final(SubjectNumber,blocks(iBlock),isMEG,is_debugging,use_eyetracker)
    PTBCleanupExperiment;
    fclose('all');
    sca;
    
end

sca; ShowCursor;

return