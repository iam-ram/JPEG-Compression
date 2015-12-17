%ECE 508 Project 1 - Image DeCompression

clc;

disp('Part 2: Reconstruction of Image');
disp('*****************************************************************');

disp('step 10: bit_stream input for reconstruction successful');
load lena512
load bit_stream
load ACCode
load DCCode
load ACCodeLength
load DCCodeLength
load LUM
row = 64;
col = 64;

% create dummy matrix to decode the bit streaming
ACdummy = zeros(16,11);
for i=1:16
    for j=1:11
        if isempty(ACCode{i}{j})
            ACdummy(i,j) = -1;
        else
            ACdummy(i,j) = bi2de(ACCode{i}{j},'left-msb');
        end
    end
end

rec_rlc = zeros(4096,64,2);
rec_rlc_cat = zeros(4096,64);

cur_bit_pos = 1;
ro = 1;                             %number of rows of rlc
flag = 0;                           %to check the while loop and reset the flag
ACflag = 0;
%this logic is used to decode the dc components by cross check all the diff
%word length with next set of bits to get a matching code_word

while cur_bit_pos < length(bit_stream)
    co = 1;                                     %number of columns of rlc
    
    for len=2:16
        cat = find(DCCodeLength == len);
        code_word = bit_stream(cur_bit_pos:len+cur_bit_pos-1);
        for i=1:length(cat)
            temp=cat(i);
            if isequal(code_word,DCCode{temp})
                cur_bit_pos = cur_bit_pos + len;
                if temp-1 == 0                          % no more value in encoded after that code word
                    res = 0;
                else
                    res = bit_stream(cur_bit_pos:temp-2+cur_bit_pos);
                    cur_bit_pos = cur_bit_pos + temp - 1;
                    if res(1) == 0
                        res = -bi2de(abs(res-1),'left-msb');
                    else
                        res = bi2de(res,'left-msb');
                    end
                end
                
                rec_rlc(ro,co,1) = res;
                rec_rlc_cat(ro,co) = temp-1;
                co = co + 1;
                flag = 1;
                break
            end
        end
        
        if flag
            flag = 0;
        end
    end
    
    while ACflag == 0
        for len=2:16
            ACword = bit_stream(cur_bit_pos:len+cur_bit_pos-1);
            ACwordnum = bi2de(ACword,'left-msb');
            [run,cat] = find(ACdummy == ACwordnum);
            for i=1:length(run)
                runvar = run(i);
                catvar = cat(i);
                if isequal(ACword,ACCode{runvar}{catvar})
                    cur_bit_pos = cur_bit_pos + len;
                    
                    if (runvar == 1 && catvar == 1)
                        ACflag = 1;
                        flag = 1;
                        break
                    end
                    
                    if catvar-1==0
                        res = 0;
                    else
                        res = bit_stream(cur_bit_pos:catvar-2+cur_bit_pos);
                        cur_bit_pos = cur_bit_pos + catvar - 1;
                        
                        if res(1) == 0
                            res = -bi2de(abs(res-1),'left-msb');
                        else
                            res = bi2de(res,'left-msb');
                        end
                    end
                    
                    rec_rlc(ro,co,1) = res;
                    rec_rlc(ro,co,2) = runvar - 1;
                    rec_rlc_cat(ro,co) = catvar - 1;
                    flag = 1;
                    co = co + 1;
                    break
                end
                if flag
                    break
                end
            end
            
            if flag
                flag = 0;
                break;
            end
        end
    end
    
    ro = ro + 1;
    co = 1;
    ACflag = 0;
end
disp('Step 11: Decoding DC, AC words Successful');

dec_rlc = zeros(1,64);
for r=1:length(rec_rlc(:,1,1))
    dec_rlc(r,1) = rec_rlc(r,1,1);
    ck = 2;
    for c=2:length(rec_rlc(1,:,1))
        if rec_rlc(r,c,1) == 0
            break
        end
        for n=1:rec_rlc(r,c,2)
            dec_rlc(r,ck) = 0;
            ck = ck+1;
        end
        dec_rlc(r,ck) = rec_rlc(r,c,1);
        ck = ck+1;
    end
end
disp('Step 12: Run length decoding Successful');

% Remove differential coding in DC component
for i=length(dec_rlc(:,1)):-1:2
    dec_rlc(i,1) = dec_rlc(i,1) + dec_rlc(i-1,1);
end

%LUM_Mat=[16 11 10 16 24 40 51 61       
%         12 12 14 19 26 58 60 55
%         14 13 16 24 40 57 69 56
%         14 17 22 29 51 87 80 62
%         18 22 37 56 68 109 103 77
%         24 35 55 64 81 104 113 92
%         49 64 78 87 103 121 120 101
%         72 92 95 98 112 100 103 99];


% Remove ZigZag fromt he received dec_rlc
IZZ_Mat = zeros();

n=0;
for r=0:row-1   
    for c=0:col-1
        k = 1;
        n = n+1;
        for i=1:8
            for j=1:i
                if mod(i,2)
                    IZZ_Mat(8*r+i-j+1,8*c+j) = dec_rlc(n,k);
                else
                    IZZ_Mat(8*r+j,8*c+i-j+1) = dec_rlc(n,k);
                end
            k=k+1;
            end
        end
        for i=7:-1:1         
            for j=1:i
                if mod(i,2)
                    IZZ_Mat(8*r+9-j,8*c+8-i+j) = dec_rlc(n,k);
                else
                    IZZ_Mat(8*r+8-i+j,8*c+9-j) = dec_rlc(n,k);
                end
                k=k+1;
            end
        end
    end
end

disp('Step 13: Removing Zig-Zag operation on matrix Succesful');
% Reverse Quantize for the matrix received
Qk=8;
LUM=Qk*LUM;
IQ_Mat = IZZ_Mat;
for c=0:col-1
    for r=0:row-1
        for u=c*8:c*8+7
            for v=r*8:r*8+7
                IQ_Mat(v+1,u+1) = IQ_Mat(v+1,u+1)*LUM(v-r*8+1,u-c*8+1);
            end
        end
    end
end

disp('Step 14: De-Quantization performed Successful');

% Perform inverse DCT - 8 X 8 Block
IDCT_Mat = zeros(length(IQ_Mat));
Cu = [1/sqrt(2) 1 1 1 1 1 1 1];
Cv = [1/sqrt(2) 1 1 1 1 1 1 1];

for c=0:col-1
    for r=0:row-1
        for u=c*8:c*8+7
            for v=r*8:r*8+7
                for i=c*8:c*8+7
                    for j=r*8:r*8+7
                        IDCT_Mat(v+1,u+1) = IDCT_Mat(v+1,u+1) + Cu(i-8*c+1)*Cv(j-8*r+1)*IQ_Mat(j+1,i+1)*cos((2*(u-8*c)+1)*(i-8*c)*pi/16)*cos((2*(v-8*r)+1)*(j-8*r)*pi/16)/4;
                    end
                end
            end
        end
    end
end

% level shifting from [-128,+128] to [0,255]
IDCT_Mat = IDCT_Mat + 2^7;
IDCT_Mat = round(IDCT_Mat);

save('IDCT_Mat.mat','IDCT_Mat');

disp('Step 15: Inverse DCT Successful');



