function sessionStr = makeCues_v5(sessionStr, mouseStr, trialNums)

% function sessionStr = makeCue_v5(sessionStr, mouseStr, trialNums)
%
% Function to generate cue numbers to send to the arduino. The sessionStr
% must have fields:
%
% trialLRtype (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)
% trialAVtype (1 = aud only, 2 = vis only, 3 = aud+vis)
% cue1Length
% cue2Length
% interOnsetInterval (the time between onset of cue 1 and cue2)
%
% the mouseStr must have the fields:
%
% leftVisCue (0 = nothing, 1 = LEDs 1+2, 2 = LEDs 3+4, 3 = LEDs 1-4)
% leftAudCue (0 = nothing, 1 = low tone, 2 = high tone, 3 = buzzer, 4 = white noise)
% rightVisCue
% rightAudCue
%
% The fields added to sessionStr are: 
% cue1_vis, cue2_vis, cue3_vis, cue1_aud, cue2_aud, cue3_aud  - to give to arduino
% slot1Length, slot2Length, slot3Length  - also to give to arduino
%
% Luke Sjulson, 2018-10-19

% % for testing
% % clear all
% clc
% 
% % info from mouse struct
% mouseStr.leftVisCue  = 1;
% mouseStr.leftAudCue  = 0;
% mouseStr.rightVisCue = 0;
% mouseStr.rightAudCue = 3;
% 
% trialNums = [1 2 3 4 5 6];
% 
% % info about trial types
% sessionStr.trialLRtype  = [1 2 3 4 5 6]; % can be 1-6
% 
% % sessionStr.trialAVtype  = [3 2 1 2 1 3 1 2 1 1 3 3 2 1]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
% sessionStr.trialAVtype  = [3 3 3 3 3 3]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
% sessionStr.cue1Length     = [100 100 100 100 100 100];
% sessionStr.cue2Length     = [100 100 100 100 100 100];
% sessionStr.interOnsetInterval = [0 10 20 30 40 50]; % in stage 4, the interOnsetInterval increases gradually

%% start of actual function

for idx = 1:length(trialNums)
	nTrial = trialNums(idx);
	
	cue1_vis = 0;
	cue1_aud = 0;
	cue2_vis = 0;
	cue2_aud = 0;
	cue3_vis = 0;
	cue3_aud = 0;
	
	trialLRtype = sessionStr.trialLRtype(nTrial);
	trialAVtype = sessionStr.trialAVtype(nTrial);
	
	%% calculating lengths of slots
	slot1Length = min(sessionStr.cue1Length(nTrial), sessionStr.interOnsetInterval(nTrial));
	tempSlot = sessionStr.interOnsetInterval(nTrial) - sessionStr.cue1Length(nTrial);
	slot2Length = abs(tempSlot);
	
	if tempSlot < 0 % the two stimuli are overlapping
		slot2StimYN = 1; % stimuli on for slot 2
	else % the stimuli are not overlapping
		slot2StimYN = 0; % stimuli off for slot 2
		tempSlot = 0;
	end
	slot3Length = sessionStr.cue2Length(nTrial) + tempSlot;
	
	if slot1Length<0 || slot2Length<0 || slot3Length<0
		warning('You attempted to generate a cue duration less than zero. No stimulus will be given on this trial.');
		slot1Length = 0;
		slot2Length = 0;
		slot3Length = 0;
		pause;
	end
	
	%% figuring out which stimuli should be turned on in which slots
	
	if trialLRtype==1 || trialLRtype==5 % if left cue is played in first slot
		% if aud cue is played
		if trialAVtype==1 || trialAVtype==3
			cue1_aud = mouseStr.leftAudCue;
			if slot2StimYN==1 % if it's played in the second slot
				cue2_aud = mouseStr.leftAudCue;
			end
		end
		
		% if vis cue is played
		if trialAVtype==2 || trialAVtype==3
			cue1_vis = mouseStr.leftVisCue;
			if slot2StimYN==1 % if it's played in the second slot
				cue2_vis = mouseStr.leftVisCue;
			end
		end
	end
	
	if trialLRtype==3 || trialLRtype==6 % if right cue is played in first slot
		% if aud cue is played
		if trialAVtype==1 || trialAVtype==3
			cue1_aud = mouseStr.rightAudCue;
			if slot2StimYN==1 % if it's played in the second slot
				cue2_aud = mouseStr.rightAudCue;
			end
		end
		
		% if vis cue is played
		if trialAVtype==2 || trialAVtype==3
			cue1_vis = mouseStr.rightVisCue;
			if slot2StimYN==1 % if it's played in the second slot
				cue2_vis = mouseStr.rightVisCue;
			end
		end
	end
	
	
	if trialLRtype==2 || trialLRtype==6 % if left cue is played in third slot
		% if aud cue is played
		if trialAVtype==1 || trialAVtype==3
			cue3_aud = mouseStr.leftAudCue;
			if slot2StimYN==1 % if it's played in the second slot
				if mouseStr.leftAudCue~=0
					if cue2_aud==0
						cue2_aud = mouseStr.leftAudCue;
					else
						warning('Attempting to play two contradictory auditory stimuli simultaneously');
					end
				end
			end
		end
		
		% if vis cue is played
		if trialAVtype==2 || trialAVtype==3
			cue3_vis = mouseStr.leftVisCue;
			if slot2StimYN==1 % if it's played in the second slot
				if mouseStr.leftVisCue~=0
					if cue2_vis==0
						cue2_vis = mouseStr.leftVisCue;
					else
						warning('Attempting to play two contradictory visual stimuli simultaneously');
					end
				end
			end
		end
	end
	
	
	if trialLRtype==4 || trialLRtype==5 % if right cue is played in third slot
		% if aud cue is played
		if trialAVtype==1 || trialAVtype==3
			cue3_aud = mouseStr.rightAudCue;
			if slot2StimYN==1 % if it's played in the second slot
				if mouseStr.rightAudCue~=0
					if cue2_aud==0
						cue2_aud = mouseStr.rightAudCue;
					else
						warning('Attempting to play two contradictory auditory stimuli simultaneously');
					end
				end
			end
		end
		
		% if vis cue is played
		if trialAVtype==2 || trialAVtype==3
			cue3_vis = mouseStr.rightVisCue;
			if slot2StimYN==1 % if it's played in the second slot
				if mouseStr.rightVisCue~=0
					if cue2_vis==0
						cue2_vis = mouseStr.rightVisCue;
					else
						warning('Attempting to play two contradictory visual stimuli simultaneously');
					end
				end
			end
		end
	end
	
	
	%% put everything in the struct
	sessionStr.slot1Length(nTrial) = slot1Length;
	sessionStr.slot2Length(nTrial) = slot2Length;
	sessionStr.slot3Length(nTrial) = slot3Length;
	
	sessionStr.cue1_aud(nTrial) = cue1_aud;
	sessionStr.cue2_aud(nTrial) = cue2_aud;
	sessionStr.cue3_aud(nTrial) = cue3_aud;
	sessionStr.cue1_vis(nTrial) = cue1_vis;
	sessionStr.cue2_vis(nTrial) = cue2_vis;
	sessionStr.cue3_vis(nTrial) = cue3_vis;
	
end







