% function waitBest(question, title)
%
% the most foolproof wait program

function waitBest(question, title)

if nargin<2
	title = 'MATLAB says: Do it';
    question = 'Question';
end

loopFlg = 1;
while loopFlg == 1
	k = questdlg(question, title, 'OK', 'Cancel', 'Cancel');
	if strcmp(k, 'OK'), loopFlg = 0; end
end



