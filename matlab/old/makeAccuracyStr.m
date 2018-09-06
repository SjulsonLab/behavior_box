function accuracyStr = makeAccuracyStr(trialInfo)

% makes struct array "accuracyStr" from input struct array "trialInfo"

accuracyStr.leftOutcome = string();
accuracyStr.leftTrialNum = string();
accuracyStr.leftAcc = [];

accuracyStr.rightOutcome = string();
accuracyStr.rightTrialNum = string();
accuracyStr.rightAcc = [];


for idx = 1:length(trialInfo)
    if strcmpi(trialInfo(idx).cuedSide, "left") && ~strcmpi(trialInfo(idx).outcome2, "none")
        accuracyStr.leftOutcome{end+1} = trialInfo(idx).outcome2;
        accuracyStr.leftTrialNum(end+1) = trialInfo(idx).trialNum;
        accuracyStr.leftAcc(end+1) = sum(count(accuracyStr.leftOutcome,"correct"));
        accuracyStr.leftAcc(end) = accuracyStr.leftAcc(end) ./ length(accuracyStr.leftAcc);
    end
    
    if strcmpi(trialInfo(idx).cuedSide, "right") && ~strcmpi(trialInfo(idx).outcome2, "none")
        accuracyStr.rightOutcome(end+1) = trialInfo(idx).outcome2;
        accuracyStr.rightTrialNum(end+1) = trialInfo(idx).trialNum;
        accuracyStr.rightAcc(end+1) = sum(count(accuracyStr.rightOutcome,"correct"));
        accuracyStr.rightAcc(end) = accuracyStr.rightAcc(end) ./ length(accuracyStr.rightAcc);
    end 
end



%n = length(accuracyStr);
%tempCorrectCount = 0;
%for idx = (n-5):n
%   if strcmpi(accuracyStr(idx), "correct")
%       tempCorrectCount = tempCorrectCount + 1;
%       movingAccuracy = 
end

