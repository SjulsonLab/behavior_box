# -*- coding: utf-8 -*-
"""
Created on Tue Jan  8 13:31:45 2019

This script was made to preprocess and visualize the behavioral performance of 
mice in a single session. It should be called from the directory you have your 
session file

To do list:
@author: Eliezyer de Oliveira
"""

#libraries
import numpy as np
import matplotlib.pyplot as plt
import scipy.io as sio
import os

# %% function to get Event Times
def getEventTimes(textString,fname):
    
    # This function searches for textString in the logfile called fname.
    # It then returns the first column (which is the timestamp for
    # behavior box log files). 
    # based on getEventTimes LSjulson made on Matlab
    fid = open(fname,'r');
    fiLines = fid.readlines();
    fid.close()
    
    nLin = len(fiLines)
    c = 0;
    
    for idx in range(0,nLin):
        tempLine = fiLines[idx];
        if textString in tempLine:
            if c == 0:
                aux = tempLine.index(';');
                T = int(tempLine[0:aux]);
                c += 1;
            else:
                aux = tempLine.index(';');
                T = np.append(T,int(tempLine[0:aux]));
    return T;

# %%function to make the poke plot
def PokePlot(sessionStr,trialStarts,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards):
    histvec = np.arange(0,trialStarts[-1]+120,2);
    
    Thist = np.histogram(trialStarts,histvec); #I haven't found a similar to histc, np.digitize doesn't work
    
    Tshade = np.cumsum(Thist[0]);
    Tshade[ np.where(Tshade%2 == 1) ] = 9999;
    Tshade[ np.where(Tshade%2 == 0) ] = 0;
    
    #setting up figure
    f, (ax1, ax2, ax3) = plt.subplots(3,1,sharex = True);
    f.set_size_inches(24,13)
    plt.xlim(histvec[0],histvec[-1]+0.1*histvec[-1])
    
    
    trainPh = sessionStr['sessionStr']['trainingPhase'];
    f.suptitle(basename + ', trainingPhase ' + str(trainPh[0][0][0][0]),fontsize=18)
    
    ##########################################################################
    #FIRST SUBPLOT - POKES
    #data
    Lhist = np.histogram(Lpokes,histvec);
    if Lhist[0].size == 0:
        Lhist = np.zeros(np.shape(histvec));
    
    Rhist = np.histogram(Rpokes,histvec);
    if Rhist[0].size == 0:
        Rhist = np.zeros(np.shape(histvec));
    
    Ihist = np.histogram(Ipokes,histvec);
    if Ihist[0].size == 0:
        Ihist = np.zeros(np.shape(histvec));
    
    #plot
    ax1.fill_between(histvec[0:-1],0,Tshade,facecolor='grey',alpha=0.1)
    ax1.plot(histvec[0:-1],Lhist[0],'b',alpha=0.5,linewidth = 0.5)
    ax1.plot(histvec[0:-1],Rhist[0],'r',alpha=0.5,linewidth = 0.5)
    ax1.plot(histvec[0:-1],Ihist[0],'g',alpha=0.5,linewidth = 0.5)
    ax1.set_ylim([0,1.1])
    ax1.set_ylabel('Nosepokes')
    ax1.legend(['L pokes','R pokes','I pokes'],loc = 'upper right')
    #ax1.spines['right'].set_visible(False) #setting the position of the y axis only in the left
    #ax1.spines['top'].set_visible(False) #setting the position of the x axis only in the bottom
    
    
    
    ###############################################################################
    # SECOND SUBPLOT - REWARDS
    #data
    LrewardHist = np.histogram(Lrewards,histvec);
    if LrewardHist[0].size == 0:
        LrewardHist = np.zeros(np.shape(histvec));
    
    RrewardHist = np.histogram(Rrewards,histvec);
    if LrewardHist[0].size == 0:
        LrewardHist = np.zeros(np.shape(histvec));
    
    #plots
    ax2.fill_between(histvec[0:-1],0,Tshade,facecolor='grey',alpha=0.1)
    ax2.plot(histvec[0:-1],LrewardHist[0],'b',alpha=0.5,linewidth = 0.5)
    ax2.plot(histvec[0:-1],RrewardHist[0],'r',alpha=0.5,linewidth = 0.5)
    ax2.set_ylim([0,1.1])
    ax2.legend(['L reward','R reward'],loc = 'upper right')
    
    
    
    ###############################################################################
    # THIRD SUBPLOT - CUMULATIVE TRIALS AND REWARD
    ax3.fill_between(histvec[0:-1],0,Tshade,facecolor='grey',alpha=0.1)
    ax3.plot(histvec[0:-1],np.cumsum(Thist[0:-1]),'k',alpha=0.5)
    ax3.plot(histvec[0:-1],np.cumsum(LrewardHist[0]),'b',alpha=0.5)
    ax3.plot(histvec[0:-1],np.cumsum(RrewardHist[0]),'r',alpha=0.5)
    ax3.plot(histvec[0:-1],np.cumsum(LrewardHist[0]+RrewardHist[0]),'g',alpha=0.5)
    ax3.set_ylim([0,np.max(np.cumsum(Thist[0:-1]))+10])
    ax3.set_ylabel('Number of trials/rewards')
    ax3.set_xlabel('Time(seconds)')
    ax3.legend(['Trial Starts','L rewards','R rewards','All rewards'],loc = 'upper right')
    #SAVING FIGURE
    
    if not os.path.isdir("figures"):
        os.mkdir("figures")
    
    os.chdir("figures")
    f.savefig(basename+".pdf",bbox_inches='tight',dpi = 300)
    os.chdir("..")

def makePokePlot(workdir=os.getcwd()):
    #function to analyze and plot the nosepoking behavior

    startdir = os.getcwd();#os.getcwd is like dir in matlab
    if workdir != startdir:
        os.chdir(workdir)
    
    dname, basename = os.path.split(workdir); 
    sessionStr = sio.loadmat('sessionStr.mat')
    fname = basename+'.txt'
    
    Lpokes = getEventTimes('leftPokeEntry',fname);
    Rpokes = getEventTimes('rightPokeEntry',fname);
    Ipokes = getEventTimes('initPokeEntry',fname);
    Lrewards = getEventTimes('leftReward_nL',fname);
    Rrewards = getEventTimes('rightReward_nL',fname);
    
    trialStarts = getEventTimes('TrialAvailable',fname);
    
    PokePlot(sessionStr,trialStarts,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards)
    os.chdir(startdir)


# %%processing

# testing
#fname = 'DIR94F212_190107_134857.txt';
#basename = fname[0:-4];
#textString = 'leftReward_nL';

makePokePlot(os.getcwd())

