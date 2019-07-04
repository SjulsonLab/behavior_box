% This function was made to organize the behavior box folder. By the time 
% this code was written, our functions to control the boxes would save the 
% the behavioral data in a folder with animal name_date_time and save it in
% the google drive in a folder containing all the behavioral data. However,
% most of our codes to analyze the data depends in a specific structure of 
% folders where an animal folder contains every session that animal ever
% went through. 

% How this code works: It searches for session folders of animals outside 
% of their respective folders and move them inside their respective folder

function organize_BehavFolders

%% TO-DO LIST
% [] Identify main animal folders and if there are any outside (tip: detect
% folders that start all with the same name and stick with the shortest)
% [] Copy to the animal folder just the folders that have the .txt file and
% the two matlab files
% [] Spill out name of folders that are potentially empty because of a
% problem (i.e. doesn't have the two .mat files in it) and that can be
% deleted










end