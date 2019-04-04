function acc_score_function(choices, trials) 


basedir = cd; 

%% extract all info 

L = extract_poke_info(basedir); 

%%  both accuracy  

% assigned trial side 
L.trials = L.trialLR_types; 
L.trials(L.trialLR_types == 1)==0; 
L.trials_aux = L.trialLR_types == 1; 

% total pokes in the session 
L.choices(1,:) = cat(2,zeros(size(L.Lpokes)),ones(size(L.Rpokes))); %0 and 1
L.choices(2,:) = cat(2,L.Lpokes,L.Rpokes); %time
[~,I] = sort(L.choices(2,:));
L.choices = L.choices(:,I);

% find the rewarded pokes within trial starts  
L.LRreward = zeros(2,length(L.Lreward_pokes)+length(L.Rreward_pokes)); %left and right reward time 
L.LRreward(2,:) = cat(2,L.Lreward_pokes,L.Rreward_pokes); %time
L.LRreward(1,:) = cat(2,zeros(size(L.Lreward_poke_trialnum)),ones(size(L.Rreward_poke_trialnum))); 
[~,I] = sort(L.LRreward(2,:));  %time in sequence 
L.LRreward= L.LRreward(:,I);  %array to be in sequence 


L.both_in_trial = Restrict(L.choices(2,:), [L.trial_starts' L.trial_stops'])

% find the first poke correct in the rewarded trials 

for idx = 1:length(L.trial_starts) 
 find(L.choices(2,:)== L.both_in_trial(1))
end

    

 %within the trial starts left happens first 



 L.first_correct = find(L.choices(2,:)== L.rewarded_in_trial(1));    %%within all the choice time first to be correct 
        
    
        L.first_correct_poke(1,i) = L.choices(1,L.first_correct); %which trial the animal poked  (in trialstarts, first to be correct) 
        L.first_correct_poke(2,i) = L.LRreward(1,i); %which it was supposed to be
        L.first_correct_poke(3,i) = L.choices(2,L.first_correct);
        
        
        
        
        
end 



for i = int16(1:length(L.trial_starts2_R)) %remove trials that weren't finished
    L.temp_R = Restrict(L.auxIntPk(2,:),[L.trial_starts2_R(i)',L.LRreward2_R(2,i)']);   %LRpoke time (561) % right start time (11) %getting reward time (11)
%     if ~isempty(temp)
        L.temp2_R = find(L.auxIntPk(2,:)==L.temp_R(1));
        
        
        
        
L.trialLR_types(L.trial_start_nums(idx))


L.choices_in_trial = Restrict(L.choices(2,:), [L.trial_starts' L.trial_stops']) %left and right poke within trialstarts 

%now we have to find the firstpokes that is correct within the trialstart
idx =1;
for idx = 1:length(L.trial_start_nums(idx))
    L.choices_first = Restrict(L.choices(2,:), [L.trial_starts(L.trial_start_nums(idx)) L.trial_stops(L.trial_start_nums(idx))])
    L.choice_correct = find(L.choices(2,:)==L.choices_first(1)); 
end


 





L.Lchoices_in_trial = Restrict(L.Lpokes, [L.trial_starts' L.trial_stops']) 
Left_in_trial = zeros(size(L.Lchoices_in_trial'))
L.Rchoices_in_trial = Restrict(L.Rpokes, [L.trial_starts' L.trial_stops']) 
right_in_trial = ones(size(L.Rchoices_in_trial'))


zeros(size(Ltemp))'







end

%% p-value and accuracy 
 L.temp = L.firstPoke(1,L.aux) - L.firstPoke(2,:);
    null_distribution(i) = length(find( (L.temp) == 0  ))/length(L.trial_starts2);


hist(null_distribution,100)
[auxND,x] = hist(null_distribution,100);
auxND = auxND./sum(auxND);
%f = fit(x',auxND','gauss1');
y = cumsum(auxND);
tempPV = find(y>=0.95);
p5=x(tempPV(1));
observed_accuracy>=p5
observed_accuracy
expected_accuracy = median(null_distribution)
pval = sum(null_distribution >= observed_accuracy) ./ length(null_distribution)




