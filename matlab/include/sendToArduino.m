% function sendToArduino(fid, Ntrial, varName, varVal)
%
% function to send a variable to the arduino on each trial. If varVal is
% a vector, it sends the Ntrial-th entry. If it is a scalar, it just sends
% the scalar value. This function has a pause in it to give the arduino
% time to read in the string before the next one is sent.
%
% Luke Sjulson, 2017-07

function sendToArduino(fid, Ntrial, varName, varVal)

if length(varVal)==1
    fprintf(fid, [varName ';' num2str(varVal) '\n']);
    %     fprintf(1, [varName ';' num2str(varVal) '\n']);
    pause(0.01);
    
elseif length(varVal)>=Ntrial
    fprintf(fid, [varName ';' num2str(varVal(Ntrial)) '\n']);
    %     fprintf(1, [varName ';' num2str(varVal(Ntrial)) '\n']);
    pause(0.01);
else
    warning(sprintf('Ntrial does not match length of %s', varName));
end