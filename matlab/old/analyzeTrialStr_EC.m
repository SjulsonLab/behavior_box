function trialInfo = analyzeTrialStr1(trialStr)

% function trialInfo = analyzeTrialStr1(trialStr)
%
% This function takes a trialStr struct (the output of extractTrial_v2) and
% parses the events inside, then outputs a struct called trialInfo that contains
% info like trial number, correct/incorrect, relevant time delays, etc.
%
% Luke Sjulson, 2017-09-28


t.trialNum = trialStr.trialNum;


%% extract first outcome (init or pre-init miss)
if any(strcmpi(trialStr.eventType, 'TrialMissedBeforeInit'))
   t.outcome1 = 'miss';
elseif any(strcmpi(trialStr.eventType, 'TrialStarted'))
   t.outcome1 = 'init';
else
   warning('Unable to determine outcome 1');
   t.outcome1 = '???';
end

%% if trial initiated, extract latency to init poke
idx = find(strcmpi(trialStr.eventType, 'TrialStarted'), 1);
if isempty(idx)
   t.latency_to_init = [];
else
   t.latency_to_init = trialStr.eventNum(idx) / 1000;
end

%% extract init poke length
if isempty(t.latency_to_init)
   t.init_poke_length = [];
else
   idx = find(strcmpi(trialStr.eventType, 'initPokeExit'), 1);
   t.init_poke_length = trialStr.eventNum(idx) / 1000;
end

%% extract whether left or right side was cued
if any(strcmpi(trialStr.eventType, 'LeftCue'))
   t.cuedSide = 'left';
elseif any(strcmpi(trialStr.eventType, 'RightCue'))
   t.cuedSide = 'right';
else
   t.cuedSide = 'none';
end

%% extract whether it was an auditory or visual cue
if ~strcmpi(t.cuedSide, 'none')
   if any(strcmpi(trialStr.eventType, 'AuditoryCue'))
      t.cueType = 'auditory';
   elseif any(strcmpi(trialStr.eventType, 'VisualCue'))
      t.cueType = 'visual';
   else
      warning('Unable to determine cue type');
      t.cueType = '???';
   end
else % meaning neither side was cued
   t.cueType = 'none';
end


%% extract second outcome (correct, error, or post-init miss) and time delay
if isempty(t.latency_to_init)
   t.outcome2 = 'none';
   t.outcome2Time = [];
else
   if any(contains(trialStr.eventType, 'Withdrawal'))
      t.outcome2 = 'withdrawal';
      t.outcome2Time = t.init_poke_length;
   elseif any(strcmpi(trialStr.eventType, 'Correct'))
      t.outcome2 = 'correct';
      idx = find(strcmpi(trialStr.eventType, 'Correct'), 1);
      t.outcome2Time = trialStr.eventNum(idx) / 1000;
   elseif any(strcmpi(trialStr.eventType, 'ErrorPoke'))
      t.outcome2 = 'errorpoke';
      idx = find(strcmpi(trialStr.eventType, 'ErrorPoke'), 1);
      t.outcome2Time = trialStr.eventNum(idx) / 1000;
   elseif any(strcmpi(trialStr.eventType, 'TrialMissedAfterInit'))
      t.outcome2 = 'miss';
      idx = find(strcmpi(trialStr.eventType, 'TrialMissedAfterInit'), 1);
      t.outcome2Time = trialStr.eventNum(idx) / 1000;
   else
      warning('Unable to determine outcome 2');
      t.outcome2 = '???';
      t.outcome2Time = [];
   end
end


%% rename the struct
trialInfo = t;