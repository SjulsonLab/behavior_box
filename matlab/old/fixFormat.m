function Z = fixFormat(Ntrial, varVal)

if length(varVal)==1
    Z = num2str(varVal);
elseif length(varVal)>=Ntrial
    Z = num2str(varVal(Ntrial));
else
    warning('Ntrial does not match length of varVal');
end
