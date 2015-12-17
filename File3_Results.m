%ECE 508 Project 1 - Code to calculate jpeg compression ratio
clear;
clc;

disp('Part 3: Calculations and Results');
disp('*****************************************************************');
disp('Quantization used in the JPEG compression procedure is Qk = 1');

load lena512
load bit_stream
load IDCT_Mat

comp_ratio = (length(lena512)^2)*8/length(bit_stream)

error = double(uint8(IDCT_Mat) - lena512);
Psignal = sum(sum(IDCT_Mat.*IDCT_Mat))/(length(IDCT_Mat)^2);
Pnoise = sum(sum(error.*error))/(length(error)^2);
SNRdb = 10*log10(Psignal/Pnoise)
SNRmaxdb = 10*log10((max(max(IDCT_Mat))^2)/Pnoise)

figure(1)
imshow(IDCT_Mat,[0 255])
title('Reconstructed image')

figure(2)
imshow(error,[0 255])
title('Error image of compression process')
