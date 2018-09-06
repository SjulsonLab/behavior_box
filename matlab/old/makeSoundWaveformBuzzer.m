% script to generate sound waveforms for the arduino Due

dt = 5e-6; % about 5 microseconds if using the timer
seqLen = 20000; % 100 ms 

compr = 5; % compress by this factor

timevec = 0:dt:dt*seqLen;
timevec = timevec(1:seqLen);

fname = 'arduino_waveform_buzzer.h';

% cd('/Users/luke/Google Drive/lab-shared/lab_equipment/operantBoxes/matlab')


[Y, fs] = audioread('Wrong-answer-sound-effect.mp3');
Y = Y(:,1);
dt_y = 1/fs ./ compr;

timevec_y = 0:dt_y:dt_y*length(Y);
timevec_y = timevec_y(1:length(Y));

buzzWaveform = interp1(timevec_y - (0.2/compr), Y, timevec);



middle = 4096/2; % for 12-bit DAC on arduino Due
buzz2 = middle + middle/3 * zscore(buzzWaveform);
buzz2(buzz2<0) = 0;
buzz2(buzz2>4095) = 4095;
buzz2 = round(buzz2);


% print out seqLen to file
fid = fopen(fname, 'wt');

% fprintf(fid, 'const int seqLen = %d;\n\n', seqLen); % already declared
% this in the file with the other waveforms

% print out buzzer waveform to file
fprintf(fid, 'const int PROGMEM buzzer[] = {');
for idx = 1:seqLen-1
    fprintf(fid, '%d, ', buzz2(idx));
end
fprintf(fid, '%d};\n\n', buzz2(end));

fclose(fid);


