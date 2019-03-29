function [times, numbers] = getEventTimes(textString, fname)

% function [times, numbers] = getEventTimes(textString, fname)
%
% This function searches for textString in the logfile called fname.
% It then returns the first column (which is the timestamp for
% behavior box log files) under times and the last column under numbers.
%
% Luke Sjulson, 2018-12-20
% updated 2019-03-29 to include numbers


% %% testing
% fname = 'D1R96Male246_181203_154542.txt';
% textString = 'leftReward';


fid = fopen(fname, 'rt');
idx = 1;
while ~feof(fid)
	filetemp = fgetl(fid);
	if contains(filetemp, textString, 'IgnoreCase', true)
		times(idx) = str2num(filetemp(1:find(filetemp==';', 1)));
		numbers(idx) = str2num(filetemp(find(filetemp==';', 1, 'last')+1:end));
		idx = idx + 1;
	end
end
if ~(exist('times','var') == 1)
    times = [];
end
if ~(exist('numbers','var') == 1)
    numbers = [];
end


fclose(fid);


% % old code, works on some windows machines but not others
% winbash(['grep -i ' textString ' ' fname ' | cut -f 1 -d '';'' > ' textString '.tmp'], 'silent');
% T = load([textString '.tmp']) ./ 1000; % convert from ms to seconds
% winbash(['rm ' textString '.tmp']);

