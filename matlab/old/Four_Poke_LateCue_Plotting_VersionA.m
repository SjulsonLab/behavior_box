%{

This script will plot where the mouse made an error.
Outer corresponds to Audio and Inner to Visual.

This version will play the distractor sound stimulus randomly between left
and right sides.

%}




%make sure no old serial ports are open
clear
delete(instrfindall);

soundStart = 0.1;
soundLength = 0.4;
soundRep = 1;

format
%tzero = clock;
time = clock;
tzero = fix(time(:,[4:6]));

serialPort = 'COM20';
baudeRate = 115200;
s = serial(serialPort,'Timeout', 15000, 'BaudRate', baudeRate, 'Terminator', 'LF');
fopen(s);

%load sound files for rewards
%[rewardR, FsA]=audioread('CorrectRightToneCloud.ogg');
%[rewardL, FsA]=audioread('CorrectLeftToneCloud.ogg');
%playerRewardR = audioplayer(rewardR, FsA);
%playerRewardL = audioplayer(rewardL, FsA);
clear rewardR rewardL



%{
rewardR = rewardR*1/max(rewardR);
rewardL = rewardL*1/max(rewardL);
rewardR = rewardR((round(soundStart.*FsA)):(round(soundStart + soundLength.*FsA)));
rewardL = rewardL((round(soundStart.*FsA)):(round(soundStart + soundLength.*FsA)));
rewardR = repmat(rewardR, soundRep, 1);
rewardL = repmat(rewardL, soundRep, 1);
%}

% [high, FsA] = audioread('highWhitenoiseShort.ogg');
% initH = high*0.9/max(high);
% playerInitHigh = audioplayer(repmat(initH, 48, 1), FsA);
% clear initH high
% 
% [low, FsA] = audioread('lowwhitenoiseShort.ogg');
% initL = low*0.9/max(low);
% playerInitLow = audioplayer(repmat(initL, 48, 1), FsA);
% clear initL low
% 
% [WN, FsA] = audioread('whitenoiseShort.ogg');
% initWN = WN*0.9/max(WN);
% playerWN = audioplayer(repmat(initWN, 48, 1), FsA);
% clear initWN WN FsA

%trial information
% autostart=zeros(1,500);
% stimOff=zeros(1,500);

stimSide = zeros(1, 500);
intensity = zeros(1, 500);
latency = zeros(1, 500);
reward = zeros(1, 500);
errorSide = zeros(1, 500);

autostart_ts = zeros(1, 500);
stimon_ts = zeros(1, 500);
reward_ts = zeros(1, 500);
stimoff_ts = zeros(1, 500);

index = 0;
trials = 0;
laststate = '';

figure(1)
ylim([-4 4]);
hold on
drawnow
figure(2)
drawnow

run = true(1);

p = 0;
pLeft = 0;
pRight = 0;

color = zeros(500,3);
left = [];
right = [];
corr = [];
inc = [];
missed = [];

audio = [];
visual = [];
errors = [];

distract = [];
nonDistract = [];
randDist = [];

AND = [];
AD = [];
VND = [];
VD = [];
ErrOutLeft =[];
ErrOutRight = [];
ErrInLeft = [];
ErrInRight = [];
%audio player variables
started = 0;
AudioOn = 0;
VisOn = 0;
VisWhite = 0;
remOn = 0;
timeNow = 0;



while run
    ts = 0;
    log = '';
    distVal = '';
    
    ser = fgetl(s);
    
    edges = [];
    
    %SERIAL LOG
    if ~isempty(ser) && strcmp(ser([1:3]), 'LOG')
        log = ser(4:end);
        
        %prints log statement and saves to record
        disp(log);
        index = index + 1;
        record{index} = log;
        
        %Audio Control
        if strcmp(log, 'LEDTG On')
          %  play(playerInitLow);
            VisOn = 1;
            AudioOn = 0;
            VisWhite = 0;
            remOn = 0;
        elseif strcmp(log, 'LEDTB On')
          %  play(playerInitHigh);
            AudioOn = 1;
            VisOn = 0;
            VisWhite = 0;
            remOn = 0;
        elseif strcmp(log, 'LEDTGWhite On')
           % play(playerWN);
            VisOn = 0;
            AudioOn = 0;
            VisWhite = 1;
            remOn = 0;
        elseif strcmp(log, 'initiation')
           % stop(playerInitHigh);
           % stop(playerInitLow);
           % stop(playerWN);
%         elseif strcmp(log, 'removed')
%             if remOn ~= 1
%                 if AudioOn == 1
%                     play(playerInitHigh);
%                 elseif VisOn == 1
%                     play(playerInitLow);
%                 elseif VisWhite == 1
%                     play(playerWN);
%                 end
%             end
            
            %Trial store plotting and stimulus
        elseif strcmp(log, 'autostart')
            trials = trials + 1;
            reward(trials) = -1;
            laststate   = 'autostart';
            mouseaction = 'autostart';
            remOn = 1;
            VisOn = 0;
            VisWhite = 0;
            
%             stop(playerInitHigh);
%             stop(playerInitLow);
%             stop(playerWN);
            
        elseif regexp(log, 'stim\s\w*\son')
            
            if strcmp(log, 'stim left on')
                %trialGoing = 1;
                stimSide(trials) = 1;
                left = [left trials];
                % randDist = randi([0 1],1,2);
                
                if AudioOn == 1
                    %play(playerRewardL)
                    AudioOn = 0;
                    %trialGoing = 0;
                end
                
            elseif strcmp(log, 'stim right on')
                stimSide(trials) = -1;
                %trialGoing = 1;
                right = [right trials];
                if AudioOn == 1
                    %play(playerRewardR)
                    AudioOn = 0;
                    %trialGoing = 0;
                end
            end
            laststate = 'stim on';
            
        elseif ~isempty(strfind(log, 'visual stim'))
            visual = [visual trials];
            if ~isempty(strfind(log, 'distractor'))
                distract = [distract trials];
                VD = [VD trials];
            else
                nonDistract = [nonDistract trials];
                VND = [VND trials];
            end
            
        elseif ~isempty(strfind(log, 'audio stim'))
            audio = [audio trials];
            if ~isempty(strfind(log, 'distractor'))
                distract = [distract trials];
                AD = [AD trials];
            else
                nonDistract = [nonDistract trials];
                AND = [AND trials];
            end
            
        elseif strcmp(log, 'reward delivered')
            laststate = 'reward';
            mouseaction = 'reward';
            corr = [corr trials];
            reward(trials) = 1;
            
        elseif strcmp(log, 'missed your shot!')
            mouseaction = 'missed';
            missed = [missed trials];
            
        elseif ~isempty(strfind(log, 'wrong'))
            errors = [errors trials];
            if ~isempty(strfind(log, 'Outer right'))
                ErrOutRight = [ErrOutRight trials];
                errorSide(trials) = -2;
            elseif ~isempty(strfind(log, 'Center right'))
                ErrInRight = [ErrInRight trials];
                errorSide(trials) = -1;
            elseif ~isempty(strfind(log, 'Center left'))
                ErrInLeft = [ErrInLeft trials];
                errorSide(trials) = 1;
            elseif ~isempty(strfind(log, 'Outer left'))
                ErrOutLeft = [ErrOutLeft trials];
                errorSide(trials) = 2;
            end
            
        elseif strcmp(log, 'stim off')
            laststate = 'stim off';
            if strcmp(mouseaction, 'reward')
                color(trials,:) = [0 1 0];
            elseif strcmp(mouseaction, 'missed')
                color(trials,:) = [0 0 1];
            elseif strcmp(mouseaction, 'autostart')
                color(trials,:) = [1 0 0];
                inc = [inc trials];
            end
            
            fileID = fopen('behavior.txt','w');
            fprintf(fileID, '%s\r\n', record{1:index});
            fclose(fileID);
            
            p = length(corr)/trials;
            pLeft = length(intersect(left, corr))/length(left);
            pRight = length(intersect(right, corr))/length(right);
            pVisual = length(intersect(visual, corr))/length(audio);
            pAudio = length(intersect(audio, corr))/length(audio);
            pNonDistract = length(intersect(nonDistract, corr))/length(nonDistract);
            pDistract = length(intersect(distract, corr))/length(distract);
            pval = binopdf(length(corr), trials, .5);
            
            %t = clock;
            %time = t - tzero;
            %timedisp = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6))];
            
            timeDisp = timeNum/60;
            timeDisp = num2str(round(timeDisp,2));
            
            figure(1)
            hold on
            if ~isempty(AND)
                scatter(AND, stimSide(AND)*2, 100, color(AND,:), 'o');
            end
            if ~isempty(AD)
                scatter(AD,  stimSide(AD)*2,  100, color(AD,:),  'o', 'filled');
            end
            if ~isempty(VND)
                scatter(VND, stimSide(VND), 100, color(VND,:), 's');
            end
            if ~isempty(VD)
                scatter(VD,  stimSide(VD),  100, color(VD,:),  's', 'filled');
            end
            if ~isempty(ErrOutRight)
                scatter(ErrOutRight, errorSide(ErrOutRight), 100, 'k', 'x');
            end
            if ~isempty(ErrInRight)
                scatter(ErrInRight, errorSide(ErrInRight), 100, 'k', 'x');
            end
            if ~isempty(ErrInLeft)
                scatter(ErrInLeft, errorSide(ErrInLeft), 100, 'k', 'x');
            end
            if ~isempty(ErrOutLeft)
                scatter(ErrOutLeft, errorSide(ErrOutLeft), 100, 'k', 'x');
            end
            
            
            title({['P Total:' num2str(p,3) ', P Left:' num2str(pLeft, 3) ', P Right: ' num2str(pRight, 3)];
                ['P Visual: ' num2str(pVisual, 3) ', P Audio: ' num2str(pAudio, 3)];
                ['P NonDistract: ' num2str(pNonDistract, 3) ', P Distract: ' num2str(pDistract, 3)];
                ['P Val = ' num2str(pval, 3) ', Mins : ' timeDisp]})
            drawnow
            
        end
        
        %SERIAL TIMESTAMP
    elseif ~isempty(ser) && strcmp(ser(1:4), 'TIME')
        index = index + 1;
        %time = ser(5:end);
        disp(ser(5:end))
        
        timeNow = ser(5:end);
        timeNum = str2num(timeNow);
        timeNum = timeNum/1000;
        timeNum = round(timeNum);
        
        record{index} = ser(5:end);
        ts = str2double(ser(5:end));
        
        if strcmp(laststate, 'autostart')
            autost_ts(trials) = ts;
        elseif strcmp(laststate, 'stim on')
            stimon_ts(trials) = ts;
        elseif strcmp(laststate, 'reward')
            reward_ts(trials) = ts;
        elseif strcmp(laststate, 'stim off')
            stimoff_ts(trials) = ts;
            if reward(trials) == 1
                latency(trials) = reward_ts(trials) - stimon_ts(trials);
            elseif reward(trials) == -1
                latency(trials) = stimoff_ts(trials) - stimon_ts(trials);
            end
            %{
            if ~isempty(corr) && ~isempty(inc)
                
                figure(2)
                edges = 0:1000:max(latency) + 1000;
                xbar = 500:1000:edges(end);
                
                [Ncorr, edges] = histcounts(latency(corr), edges);
                [Ninc, edges] = histcounts(latency(inc), edges);
                b = bar(xbar, [Ninc;Ncorr]');
                drawnow
            end
            %}
        end
        laststate = '';
    end
end

%Close Serial COM Port
fclose(s);
disp('Session Terminated...');







