function D = date_weight_info(basedir)


%cd(basedir);
[~, basename] = fileparts(pwd);

            if isfile('sessionStr.mat')
                load ./sessionStr.mat
                session_info = sessionStr;
                flag = true;
            elseif isfile('session_info.mat')
                load ./session_info.mat
                flag = true;
            else
                flag = false;
            end

        D.trainingPhase = session_info.trainingPhase;
        D.weight = session_info.weight;
        D.IrewardSize_nL = session_info.IrewardSize_nL;
        D.date = session_info.date;
    
end 


