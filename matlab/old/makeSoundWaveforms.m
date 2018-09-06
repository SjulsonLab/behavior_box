% script to generate sound waveforms for the arduino Due

dt = 5e-6; % about 5 microseconds if using the timer
seqLen = 20000; % 100 ms 
lowFreqHz = 2000;
highFreqHz = 10000;
fname = 'arduino_waveforms.h';

fid = fopen(fname, 'wt');


t = 0:dt:dt*(seqLen-1);

middle = 4096/2; % for 12-bit DAC on arduino Due

whiteNoise = middle + middle/6 * randn(seqLen, 1);
lowFreq = middle + middle/2*sin(2*pi*t*lowFreqHz);
highFreq = middle + middle/2*sin(2*pi*t*highFreqHz);

whiteNoise(whiteNoise<0) = 0;
whiteNoise(whiteNoise>4095) = 4095;
whiteNoise = round(whiteNoise);

lowFreq(lowFreq<0) = 0;
lowFreq(lowFreq>4095) = 4095;
lowFreq = round(lowFreq);

highFreq(highFreq<0) = 0;
highFreq(highFreq>4095) = 4095;
highFreq = round(highFreq);

% print out seqLen to file
fprintf(fid, 'const int seqLen = %d;\n\n', seqLen);

% print out whiteNoise to file
fprintf(fid, 'const int PROGMEM whiteNoise[] = {');
for idx = 1:seqLen-1
    fprintf(fid, '%d, ', whiteNoise(idx));
end
fprintf(fid, '%d};\n\n', whiteNoise(end));

% print out lowFreq to file
fprintf(fid, 'const int PROGMEM lowFreq[] = {');
for idx = 1:seqLen-1
    fprintf(fid, '%d, ', lowFreq(idx));
end
fprintf(fid, '%d};\n\n', lowFreq(end));

% print out highFreq to file
fprintf(fid, 'const int PROGMEM highFreq[] = {');
for idx = 1:seqLen-1
    fprintf(fid, '%d, ', highFreq(idx));
end
fprintf(fid, '%d};\n\n', highFreq(end));



fclose(fid);



% break
% close all
% histogram(whiteNoise, 'normalization', 'probability');
% hold on
% histogram(lowFreq, 'normalization', 'probability');
% 
% 
% close all
% plot(t, lowFreq, 'r');
% hold on
% plot(t, highFreq, 'g');

