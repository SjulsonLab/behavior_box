% script to generate all of the poke plots for a few test sessions

clear all
close all
tic

% these need to be changed
%cd('/home/edith/lab@sjulsonlab.org/lab-shared/lab_projects/rewardPrediction/behavior/D1R104M735');
k = dir('ADR*');
%k = dir('D1R*');

startdir = pwd;

parfor idx = 1:length(k)
	if k(idx).isdir==1 % only for directories
		extract_poke_info(k(idx).name, startdir);
        %makePokePlot1(k(idx).name, startdir);
        %fixed_choice_accuracy(k(idx).name, startdir);
	end
end

toc
	
