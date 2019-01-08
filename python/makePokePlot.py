# -*- coding: utf-8 -*-
"""
Created on Tue Jan  8 13:31:45 2019

@author: Eliezyer de Oliveira
"""

#libraries
import numpy as np

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
                T = np.empty(c);
                aux = tempLine.find(';');
                T = int(tempLine[0:aux]);
                c += 1;
            else:
                T = np.append(T,int(tempLine[0:aux]));
    return T;





# %% testing

fname = 'DIR102M598_190107_135328.txt';
textString = 'leftReward_nL';
T = getEventTimes(textString,fname);


