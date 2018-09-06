% this script loads in a log file from the fivePokeBox and plots some
% relevant behavioral parameters



% % for testing
% clear all
% clc
% fname = '/home/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior/fivePokeTest_2017-09-27_T165259.txt';
% fname = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior/D1R83-4_2017-09-29_T174045.txt';


%% start of actual function
if strcmpi(computer, 'MACI64')
   basedir = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior';
else
   basedir = 'C:\Users\Luke\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior';
end
cd(basedir);

fname = uigetfile('*.txt', 'Choose behavior log file to open');



%% load in trial info from text file
lastPos = 0;
idx = 1;
while 1
   
   % extract the event names, etc. from text file
   [trialStr, lastPos] = extractTrial_v2(fname, lastPos);
   
   if isempty(trialStr)
      break % break out of the while loop
   end
   
   % convert event names into a struct array that contains only the
   % relevant info
   trialInfo(idx) = analyzeTrialStr1(trialStr);
   idx = idx + 1;
   
end

%% plot latency to nose poke
close all
f1 = figure;
a1 = subplot(2, 2, 1); % upper left
trialNums = [trialInfo.trialNum];

a1.XLabel.String = 'Trial number';
a1.YLabel.String = 'Latency to init poke (sec.)';
a1.XLim = [min(trialNums) max(trialNums)];
hold on

for idx = 1:length(trialInfo)
   if ~isempty(trialInfo(idx).latency_to_init)
      p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).latency_to_init); hold on
      p1.FaceColor = [0 0 0]; % red, green, blue
   end
   
end

t1 = title(fname);
t1.Interpreter = 'none';



% plot nose poke duration
a2 = subplot(2, 2, 3); % lower left
a2.XLabel.String = 'Trial number';
a2.YLabel.String = 'Nose poke duration (sec.)';
a2.XLim = [min(trialNums) max(trialNums)];
hold on

for idx = 1:length(trialInfo)
   if ~isempty(trialInfo(idx).latency_to_init)
      p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).init_poke_length); hold on
      p1.FaceColor = [0 0 0]; % red, green, blue
   end
end


% plot responses to left cues: correct, error, and missed
a3 = subplot(2, 2, 2); % upper right
maxOutcome2Length = 1;
a3.XLabel.String = 'Trial number';
a3.YLabel.String = 'Time to nosepoke (sec.)';
a3.XLim = [min(trialNums) max(trialNums)];
hold on

t1 = title('Left trials, green = correct, red = error, blue = missed');

for idx = 1:length(trialInfo)
   if trialInfo(idx).outcome2Time > maxOutcome2Length
      maxOutcome2Length = trialInfo(idx).outcome2Time;
   end
   if strcmpi(trialInfo(idx).cuedSide, 'left')
      if strcmpi(trialInfo(idx).outcome2, 'correct')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [0 1 0]; % red, green, blue
         p1.EdgeAlpha = 0;
      elseif strcmpi(trialInfo(idx).outcome2, 'ErrorPoke')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [1 0 0];
         p1.EdgeAlpha = 0;
      elseif strcmpi(trialInfo(idx).outcome2, 'miss')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [0 0 1];
         p1.EdgeAlpha = 0;
      % another outcome is "center" - I haven't dealt with that yet
      end
   end
end


a3.YLim = [0 maxOutcome2Length];

% plot correct and incorrect responses to right cues
a4 = subplot(2, 2, 4); % lower right
a4.XLabel.String = 'Trial number';
a4.YLabel.String = 'Time to nosepoke (sec.)';
a4.XLim = [min(trialNums) max(trialNums)];
hold on

for idx = 1:length(trialInfo)
   if trialInfo(idx).outcome2Time > maxOutcome2Length
      maxOutcome2Length = trialInfo(idx).outcome2Time;
   end
   if strcmpi(trialInfo(idx).cuedSide, 'right')
      if strcmpi(trialInfo(idx).outcome2, 'correct')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [0 1 0]; % red, green, blue
         p1.EdgeAlpha = 0;
      elseif strcmpi(trialInfo(idx).outcome2, 'ErrorPoke')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [1 0 0];
         p1.EdgeAlpha = 0;
      elseif strcmpi(trialInfo(idx).outcome2, 'miss')
         p1 = bar(trialInfo(idx).trialNum, trialInfo(idx).outcome2Time);
         p1.FaceColor = [0 0 1];
         p1.EdgeAlpha = 0;
      end
   end
end

a4.YLim = [0 maxOutcome2Length];
t1 = title('Right trials, green = correct, red = error, blue = missed');






