# JPEG-Compression
The primary objective of this Matlab project is to compress a preloaded image using JPEG compression technique. This image will be in a set of binary codes (1’s and 0’s). The compressed image is then decompressed to construct the original image. The decompression and reconstruction will introduce some noise into the image, which implies the original image and the final output image will not be exactly same. In this project, the signal to noise ratio from the image compression technique applied is also calculated.

Procedure

1.	The image is then converted to matrix form to start perform the calculations. 

2.	8X8 DCT is applied upon the image 
 
3.	Quantization is performed. In my algorithm I have used Quantization factor Qk =1 by default. 


4.	Variable run length coding applied over the quantized bits to the DC(1 number) and AC coefficients(63 number). 

5.	The output bits are decoded to bit_stream and saved it into output file.  Start reconstructing image using the ‘bit_stream’. At the receiver side we will perform the above operations in reverse order to recover the original image. 
