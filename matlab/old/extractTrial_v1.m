function [trialStr, lastPos] = extractTrial_v1(fname, lastPos)

% function [trialStr, lastPos] = extractTrial_v1(fname, lastPos)
%
% function to extract a trial from an arduino log file. lastPos is the
% position in the file where the last trial ended. This function looks for
% a trial starting with "TrialAvailable" and ending with "Standby". If
% there is no complete trial found, it will return an empty trialStr. The
% lastPos that is returned will be updated only if a trial is successfully
% extracted.
%
% Luke Sjulson, 2017-09-25


% % for testing
% clear all
% fname = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior/D1R77-4_2017-09-20/D1R77-4_2017-09-20_T150219.txt';
% lastPos = 0;

if nargin < 2
   lastPos = 0;
end


%% 
fid = fopen(fname, 'rt'); % open file pointer
fseek(fid, lastPos, 'bof'); % position pointer to the position from last time

trialStartFound = 0;
trialEndFound = 0;

trialStr.timevec = [];
trialStr.trialNum = [];
trialStr.eventType = {};
idx = 2;

% look for TrialAvailable
while ~feof(fid)
   C = textscan(fid, '%f;%f;%s', 1); % read in one line
   if strfind(C{3}{1}, 'TrialAvailable')
      trialStartFound = 1;
      trialStr.timevec(1) = C{1};
      trialStr.trialNum(1) = C{2};
      trialStr.eventType{1} = C{3}{1};
      break
   end
end

% if TrialAvailable found, look for Standby (end of trial)
if trialStartFound==1
   while ~feof(fid)
      C = textscan(fid, '%f;%f;%s', 1); % read in one line
      trialStr.timevec(idx) = C{1};
      trialStr.trialNum(idx) = C{2};
      trialStr.eventType{idx} = C{3}{1};
      idx = idx + 1;
      if strfind(C{3}{1}, 'Standby')
         trialEndFound = 1;
         break
      end
      
   end
end

if sum(diff(trialStr.trialNum)) > 0
   warning('multiple trial numbers between TrialAvailable and Standby; skipping');
   trialStr = [];
   fclose(fid);
   return
end

if trialEndFound==0 % unsuccessful extraction of a trial
   trialStr = [];
else % trial extracted successfully
   lastPos = ftell(fid);
   trialStr.timevec = trialStr.timevec ./ 1000;
end



fclose(fid);






