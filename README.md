# JPEG-Compression
The primary objective of this Matlab project is to compress a preloaded image using JPEG compression technique. This image will be in a set of binary codes (1’s and 0’s). The compressed image is then decompressed to construct the original image. The decompression and reconstruction will introduce some noise into the image, which implies the original image and the final output image will not be exactly same. In this project, the signal to noise ratio from the image compression technique applied is also calculated.

Procedure

1.	lena512.bmp Image is loaded into the system. The image is then converted to matlab matrix form to start perform the calculations. Initially, level shifting is performed to change it from [0,255] to [-128,128] to make all the pixel values ‘0’ centered.
2.	8X8 DCT is applied upon the image using the equation 
 

3.	Quantization is performed. In my algorithm I have used Quantization factor Qk =1 by default. Also since the input image is a black and white one, I have just used the Luminance Component to do the quantization and not considered the Chrominance components. 
 		


4.	Variable run length coding applied over the quantized bits to the DC(1 number) and AC coefficients(63 number). Run length coding is done with an upper limit of run zeroes as 15, because, a sequence of 16 zeroes means all the elements in the block are zero, indicating end of block encoding. DCCode.mat & ACCode.mat contain the code words used to represent the DC and AC components respectively. DCCodeLength.mat, ACCodeLength.mat are matrices used to store the length of the code words belonging to each category. 
For eg: Length of word corresponding to each category {c} with run zeroes {r} can be found in ACCodeLength({r}{c}).
 
5.	The output bits are decoded to bit_stream and saved it into output file.  Start reconstructing image using the ‘bit_stream’. At the receiver side we will perform the above operations in reverse order to recover the original image. There is an additional AC dummy table prepared as in the part 1 which has decimal representation of each code word in ACCode, to find the match in code words and bits in bit_stream.
