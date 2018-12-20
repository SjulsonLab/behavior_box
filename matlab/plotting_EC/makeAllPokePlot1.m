% script to generate all of the poke plots for a few test sessions

clear all
close all
tic

% these need to be changed
cd('C:\Users\lukes\Desktop\temp');
k = dir('D1R*');


startdir = pwd;

parfor idx = 1:length(k)
	if k(idx).isdir==1 % only for directories
		makePokePlot1(k(idx).name, startdir);
	end
end

toc
	
