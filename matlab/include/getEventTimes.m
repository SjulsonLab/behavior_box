function T = getEventTimes(textString, fname)

% function T = getEventTimes(textString, fname)
%
% This function searches for textString in the logfile called fname.
% It then returns the first column (which is the timestamp for
% behavior box log files). 
%
% Luke Sjulson, 2018-12-20


% %% testing
% fname = 'D1R96Male246_181203_154542.txt';
% textString = 'leftReward';


fid = fopen(fname, 'rt');
idx = 1;
while ~feof(fid)
	filetemp = fgetl(fid);
	if contains(filetemp, textString, 'IgnoreCase', true)
		T(idx) = str2num(filetemp(1:find(filetemp==';', 1)));
		idx = idx + 1;
	end
end
fclose(fid);


% % old code, works on some windows machines but not others
% winbash(['grep -i ' textString ' ' fname ' | cut -f 1 -d '';'' > ' textString '.tmp'], 'silent');
% T = load([textString '.tmp']) ./ 1000; % convert from ms to seconds
% winbash(['rm ' textString '.tmp']);

