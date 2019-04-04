function plot_poke_latency(basedir)  

if nargin<2
	%startdir = pwd;
    basedir = pwd;
end

%cd(startdir);
cd(basedir);

%[~,basename] = fileparts(pwd);

%extract poke info

L = extract_poke_info(basedir);


%median_poke_latency 

Init_latency=median((L.trial_start_latencies)/1000);%bar(Init_latency,'facecolor','b');hold on;
Left_poke_latency=median((L.Lreward_pokes_latencies)/1000);%bar(Left_poke_latency,'facecolor','k');hold on;  
right_poke_latency=median((L.Rreward_pokes_latencies)/1000);%bar(right_poke_latency,'facecolor','r')  
%hold off;
%xlabel('Init_latency','Left_poke_latency','right_poke_latency')
%latencies = [Init_latency Left_poke_latency right_poke_latency];
boxplot(Init_latency,'-dk','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
hold on; 
plot(Left_poke_latency,'-dr','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(right_poke_latency,'-db','linewidth',2,'markerfacecolor',[0 1 0],'markersize',3)
ylabel('Time(in s)')
legend('Init latency','Left poke latency','Right poke latency')


%C= categorical({'Init_latenc','Left_poke_latency','right_poke_latency'});
%latencies = [Init_latency Left_poke_latency right_poke_latency];
%bar(C, latencies)
%ylabel('Time(in s)')
%title('Poke latencies')
end 


