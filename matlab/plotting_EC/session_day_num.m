function SDN = session_day_num(startdir,basedir)


if nargin<1
    startdir = pwd;
end

cd(startdir);
[~, basename] = fileparts(startdir);
animalDir = dir;

idxDir = find([animalDir.isdir]);

s = 0;
for idx = idxDir
    if (strfind(animalDir(idx).name,basename))
        cd(animalDir(idx).name)
        %processing and collecting data

%         try
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
%         catch
%             warning(['Unable to find .mat files in ' basedir]);
%             return
%         end

        
        % extract times of nosepoke entries
        if flag
        s = s+1;
        [~,fname]=fileparts(basedir);
        
        SDN.N(s).date = session_info.date;
        if strcmp(fname,animalDir(idx).name)
            SDN.folderNum = s;
        end
        
        end
      cd(startdir) 
    end
end

        
end