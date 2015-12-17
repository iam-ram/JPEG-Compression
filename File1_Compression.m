%ECE 508 Project 1 - JPEG Compression

clear;
clc;
%load image array already saved into the current folder
%lena512.mat = imread('lena512').bmp;
%save lena512.mat;
disp('Part 1 : Compression');
disp('*****************************************************************');
load lena512
load ACCode
load DCCode
load ACCodeLength
load DCCodeLength
load LUM

%convert from uint8 to double
lena_Mat = double(lena512);
row = length(lena_Mat(:,1))/8;
col = length(lena_Mat(1,:))/8;
disp('Step 1: Image loaded successfully');
% Level shifting to make the image pixel values centered to zero
lena_Mat = lena_Mat - 2^7;

disp('Step 2: Image level shifted to [-128,128]. Succcessful');

%perform DCT - 8 X 8 block
% FDCT for row = col = 8
% S(u,v)=(2/root(row*col))*c(k)*c(l)*sigma(i=0:row-1)sigma(j=0:col-1)y(i,j)cos(pi(2i+1)k/(2*row))cos(pi(2j+1)l/(2*col))
% S(u,v)=(1/4)*c(k)*c(l)*sigma(i=0:7)sigma(j=0:7)y(i,j)cos(pi(2i+1)k/(16))cos(pi(2j+1)l/(16))
% where c(u)=1/root(2) if u=0
%            = 1       if u>0

DCT_Mat = zeros(length(lena_Mat));
Cu = [1/sqrt(2) 1 1 1 1 1 1 1];
Cv = [1/sqrt(2) 1 1 1 1 1 1 1];

for c=0:col-1
    for r=0:row-1
        for u=c*8:c*8+7
            for v=r*8:r*8+7
                for i=c*8:c*8+7
                    for j=r*8:r*8+7
                        DCT_Mat(v+1,u+1) = DCT_Mat(v+1,u+1) + Cu(u-8*c+1)*Cv(v-8*r+1)*lena_Mat(j+1,i+1)*cos((2*(i-8*c)+1)*(u-8*c)*pi/16)*cos((2*(j-8*r)+1)*(v-8*r)*pi/16)/4;
                    end
                end
            end
        end
    end
end

disp('Step 3: 8X8 block DCT successful');

% perform quantization
% Since Lena.bmp is black and white we just consider the luminance component not the chrominance component
% Luminance matrix (8 X 8) used to Normalize the DCT Matrix is given by

%LUM_Mat=[16 11 10 16 24 40 51 61       
%         12 12 14 19 26 58 60 55
%         14 13 16 24 40 57 69 56
%         14 17 22 29 51 87 80 62
%         18 22 37 56 68 109 103 77
%         24 35 55 64 81 104 113 92
%         49 64 78 87 103 121 120 101
%         72 92 95 98 112 100 103 99];

%Quantization Factor 
Qk=8;
LUM=Qk*LUM;
for c=0:col-1
    for r=0:row-1
        for u=c*8:c*8+7
            for v=r*8:r*8+7
                DCT_Mat(v+1,u+1) = DCT_Mat(v+1,u+1)/LUM(v-r*8+1,u-c*8+1);
            end
        end
    end
end

DCT_Mat = round(DCT_Mat);

disp('Step 4: Quantization Successful');

% DCT Mat received here is a set of 64 values called has DCT coefficients
% One of it is called as DC coeff and others is called as AC coeff

% Zig-Zaging of quantized DCT sequence
ZZ_Mat = zeros(1);
n=0;
for r=0:row-1   
    for c=0:col-1
        k = 1;
        n = n+1;
        for i=1:8
            for j=1:i
                if mod(i,2)
                    ZZ_Mat(n,k) = DCT_Mat(8*r+i-j+1,8*c+j);
                else ZZ_Mat(n,k) = DCT_Mat(8*r+j,8*c+i-j+1);
                end
            k=k+1;
            end
        end
        for i=7:-1:1         
            for j=1:i
                if mod(i,2)
                    ZZ_Mat(n,k) = DCT_Mat(8*r+9-j,8*c+8-i+j);
                else ZZ_Mat(n,k) = DCT_Mat(8*r+8-i+j,8*c+9-j);
                end
                k=k+1;
            end
        end
    end
end

disp('Step 5: Zig-Zaging of Quantized sequenced successful');

% Previous Quantized DC coefficient is used to predict the current
% quantized DC coefficients . 

for i = 2:length(ZZ_Mat(:,1))
    ZZ_Mat(i,1) = ZZ_Mat(i,1) - ZZ_Mat(i-1,1);
end
% run length coding algorithm calculated for 1 DC and 63 AC components 
rlc = zeros(length(ZZ_Mat(:,1)),64,2);
for r=1:length(ZZ_Mat(:,1))
    
    % RLC for DC
    rlc(r,1,1) = ZZ_Mat(r,1);
    run_val = 0;
    var = 2;
    % RLC for AC
    for c=2:length(ZZ_Mat(1,:))
        if ZZ_Mat(r,c) ~= 0            % Find rlc for AC coeffs
            while run_val > 15              % Run value is no more than 15              
                rlc(r,var,1) = 0;     
                rlc(r,var,2) = 15;    
                run_val = run_val - 15;
                var = var + 1;
            end
            rlc(r,var,1) = ZZ_Mat(r,c);
            rlc(r,var,2) = run_val;
            var = var+1;
            run_val = 0;
        else
            run_val = run_val+1;
        end
    end
end
% Run length encodin is complete

% Finding the category of each encoded value   
rlc_cat = zeros(size(rlc(:,:,1)));
for c=1:length(rlc(1,:,1))
    for r=1:length(rlc(:,1,1))
        for n=0:11
            if abs(rlc(r,c,1))/(2^n) < 1
                rlc_cat(r,c) = n;
                break
            end
        end
    end
end  

disp('Step 6: Run length Encoding Successful');
%calc length of  bit stream for transmission
im_sz = 0;
for r=1:length(rlc_cat(:,1))
    im_sz = im_sz + DCCodeLength(rlc_cat(r,1)+1) + rlc_cat(r,1);
    for c=2:length(rlc_cat(1,:))
        im_sz = im_sz + ACCodeLength(rlc(r,c,2)+1,rlc_cat(r,c,1)+1);
        im_sz = im_sz + rlc_cat(r,c,1);
        if rlc(r,c,1) == 0 && rlc(r,c,2) == 0
            break
        end
    end
end

% Perform Huffman coding
bit_stream = zeros(1,im_sz);
k = 1;
for r=1:length(rlc_cat(:,1))
    cat = rlc_cat(r,1);
    code = DCCode{cat+1};
    byte = de2bi(abs(rlc(r,1,1)),'left-msb');
    if rlc(r,1,1) < 0
        byte = abs(byte-1);
    end
    newword = horzcat(code,byte(1:cat));
    bit_stream(k:k+length(newword)-1) = newword;
    k = k + length(newword);

    % Huffman-encoding the AC values
    for c=2:length(rlc_cat(1,:))
        cat = rlc_cat(r,c);
        run = rlc(r,c,2);
        code = ACCode{run+1}{cat+1};
        byte = de2bi(abs(rlc(r,c,1)),'left-msb');
        if rlc(r,c,1) < 0
            byte = abs(byte-1);
        end
        newword = horzcat(code,byte(1:cat));
        bit_stream(k:k+length(newword)-1) = newword;
        k = k + length(newword);
        
        if cat == 0 && run == 0             %EndOfBlockCode
            break
        end
    end
end
disp('Step 7: Huffman Encoding Successful');

save('bit_stream.mat','bit_stream');

disp('Step 8: JPEG Compression bit streamed saved Successfully');
disp('*****************************************************************');
disp('*****************************************************************');
