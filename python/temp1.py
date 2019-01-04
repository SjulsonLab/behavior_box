#function session_info = setCueLengthsPhase4(session_info, nTrial, totalRewards)

# function session_info = setCueLengthsPhase4(session_info, nTrial, totalRewards)
#
# for setting cue delivery parameters for stage 4 training, where they vary
# as a function of the number of rewards the animal has received. Also
# works for stage 5.
#
# Luke Sjulson, 2018-10-29

# ## for testing
# Ntrial = 1)
# totalRewards = 300)
# session_info['fakeRewards'] = 1)
# session_info.numRewardsToAdvance = 10)


## start of actual function

# 1: hold until end, 10 correct trials
# 2: add 25 ms precue, 25 ms postcue. Increment precue every 10
# correct trials until it's 75 ms.
# 3: increase interOnsetInterval by 10 ms every 10 correct trials
# until it's 125 ms

totalRewards = 33
session_info = {'preCueLength': [], 'postCueLength': [], 'interOnsetInterval': [], 'numRewardsToAdvance': 10, 'trainingPhase': 4, 'fakeRewards': 10}






if session_info['trainingPhase'] == 4:
	R = session_info['numRewardsToAdvance']
	if (totalRewards + session_info['fakeRewards']) < R:
		# no extra delays
		session_info['preCueLength'].append(0)
		session_info['postCueLength'].append(0)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >1*R and (totalRewards + session_info['fakeRewards']) <= 2*R:
		# add precue and postcue 25
		session_info['preCueLength'].append(25)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >2*R and (totalRewards + session_info['fakeRewards']) <= 3*R:
		# precue = 35
		session_info['preCueLength'].append(35)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >3*R and (totalRewards + session_info['fakeRewards']) <= 4*R:
		# precue = 45
		session_info['preCueLength'].append(45)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >4*R and (totalRewards + session_info['fakeRewards']) <= 5*R:
		# precue = 55
		session_info['preCueLength'].append(55)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >5*R and (totalRewards + session_info['fakeRewards']) <= 6*R:
		# precue = 65
		session_info['preCueLength'].append(65)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >6*R and (totalRewards + session_info['fakeRewards']) <= 7*R:
		# precue = 75
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(0)	
	elif (totalRewards + session_info['fakeRewards']) >7*R and (totalRewards + session_info['fakeRewards']) <= 8*R:
		# IOI = 15
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(15)
	elif (totalRewards + session_info['fakeRewards']) >8*R and (totalRewards + session_info['fakeRewards']) <= 9*R:
		# IOI = 25
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(25)
	elif (totalRewards + session_info['fakeRewards']) >9*R and (totalRewards + session_info['fakeRewards']) <= 10*R:
		# IOI = 35
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(35)
	elif (totalRewards + session_info['fakeRewards']) >10*R and (totalRewards + session_info['fakeRewards']) <= 11*R:
		# IOI = 45
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(45)
	elif (totalRewards + session_info['fakeRewards']) >11*R and (totalRewards + session_info['fakeRewards']) <= 12*R:
		# IOI = 55
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(55)
	elif (totalRewards + session_info['fakeRewards']) >12*R and (totalRewards + session_info['fakeRewards']) <= 13*R:
		# IOI = 65
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(65)
	elif (totalRewards + session_info['fakeRewards']) >13*R and (totalRewards + session_info['fakeRewards']) <= 14*R:
		# IOI = 75
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(75)
	elif (totalRewards + session_info['fakeRewards']) >14*R and (totalRewards + session_info['fakeRewards']) <= 15*R:
		# IOI = 85
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(85)
	elif (totalRewards + session_info['fakeRewards']) >15*R and (totalRewards + session_info['fakeRewards']) <= 16*R:
		# IOI = 95
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(95)
	elif (totalRewards + session_info['fakeRewards']) >16*R and (totalRewards + session_info['fakeRewards']) <= 17*R:
		# IOI = 105
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(105)
	elif (totalRewards + session_info['fakeRewards']) >17*R and (totalRewards + session_info['fakeRewards']) <= 18*R:
		# IOI = 115
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(115)
	elif (totalRewards + session_info['fakeRewards']) >18*R:
		# IOI = 125
		session_info['preCueLength'].append(75)
		session_info['postCueLength'].append(25)
		session_info['interOnsetInterval'].append(125)

	
	# display status for phase 4
	print('Animal has ' + str(totalRewards) + ' real rewards and ' + str(session_info['fakeRewards']) + ' fake ones. precue = ' + \
	str(session_info['preCueLength'][-1]) + ', postcue = ' + str(session_info['postCueLength'][-1]) + \
	', IOI = ' + str(session_info['interOnsetInterval'][-1]))
	
elif session_info['trainingPhase'] == 5:
	session_info['preCueLength'].append(75)
	session_info['postCueLength'].append(25)
	session_info['interOnsetInterval'].append(125)
else:
	raise Exception('session_info.trainingPhase needs to be 4 or 5 to use this function')




