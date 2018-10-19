function Z = makeRandomVector(numRange, numLength)

% function Z = makeRandomVector(numRange, numLength)
%
% this function takes a range of numbers and returns a vector of length
% numLength
%
% e.g. 
% makeRandomVector([1 3 6], 10)
% 
% ans =
% 
%      3     6     6     1     6     6     3     6     3     1
% 
% Luke Sjulson, 2018-10-19



% % for testing
% numRange = [1 2 43 5];
% numLength = 10;

%% start of actual function
Z = numRange(randi(length(numRange), [1 numLength]));

