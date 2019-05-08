function D = extract_session_info(basedir)

%this function return informations from the animal e parameters from the
%session, such as animal's weight, session date, training phase, side poke
%time limit (in seconds), punish time (in s), initiation time (in s) and
%size of rewards in each poke (in uL). The output is a structure (D) with
%all the fields cited above.

[~, basename] = fileparts(pwd);

if isfile('sessionStr.mat')
    load ./sessionStr.mat
    session_info = sessionStr;
elseif isfile('session_info.mat')
    load ./session_info.mat
end

D.trainingPhase = session_info.trainingPhase;
D.weight = session_info.weight;
D.initiation_time_limit = session_info.readyToGoLength/1000;
D.sidePoke_time_limit = session_info.goToPokesLength/1000;
D.punish_time = session_info.punishDelayLength/1000;
D.IrewardSize_nL = double(session_info.IrewardSize_nL)/1000;
D.LrewardSize_nL = double(session_info.LrewardSize_nL)/1000;
D.RrewardSize_nL = double(session_info.RrewardSize_nL)/1000;
D.date = session_info.date;

end


