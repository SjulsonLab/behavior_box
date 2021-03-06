function [cue1_vis, cue1_aud, cue2_vis, cue2_aud, cue3_vis, cue3_aud] = makeCueVectors_3cue(sessionStr, mouseStr)

% function [cue1_vis, cue1_aud, cue2_vis, cue2_aud, cue3_vis, cue3_aud] = makeCueVectors_3cue(sessionStr, mouseStr)
%
% Function to generate cue vectors to send to the arduino. The sessionStr
% must have fields:
%
% trialLRtype (1 = left, 2 = right, 3 = free choice) and
% trialAVtype (1 = aud only, 2 = vis only, 3 = aud+vis)
%
% leftCueWhen (1 = first cue slot, 2 = second cue slot, 4 = third cue slot)
% rightCueWhen (sum numbers to play cue in multiple slots)
%
% the mouseStr must have the fields:
%
% leftVisCue (0 = nothing, 1 = LEDs 1+2, 2 = LEDs 3+4, 3 = LEDs 1-4)
% leftAudCue (0 = nothing, 1 = low tone, 2 = high tone, 3 = buzzer, 4 = white noise)
% rightVisCue
% rightAudCue
%
% Luke Sjulson, 2018-09-07

%% for testing
% clear all
% 
% % info from mouse struct
% mouseStr.leftVisCue  = 0;
% mouseStr.leftAudCue  = 3;
% mouseStr.rightVisCue = 2;
% mouseStr.rightAudCue = 0;
% 
% % info about trial types
% sessionStr.trialLRtype  = [3 3 3 3 3 3 3]; % 1 = left, 2 = right, 3 = free choice (i.e. both)
% % sessionStr.trialAVtype  = [3 2 1 2 1 3 1 2 1 1 3 3 2 1]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
% sessionStr.trialAVtype  = [3 3 3 3 3 3 3]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
% 
% 
% % which slots they go in. 1 = first slot, 2 = second slot, 4 = third slot.
% % So 7 would be all slots, 5 would be first and third, etc.
% sessionStr.leftCueWhen  = [1 2 3 4 5 6 7]; % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots
% sessionStr.rightCueWhen = [7 6 5 4 3 2 1]; % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots

%% start of actual function

% declare cue vectors as all zeros
cue1_vis = zeros(length(sessionStr.trialLRtype), 1);
cue1_aud = cue1_vis;
cue2_vis = cue1_vis;
cue2_aud = cue1_vis;
cue3_vis = cue1_vis;
cue3_aud = cue1_vis;



% loop over trials, fill in the cue vectors
for idx = 1:length(sessionStr.trialLRtype)
	
	% converting cueWhen variables to binary
	leftCueWhen = dec2bin(sessionStr.leftCueWhen(idx), 3);
	rightCueWhen = dec2bin(sessionStr.rightCueWhen(idx), 3);
	
	% if left cue will be delivered
	if sessionStr.trialLRtype(idx)==1 || sessionStr.trialLRtype(idx)==3 % left trial or free choice trial
		
		% if auditory cue will be delivered
		if sessionStr.trialAVtype(idx)==1 || sessionStr.trialAVtype(idx)==3 % either auditory or aud+vis
			
			if leftCueWhen(3)=='1' % aud in 1st cue slot
				if cue1_aud(idx)==0
					cue1_aud(idx) = mouseStr.leftAudCue;
				elseif mouseStr.leftAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue1_aud');
				end
			end
			
			if leftCueWhen(2)=='1' % aud in 2nd cue slot
				if cue2_aud(idx)==0
					cue2_aud(idx) = mouseStr.leftAudCue;
				elseif mouseStr.leftAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue2_aud');
				end
			end
			
			if leftCueWhen(1)=='1' % aud in 3rd cue slot
				if cue3_aud(idx)==0
					cue3_aud(idx) = mouseStr.leftAudCue;
				elseif mouseStr.leftAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue3_aud');
				end
			end
		end
		
		% if visual cue will be delivered
		if sessionStr.trialAVtype(idx)==2 || sessionStr.trialAVtype(idx)==3 % either visual or aud+vis
			
			if leftCueWhen(3)=='1' % vis in 1st cue slot
				if cue1_vis(idx)==0
					cue1_vis(idx) = mouseStr.leftVisCue;
				elseif mouseStr.leftVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue1_vis');
				end
			end
			
			if leftCueWhen(2)=='1' % vis in 2nd cue slot
				if cue2_vis(idx)==0
					cue2_vis(idx) = mouseStr.leftVisCue;
				elseif mouseStr.leftVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue2_vis');
				end
			end
			
			if leftCueWhen(1)=='1' % vis in 3rd cue slot
				if cue3_vis(idx)==0
					cue3_vis(idx) = mouseStr.leftVisCue;
				elseif mouseStr.leftVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue3_vis');
				end
			end
		end
		
	end
	
	
	
	%%
	% if right cue will be delivered
	if sessionStr.trialLRtype(idx)==2 || sessionStr.trialLRtype(idx)==3 % right trial or free choice trial
		
		% if auditory cue will be delivered
		if sessionStr.trialAVtype(idx)==1 || sessionStr.trialAVtype(idx)==3 % either auditory or aud+vis
			
			if rightCueWhen(3)=='1' % aud in 1st cue slot
				if cue1_aud(idx)==0
					cue1_aud(idx) = mouseStr.rightAudCue;
				elseif mouseStr.rightAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue1_aud');
				end
			end
			
			if rightCueWhen(2)=='1' % aud in 2nd cue slot
				if cue2_aud(idx)==0
					cue2_aud(idx) = mouseStr.rightAudCue;
				elseif mouseStr.rightAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue2_aud');
				end
			end
			
			if rightCueWhen(1)=='1' % aud in 3rd cue slot
				if cue3_aud(idx)==0
					cue3_aud(idx) = mouseStr.rightAudCue;
				elseif mouseStr.rightAudCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue3_aud');
				end
			end
		end
		
		% if visual cue will be delivered
		if sessionStr.trialAVtype(idx)==2 || sessionStr.trialAVtype(idx)==3 % either visual or aud+vis
			
			if rightCueWhen(3)=='1' % vis in 1st cue slot
				if cue1_vis(idx)==0
					cue1_vis(idx) = mouseStr.rightVisCue;
				elseif mouseStr.rightVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue1_vis');
				end
			end
			
			if rightCueWhen(2)=='1' % vis in 2nd cue slot
				if cue2_vis(idx)==0
					cue2_vis(idx) = mouseStr.rightVisCue;
				elseif mouseStr.rightVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue2_vis');
				end
			end
			
			if rightCueWhen(1)=='1' % vis in 3rd cue slot
				if cue3_vis(idx)==0
					cue3_vis(idx) = mouseStr.rightVisCue;
				elseif mouseStr.rightVisCue~=0
					error('attempting to deliver two contradictory stimuli simultaneously for cue3_vis');
				end
			end
		end
		
	end
	
	
	
	
end



