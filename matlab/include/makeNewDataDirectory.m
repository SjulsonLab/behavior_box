function sessionStr = makeNewDataDirectory(sessionStr, m)

% function sessionStr = makeNewDataDirectory(sessionStr, m)


sessionStr.timeString = m.timeString;
sessionStr.dateString = m.dateString;
% cd(m.basedir);
sessionStr.basename = [sessionStr.mouseName '_' datestr(now, 'yymmdd') '_' sessionStr.timeString];
sessionStr.basedir = [m.basedir '/' sessionStr.basename];
mkdir(sessionStr.basedir);


%% also checking python version for later
x = pyversion();
if str2num(x) ~= 2.7
	try
		pyversion 2.7
	catch
		disp('The wrong version of python is loaded. Restart MATLAB.');
		return
	end
end