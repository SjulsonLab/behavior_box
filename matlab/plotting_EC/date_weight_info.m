function D = date_weight_info(startdir)

startdir = fileparts(pwd);
%basedir = pwd;

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
        
        D.cellofDates = {D(:).date};
        D.days = cellfun(@str2num,D.cellofDates);
        
        for i =1:length(D.cellofDates) 
        yyyy(i) = str2num(D.cellofDates{i}(1:4)); 
        mm(i) = str2num(D.cellofDates{i}(5:6)); 
        dd(i) = str2num(D.cellofDates{i}(7:8)); 
        end
        
% transfer dates into days of year 
D.auxd = datetime(yyyy,mm,dd); 
D.doy = day(D.auxd,'dayofyear');
for i = 1:length(D.doy)
    D.doy2{i,1} = num2str(D.doy(i)-D.doy(1));
end
D.auxTicks = D.doy2;
        
        
end