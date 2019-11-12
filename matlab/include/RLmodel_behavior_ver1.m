function [RLfit] = RLmodel_behavior_ver1(filename,isFigure1)

%this function was develop by Soyoun Kim (2019) as a RL model to the free choice
%trials in the decision making task we are running (2AFC).
%
%some small adaptations were made by Eliezyer de Oliveira


%filename ='D1R114M828_20190913_094728.txt';
% files = dir ('*.txt');

% filename = files(n).name
if nargin<2
    isFigure1=0;
end
fid=fopen(filename);
tmp = textscan(fid, '%d%d%s%f', 'Delimiter',';');
fclose(fid);

session = unique(tmp{2}); nsession = length(session);
t = strcmp(tmp{3},'trialLRtype')& tmp{4}>0;
tF = strcmp(tmp{3},'trialLRtype') & tmp{4}>4;
freechoicesession = tmp{2}(tF);
trialtype = tmp{4}(t);
LFchoice = (trialtype==1| trialtype==2);
RFchoice = (trialtype==3 | trialtype==4 );

choicetype = zeros(nsession,1); % 1 for left, 2 for right, 3 for free
choicetype(LFchoice,1) =1; choicetype(RFchoice,1) = 2;
choicetype(freechoicesession,1)=3;

%error
errorL = tmp{2}(strcmp(tmp{3}, 'LeftPokeError'));
errorR = tmp{2}(strcmp(tmp{3}, 'RightPokeError'));


Lsize = tmp{4}(strcmp(tmp{3},'Lsize_nL'));
Rsize = tmp{4}(strcmp(tmp{3},'Rsize_nL'));
LRsize =[Lsize, Rsize]; LRsize = LRsize/1000;
LRsize(LFchoice,2)=0; LRsize(RFchoice,1)=0;
LRsize_free = LRsize(freechoicesession,:);

choice = zeros(nsession,2);
Lchoice_reward = tmp{2}(strcmp(tmp{3},'leftReward_nL'));
Rchoice_reward = tmp{2}(strcmp(tmp{3},'rightReward_nL'));
choice(Lchoice_reward,1)=1; choice(Rchoice_reward,2)=1;
choice(errorL,1) = 1; choice(errorR,2)=1;
choice_free = choice(freechoicesession,:);

reward = zeros(nsession,1);
reward(choice(:,1)==1) = LRsize(choice(:,1)==1,1);
reward(choice(:,2)==1) = LRsize(choice(:,2)==1,2);
reward_free = reward(freechoicesession);

%%%fitting
regx ='qL-qR';
qfun = @ (qt, rt,par) qt+par(1)*(rt-qt);
qstr = 'Q(t)+alpha*(R(t)-Q(t))';
pfun = @ (x,par) 1./(1+exp(-par(end)*x));
%RPE = rt-qt;

ipar = [0.5,0.5,0.5];

op=optimset('fminsearch');
op.MaxFunEvals = 1000000;
op.MaxIter = 1000000;

[xpar fval exitflag, outp]  = fminsearch(@loglike, ipar, op, qfun, pfun, choice, reward,choicetype, regx);

qL = 0; qR = 0; LL=0;  pl=zeros(nsession,1);
qlr =[0,0]; pl(1)=0.5;RPE = zeros(nsession,1);
for ii=1:nsession-1
    if choicetype(ii)==3
        if choice(ii,1)==1
            RPE(ii+1,1) = reward(ii)-qL;
            qL = qfun(qL,reward(ii),xpar(1));
        elseif choice(ii,2)==1
            RPE(ii+1,1) = reward(ii)-qR;
            qR = qfun(qR,reward(ii),xpar(2));
        end
        pl(ii) = pfun(eval(regx), xpar);
    end
    if choicetype(ii)==1 & choice(ii,1)==1
        RPE(ii+1,1) = reward(ii)-qL;
        qL = qfun(qL,reward(ii),xpar(1));
    elseif choicetype(ii)==2 & choice(ii,2)==1
        RPE(ii+1,1) = reward(ii)-qR;
        qR = qfun(qR,reward(ii),xpar(2));
    end
    if choicetype(ii)==3
        qlr = [qlr;[qL,qR]];
    elseif choicetype(ii)==1
        qlr = [qlr;[qL,qR]]; %qlr = [qlr;[qL,0]];
    elseif choicetype(ii)==2
        qlr = [qlr;[qL,qR]]; %qlr = [qlr;[0,qR]];
    end  
    
end

RLfit.RPE = RPE;
RLfit.qlr = qlr;





if isFigure1==1
    f1 = figure('Renderer', 'painters', 'Position', [10 10 900 400]);
    subplot(4,1,2:4)
    x = 1:size(choice,1);
    row = find(LFchoice>0);
    for ii=1:length(row)
        h1(ii) = area([x(row(ii))-0.5, x(row(ii))+0.5],[5.5,5.5]);
        h1(ii).FaceColor = [0.6,0.6,0.6];
        h1(ii).EdgeColor = [0.6,0.6,0.6];
        hold on
    end
    
    row = find(RFchoice>0);
    for ii=1:length(row)
        h2(ii) = area([x(row(ii))-0.5, x(row(ii))+0.5],[5.5,5.5]);
        h2(ii).FaceColor = [0.8,0.8,0.8];
        h2(ii).EdgeColor = [0.8,0.8,0.8];
        hold on
    end
    xlim([0.5,size(LRsize,1)])
    %ylim([0, 5.6])
    
    
    plot(x(LRsize(:,1)>0),LRsize(LRsize(:,1)>0,1),'b.-')
    hold on
    plot(x(LRsize(:,2)>0),LRsize(LRsize(:,2)>0,2),'r.-')
    plot(freechoicesession(choice_free(:,1)>0), choice_free(choice_free(:,1)>0,1)*mean(LRsize(LRsize>0)),'b.')
    plot(freechoicesession(choice_free(:,2)>0), choice_free(choice_free(:,2)>0,2)*mean(LRsize(LRsize>0))*1.1,'r.')
    
    a = (choicetype==3 | choicetype==1);
    plot(x(a), qlr(a,1),'c-')
    a = (choicetype==3 | choicetype==2);
    plot(x(a), qlr(a,2),'m-')
    
    plot(freechoicesession, qlr(freechoicesession,1),'co','markerfacecolor','c','markersize',2)
    plot(freechoicesession, qlr(freechoicesession,2),'mo','markerfacecolor','m','markersize',2)
    plot(x(LFchoice), qlr(LFchoice,1),'co','markersize',2)
    plot(x(RFchoice), qlr(RFchoice,2),'mo','markersize',2)
    xlabel('trial number')
    
    subplot(4,1,1)
    plot(x,RPE,'k-')
    hold on
    plot(x(choicetype<3),RPE(choicetype<3),'go','markersize',3)
    plot(freechoicesession,RPE(freechoicesession),'ko','markerfacecolor','g','markersize',3)
    
    plot([x(1),x(end)],[0,1],'k:')
    xlim([0.5,size(LRsize,1)])
    title(['alpha_L:' num2str(xpar(1), 3) ', alpha_R:' num2str(xpar(2), 3)]);
    ylabel('RPE')
    
    %ax = gca;
    %ax.TickDir ='out'
    f1.Renderer = 'painters';
    
    
    %{
    %left forced choice /successful
    %right forced choice /failed
    plot(x(find(RFchoice.*choice(:,1))), choice(find(RFchoice.*choice(:,1)),1)*mean(LRsize(:))*0.9,'bx')
    
    plot(x(find(RFchoice.*choice(:,2))), choice(find(RFchoice.*choice(:,2)),2)*mean(LRsize(:))*1.1,'ro')
    plot(x(find(LFchoice.*choice(:,2))), choice(find(LFchoice.*choice(:,2)),2)*mean(LRsize(:))*0.9,'rx')
    %}
end

%define function for reinforcement learning

isFigure2=0; % for free choice
if isFigure2==1
    f2 = figure('Renderer', 'painters', 'Position', [10 10 900 400]);
    subplot(4,1,2:4)
    x = 1:size(choice_free,1);
    plot(x,LRsize_free(:,1),'b')
    hold on
    plot(x,LRsize_free(:,2),'r')
    plot(x(choice_free(:,1)>0), choice_free(choice_free(:,1)>0,1)*mean(LRsize(LRsize>0)),'b.')
    plot(x(choice_free(:,2)>0), choice_free(choice_free(:,2)>0,2)*mean(LRsize(LRsize>0))*1.1,'r.')
    plot(x, qlr(freechoicesession,1),'co-','markerfacecolor','c','markersize',2)
    plot(x, qlr(freechoicesession,2),'mo-','markerfacecolor','m','markersize',2)
    xlim([0.5,x(end)])
    xlabel('trial number')
    
    subplot(4,1,1)
    plot(x,RPE(freechoicesession),'go-','markersize',2)
    hold on
    plot([x(1),x(end)],[0,0],'k:')
    xlim([0.5,x(end)])
    title(['alpha_L:' num2str(xpar(1), 3) ', alpha_R:' num2str(xpar(2), 3)]);
    ylabel('RPE')
    
    %f2.Renderer = 'painters';
    
end

isFigure3=0; % for free choice
if isFigure3==1
f3 = figure('Renderer', 'painters', 'Position', [10 10 400 400]);

 x = -10:0.5:10;
ple = pfun(x, xpar);   
plot(x,ple)
xlabel('Q_L - Q_R')
ylabel('P_L(t)')
title([ 'beta: ' num2str(xpar(3),3)])    
end


n_pwindow = 5;
for ii=1:size(choice_free,1)-1
    ini = ii-floor(n_pwindow/2); if ini<1, ini=1;end
    fin = ii+floor(n_pwindow/2); if fin>size(choice_free,1), fin = size(choice_free,1)-1;
    end
    pl_5(ii,1) = sum(choice_free(ini:fin,1))/(fin-ini+1);
end

end



function LL = loglike(xpar, qfun, pfun, cho, rc, choicetype,regx)
pl =0;qL = 0; qR = 0; LL=0; nL = 0; nR =0; itot =0;
n_pwindow = 5; cho_free = cho(choicetype==3,:);
for ii=1:size(cho,1)-1
    
    if cho(ii,1)==1 && choicetype(ii)==3 %choice 1 = left, choice 2 = right, choice 3 = free choice
        itot=itot+1; % count for free choice
        qL = qfun(qL,rc(ii),xpar(1));
        pl = pfun(eval(regx), xpar);
    elseif cho(ii,2)==1 && choicetype(ii)==3
        itot=itot+1; % count for free choice
        qR = qfun(qR,rc(ii),xpar(2));
        pl = pfun(eval(regx), xpar);
    elseif cho(ii,1)==1 && choicetype(ii)==1
        qL = qfun(qL,rc(ii),xpar(1));
    elseif cho(ii,2)==1 && choicetype(ii)==2
        qR = qfun(qR,rc(ii),xpar(2));
    end
    
    if choicetype(ii)==3
        ini = itot-floor(n_pwindow/2); if ini<1, ini=1;end
        fin = itot+floor(n_pwindow/2); if fin>size(cho_free,1), fin=size(cho_free,1)-1;end
        nL = sum(cho_free(ini:fin,1));
        nR = sum(cho_free(ini:fin,2));
        
        if pl==0, pl = eps;end
        if pl==1, pl = 1-eps; end
        LL = LL - nL*log(pl)-nR*log(1-pl);
    end
end

end







