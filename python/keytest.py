
import time
import msvcrt

keyqueue = ['a', 'b', 'c', 'd', 'e']

exit = 0
while exit == 0:
    time.sleep(2)
    print('a')
    while msvcrt.kbhit():
        x = msvcrt.getch()
        keyqueue.append(x)
        keyqueue.pop(0)

        print('keyqueue is: ' + str(keyqueue))
        if keyqueue[0] == keyqueue[1] == keyqueue[2] == keyqueue[3] == keyqueue[4] == 'x':
        	exit = 1
        	