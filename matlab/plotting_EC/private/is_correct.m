% used by calc_accuracy_LS.m

function correctYN = is_correct(pokes, trial_types)

for idx = 1:length(pokes)
	if strcmpi(pokes{idx}, 'left') && any(trial_types(idx) == [1 2])
		correctYN(idx) = 1;
	elseif strcmpi(pokes{idx}, 'right') && any(trial_types(idx) == [3 4])
		correctYN(idx) = 1;
	else correctYN(idx) = 0;
	end
end
