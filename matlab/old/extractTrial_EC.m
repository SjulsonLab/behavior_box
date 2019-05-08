function [trialStr, lastPos] = extractTrial_v2(fname, lastPos)

% function [trialStr, lastPos] = extractTrial_v2(fname, lastPos)
%
% function to extract a trial from an arduino log file. lastPos is the
% position in the file where the last trial ended. This function looks for
% a trial starting with "TrialAvailable" and ending with "Standby". If
% there is no complete trial found, it will return an empty trialStr. The
% lastPos that is returned will be updated only if a trial is successfully
% extracted.
%
% Luke Sjulson, 2017-09-25
%
% v2 : same as before, except it uses the four-column format where the fourth
% column stores a number associated with the event.


% % % for testing
%clear all
%fname = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior\jaxMale03';
%nargin = 1;

% start of actual function
if nargin < 2
   lastPos = 0;
end


%%
fid = fopen(fname, 'rt'); % open file pointer
fseek(fid, lastPos, 'bof'); % position pointer to the position from last time

trialStartFound = 0;

trialStr.timevec = [];
trialStr.trialNum = [];
trialStr.eventType = {};
trialStr.eventNum = [];
idx = 2;

% look for TrialAvailable
while 1
   
   C = textscan(fid, '%f;%f;%s', 1); % read in one line.
   
   if feof(fid)
      warning('End of file reached');
      lastPos = ftell(fid);
      trialStr = [];
      fclose(fid);
      return
   end
   
   try 
       if strfind(C{3}{1}, 'TrialAvailable')
          trialStartFound = 1;

          % for some reason textscan can't parse this string correctly, so I have to do it manually
          tempStr = C{3}{1};
          kidx = min(find(tempStr==';'));
          tempNum = str2num(tempStr(kidx+1:end));
          tempStr = tempStr(1:kidx-1);

          trialStr.timevec(1) = C{1}; % time in ms
          trialStr.trialNum(1) = C{2}; % trial number
          trialStr.eventType{1} = tempStr; % event name
          trialStr.eventNum(1) = tempNum;  % number associated w the event
          break
       end
   end
end

% if TrialAvailable found, look for Standby (end of trial)
runLoop = 1;

if trialStartFound==1
   while runLoop == 1
      if ~feof(fid)
         C = textscan(fid, '%f;%f;%s', 1); % read in one line
         
         if ~isempty(C{3})
            % for some reason textscan can't parse this string correctly, so I have to do it manually
            tempStr = C{3}{1};
            kidx = min(find(tempStr==';'));
            tempNum = str2num(tempStr(kidx+1:end));
            tempStr = tempStr(1:kidx-1);
            trialStr.timevec(idx) = C{1};
            trialStr.trialNum(idx) = C{2};
            trialStr.eventType{idx} = tempStr;
            trialStr.eventNum(idx) = tempNum;
            
            % if trial number goes up without finding a "Standby" first
            if C{2} ~= trialStr.trialNum(idx-1)
               warning('Trial #%d did not have a Standby...skipping...');
               trialStr = [];
               lastPos = ftell(fid);
               fclose(fid);
               return
            end
            
            % if it finds a "Standby"
            if strfind(C{3}{1}, 'Standby')
               lastPos = ftell(fid);
               trialStr.trialNum = trialStr.trialNum(1);
               trialStr.timevec = trialStr.timevec ./ 1000;
               fclose(fid);
               return
            end
            idx = idx + 1;
         else runLoop = 0;
         end
      else runLoop = 0;
      end
   end
   
   % if it reaches the end of the file without finding a Standby
   warning('End of file reached with no Standby found');
   lastPos = ftell(fid);
   trialStr = [];
   fclose(fid);
   
end