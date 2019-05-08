function D2 = session_day(startdir)
%calculate the last minus first day of training in the folder 

if nargin<1
 %basedir = pwd;
 %startdir = fileparts(pwd);
 startdir = fileparts(pwd);
end

cd(startdir);
[~, basename] = fileparts(pwd);  
animalDir = dir;

idxDir = find([animalDir.isdir]);

s = 0;
for idx = idxDir
    if (strfind(animalDir(idx).name,basename))
        cd(animalDir(idx).name)
        %if flag
        s = s+1;
       
        D2(s) = extract_session_info(startdir);

        %[~,fname] = fileparts(cd);
        
    end
      cd(startdir) 
end