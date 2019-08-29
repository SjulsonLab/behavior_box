% used by calc_accuracy_LS.m

function correctYN = is_correct(pokes, trial_types)

correctYN = zeros(size(trial_types));
if ~isempty(pokes)
    
    %left pokes
    temp = cellfun(@(x) strcmpi(x,'left'),pokes) & ismember(trial_types,[1,2]);
    correctYN(temp) = 1;
    
    %right pokes
    temp = cellfun(@(x) strcmpi(x,'right'),pokes) & ismember(trial_types,[3,4]);
    correctYN(temp) = 1;
% else
%     correctYN = 0;
end
