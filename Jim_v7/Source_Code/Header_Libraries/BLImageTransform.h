#pragma once
#ifndef BLImageTransform_H_
#define BLImageTransform_H_

#include <iostream>
#include <vector>
#include <cmath>
#include <numeric>
#include <algorithm>
#include "mkl.h"
#include "ipp.h"



class alignImages_32f {
	int upscalefactor, width, height, nop;

	//vector<float> gaus1, gaus2;
	IppiSize roiSize;
	IppiDFTSpec_R_32f *pDFTSpec;
	Ipp8u  *pDFTInitBuf, *pDFTWorkBuf;
	int sizeDFTSpec, sizeDFTInitBuf, sizeDFTWorkBuf;

	std::vector<float> fgaus1, fgaus2, fcc, rcc, singlepixelrcc;

	IppiSize roiSize2;
	IppiDFTSpec_R_32f *pDFTSpec2;
	Ipp8u  *pDFTInitBuf2, *pDFTWorkBuf2;
	int sizeDFTSpec2, sizeDFTInitBuf2, sizeDFTWorkBuf2;

	std::vector<Ipp32fc> exfcc, expaddedfcc, cexfcc;
	std::vector<float>paddedfcc;

	int max1dpos;


	int dftshift;
	int nor;//also noc
	int roff, coff;
	std::vector<Ipp32fc>kernc, kernr;
	std::vector<float> intij1, intj1, intjr1, intjimr1, intsin1, intcos1;
	std::vector<float> intij2, intj2, intjc2, intjimc2, intsin2, intcos2;

	std::vector<float> rexfcc, iexfcc, interre, interim, output;

	double estoffsetx, estoffsety;

public:
	alignImages_32f(int upscalefactorin, int widthin, int heightin);
	~alignImages_32f();

	void imageAlign(std::vector<float>& gaus1, std::vector<float>& gaus2, int maxShiftin = 10000000);
	void imageAligntopixel(std::vector<float>& gaus1, std::vector<float>& gaus2, int maxShiftin = 10000000);

	void preloadImage(std::vector<float>& gaus1);
	void imageAligntopixelpreloaded(std::vector<float>& gaus2, int maxShiftin = 10000000);

	float max1dval;
	double offsetx, offsety;
};



inline alignImages_32f::~alignImages_32f() {
	if (pDFTWorkBuf) ippFree(pDFTWorkBuf);
	if (pDFTSpec) ippFree(pDFTSpec);
}

inline alignImages_32f::alignImages_32f(int upscalefactorin, int widthin, int heightin) {
	upscalefactor = upscalefactorin;

	width = widthin;
	height = heightin;
	nop = width*height;
	//gaus1 = std::vector<float>(nop); gaus2= std::vector<float>(nop);

	roiSize.width = width;
	roiSize.height = height;


	ippiDFTGetSize_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, &sizeDFTSpec, &sizeDFTInitBuf, &sizeDFTWorkBuf);
	// Alloc DFT buffers
	pDFTSpec = (IppiDFTSpec_R_32f*)ippsMalloc_8u(sizeDFTSpec);
	pDFTInitBuf = ippsMalloc_8u(sizeDFTInitBuf);
	pDFTWorkBuf = ippsMalloc_8u(sizeDFTWorkBuf);

	// Initialize DFT
	ippiDFTInit_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, pDFTSpec, pDFTInitBuf);
	if (pDFTInitBuf) ippFree(pDFTInitBuf);

	fgaus1 = std::vector<float>(nop); fgaus2 = std::vector<float>(nop); fcc = std::vector<float>(4 * nop); rcc = std::vector<float>(4 * nop);

	singlepixelrcc = std::vector<float>(nop);

	roiSize2.width = 2 * width;
	roiSize2.height = 2 * height;

	//roiSize2 = { 2 * width, 2 * height };
	ippiDFTGetSize_R_32f(roiSize2, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, &sizeDFTSpec2, &sizeDFTInitBuf2, &sizeDFTWorkBuf2);
	// Alloc DFT buffers
	pDFTSpec2 = (IppiDFTSpec_R_32f*)ippsMalloc_8u(sizeDFTSpec2);
	pDFTInitBuf2 = ippsMalloc_8u(sizeDFTInitBuf2);
	pDFTWorkBuf2 = ippsMalloc_8u(sizeDFTWorkBuf2);

	// Initialize DFT
	ippiDFTInit_R_32f(roiSize2, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, pDFTSpec2, pDFTInitBuf2);
	if (pDFTInitBuf2) ippFree(pDFTInitBuf2);

	exfcc = std::vector<Ipp32fc>(nop); expaddedfcc = std::vector<Ipp32fc>(4 * nop); cexfcc = std::vector<Ipp32fc>(nop);
	paddedfcc = std::vector<float>(4 * nop);


	dftshift = (int)ceil(upscalefactor*1.5) / 2;
	nor = ceil(upscalefactor*1.5);//also noc


	intij1 = std::vector<float>(nor*width); intj1 = std::vector<float>(nor*width); intjr1 = std::vector<float>(nor*width); intjimr1 = std::vector<float>(nor*width); intsin1 = std::vector<float>(nor*width); intcos1 = std::vector<float>(nor*width);
	intij2 = std::vector<float>(nor*height); intj2 = std::vector<float>(nor*height); intjc2 = std::vector<float>(nor*height); intjimc2 = std::vector<float>(nor*height); intsin2 = std::vector<float>(nor*height); intcos2 = std::vector<float>(nor*height);
	double someconst1 = -2 * 3.141592653589 / (width*upscalefactor), someconst2 = -2 * 3.141592653589 / (height*upscalefactor);

	for (int i = 0; i < nor; i++)for (int j = 0; j < width; j++) {
		intj1[i + j*nor] = j < (width + 1) / 2 ? someconst1*j : someconst1*(j - width);
		intij1[i + j*nor] = j < (width + 1) / 2 ? someconst1*j*i : someconst1*(j - width)*i;
	}

	for (int i = 0; i < nor; i++)for (int j = 0; j < height; j++) {
		intj2[i*height + j] = j < (height + 1) / 2 ? someconst2*j : someconst2*(j - height);
		intij2[i*height + j] = j < (height + 1) / 2 ? someconst2*j*i : someconst2*(j - height)*i;
	}

	rexfcc = std::vector<float>(nop); iexfcc = std::vector<float>(nop); interre = std::vector<float>(nor*height); interim = std::vector<float>(nor*height); output = std::vector<float>(nor*nor);


}

inline void alignImages_32f::preloadImage(std::vector<float>& gaus1) {
	ippiDFTFwd_RToPack_32f_C1R(&gaus1[0], width * sizeof(float), &fgaus1[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);
}

inline void alignImages_32f::imageAligntopixelpreloaded(std::vector<float>& gaus2, int maxShiftin) {
	ippiDFTFwd_RToPack_32f_C1R(&gaus2[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	//find cross correlation
	ippiMulPackConj_32f_C1R(&fgaus1[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), &fcc[0], width * sizeof(float), roiSize);

	ippiDFTInv_PackToR_32f_C1R(&fcc[0], width * sizeof(float), &singlepixelrcc[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	int maxShift = std::min(width / 2, maxShiftin);
	int intMaxShift = (int)maxShift;

	IppiSize quarterROI{ intMaxShift ,intMaxShift };
	int max1x, max2x, max3x, max4x, max1y, max2y, max3y, max4y;
	float max1, max2, max3, max4;
	ippiMaxIndx_32f_C1R(&singlepixelrcc[0], width * sizeof(float), quarterROI, &max1, &max1x, &max1y);
	ippiMaxIndx_32f_C1R(&singlepixelrcc[width - maxShift], width * sizeof(float), quarterROI, &max2, &max2x, &max2y);
	ippiMaxIndx_32f_C1R(&singlepixelrcc[(height - maxShift)*width], width * sizeof(float), quarterROI, &max3, &max3x, &max3y);
	ippiMaxIndx_32f_C1R(&singlepixelrcc[(height - maxShift) * width + width - maxShift], width * sizeof(float), quarterROI, &max4, &max4x, &max4y);
	if (max2 > max1) {
		max1 = max2;
		max1x = max2x - maxShift;//max1x = max2x - maxShift - 1;
		max1y = max2y;
	}
	if (max3 > max1) {
		max1 = max3;
		max1x = max3x;
		max1y = max3y - maxShift;//max1y = max3y - maxShift - 1;
	}
	if (max4 > max1) {
		max1 = max4;
		max1x = max4x - maxShift;//max1x = max4x - maxShift - 1;
		max1y = max4y - maxShift;//max1y = max4y - maxShift - 1;
	}

	max1dval = max1;
	offsetx = max1x;
	offsety = max1y;

}

inline void alignImages_32f::imageAligntopixel(std::vector<float>& gaus1, std::vector<float>& gaus2, int maxShiftin) {
	ippiDFTFwd_RToPack_32f_C1R(&gaus1[0], width * sizeof(float), &fgaus1[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);
	ippiDFTFwd_RToPack_32f_C1R(&gaus2[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	//find cross correlation
	ippiMulPackConj_32f_C1R(&fgaus1[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), &fcc[0], width * sizeof(float), roiSize);

	ippiDFTInv_PackToR_32f_C1R(&fcc[0], width * sizeof(float), &singlepixelrcc[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	ippsMaxIndx_32f(&singlepixelrcc[0], nop, &max1dval, &max1dpos);
	offsetx = max1dpos % (width);
	offsety = max1dpos / (width);
	if (offsetx > (width) / 2)offsetx += -width;
	if (offsety > (height) / 2)offsety += -height;

	/*
		ippsMaxIndx_32f(&singlepixelrcc[0], nop, &max1dval, &max1dpos);
		offsetx = max1dpos % (width);
		offsety = max1dpos / (width);
		if (offsetx > (width) / 2)offsetx += -width;
		if (offsety > (height) / 2)offsety += -height;
	*/

	int maxShift = std::min(std::min(width / 2, maxShiftin),height / 2);
	int intMaxShift = (int)maxShift;

		IppiSize quarterROI{ intMaxShift ,intMaxShift };
		int max1x, max2x, max3x, max4x, max1y, max2y, max3y, max4y;
		float max1, max2, max3, max4;
		ippiMaxIndx_32f_C1R(&singlepixelrcc[0], width*sizeof(float), quarterROI, &max1, &max1x, &max1y);
		ippiMaxIndx_32f_C1R(&singlepixelrcc[width- maxShift], width * sizeof(float), quarterROI, &max2, &max2x, &max2y);
		ippiMaxIndx_32f_C1R(&singlepixelrcc[(height-maxShift)*width], width * sizeof(float), quarterROI, &max3, &max3x, &max3y);
		ippiMaxIndx_32f_C1R(&singlepixelrcc[(height - maxShift) * width+ width - maxShift], width * sizeof(float), quarterROI, &max4, &max4x, &max4y);
		if (max2 > max1) {
			max1 = max2;
			max1x = max2x - maxShift;//max1x = max2x - maxShift - 1;
			max1y = max2y;
		}
		if (max3 > max1) {
			max1 = max3;
			max1x = max3x;
			max1y = max3y - maxShift;//max1y = max3y - maxShift - 1;
		}
		if (max4 > max1) {
			max1 = max4;
			max1x = max4x - maxShift;//max1x = max4x - maxShift - 1;
			max1y = max4y - maxShift;//max1y = max4y - maxShift - 1;
		}

		max1dval = max1;
		offsetx = max1x;
		offsety = max1y;

}

inline void alignImages_32f::imageAlign(std::vector<float>& gaus1, std::vector<float>& gaus2, int maxShiftin) {


	// Do the DFT
	ippiDFTFwd_RToPack_32f_C1R(&gaus1[0], width * sizeof(float), &fgaus1[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);
	ippiDFTFwd_RToPack_32f_C1R(&gaus2[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	//find cross correlation
	ippiMulPackConj_32f_C1R(&fgaus1[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), &fcc[0], width * sizeof(float), roiSize);
	//exapand from packed form
	ippiPackToCplxExtend_32f32fc_C1R(&fcc[0], roiSize, width * sizeof(float), &exfcc[0], width * sizeof(Ipp32fc));

	//padd the solution
	for (int i = 0; i < (int)(width + 1) / 2; i++)for (int j = 0; j < (int)(height + 1) / 2; j++) {
		expaddedfcc[i + 2 * width*j].re = 4 * exfcc[i + width*j].re;
		expaddedfcc[i + 2 * width*j].im = 4 * exfcc[i + width*j].im;
	}
	for (int i = ceil(1.5* width); i < 2 * width; i++)for (int j = 0; j < (int)(height + 1) / 2; j++) {
		expaddedfcc[i + 2 * width*j].re = 4 * exfcc[i - width + width*j].re;
		expaddedfcc[i + 2 * width*j].im = 4 * exfcc[i - width + width*j].im;
	}
	for (int i = 0; i < (int)(width + 1) / 2; i++)for (int j = ceil(1.5* height); j < 2 * height; j++) {
		expaddedfcc[i + 2 * width*j].re = 4 * exfcc[i + width*(j - height)].re;
		expaddedfcc[i + 2 * width*j].im = 4 * exfcc[i + width*(j - height)].im;
	}
	for (int i = ceil(1.5* width); i < 2 * width; i++)for (int j = ceil(1.5* height); j < 2 * height; j++) {
		expaddedfcc[i + 2 * width*j].re = 4 * exfcc[i - width + width*(j - height)].re;
		expaddedfcc[i + 2 * width*j].im = 4 * exfcc[i - width + width*(j - height)].im;
	}

	//collapse to packed form
	ippiCplxExtendToPack_32fc32f_C1R(&expaddedfcc[0], 2 * width * sizeof(Ipp32fc), roiSize2, &paddedfcc[0], 2 * width * sizeof(float));
	//inverse transform
	ippiDFTInv_PackToR_32f_C1R(&paddedfcc[0], 2 * width * sizeof(float), &rcc[0], 2 * width * sizeof(float), pDFTSpec2, pDFTWorkBuf2);

	//uncomment to add a max shift


	/*
		ippsMaxIndx_32f(&rcc[0], 4 * nop, &max1dval, &max1dpos);
		estoffsetx = max1dpos % (2 * width);
		estoffsety = max1dpos / (2 * width);
		if (estoffsetx > (2 * width) / 2)estoffsetx += -2 * width;
		if (estoffsety > (2 * height) / 2)estoffsety += -2 * height;

		estoffsetx *= 0.5;
		estoffsety *= 0.5;
	*/

	int maxShift = std::min(width / 2, maxShiftin);
	int intMaxShift = (int)maxShift;
		IppiSize quarterROI{ 2* intMaxShift ,2* intMaxShift };
		int max1x, max2x, max3x, max4x, max1y, max2y, max3y, max4y;
		float max1, max2, max3, max4;
		ippiMaxIndx_32f_C1R(&rcc[0], 2*width * sizeof(float), quarterROI, &max1, &max1x, &max1y);
		ippiMaxIndx_32f_C1R(&rcc[2*width - 2*maxShift], 2*width * sizeof(float), quarterROI, &max2, &max2x, &max2y);
		ippiMaxIndx_32f_C1R(&rcc[(2*height - 2*maxShift) * 2*width], 2*width * sizeof(float), quarterROI, &max3, &max3x, &max3y);
		ippiMaxIndx_32f_C1R(&rcc[(2*height - 2*maxShift) * 2*width + 2*width - 2*maxShift], 2*width * sizeof(float), quarterROI, &max4, &max4x, &max4y);
		//int quad = 1;
		//std::cout << "Max Quads " << max1 << " " << max1x << " " << max1y << " " << max2 << " " << max2x << " " << max2y << " " << max3 << " " << max3x << " " << max3y << " " << max4 << " " << max4x << " " << max4y << " " << std::endl;
		
		if (max2 > max1) {
			//quad = 2;
			max1 = max2;
			//max1x = max2x-2 * maxShift -1;
			max1x = max2x - 2 * maxShift;
			max1y = max2y;
		}
		if (max3 > max1) {
			//quad = 3;
			max1 = max3;
			max1x = max3x;
			//max1y = max3y - 2 * maxShift -1;
			max1y = max3y - 2 * maxShift;
		}
		if (max4 > max1) {
			//quad = 4;
			max1 = max4;
			//max1x = max4x - 2 * maxShift -1;
			//max1y = max4y - 2 * maxShift -1;
			max1x = max4x - 2 * maxShift;
			max1y = max4y - 2 * maxShift;
		}

		//if (max1x != 2*round(estoffsetx)+10 || max1y != 2 * round(estoffsety))std::cout << "error2 " << max1dval- max1 << " " << max1dval << " " << max1 << " " << 2 * round(estoffsetx) << " " << max1x << " " << 2 * round(estoffsety) << " " << max1y << " "<<quad<<"\n";
		estoffsetx = 0.5* max1x;
		estoffsety = 0.5* max1y;


	//std::cout << "Initial estimated offset " << estoffsetx << " " << estoffsety << std::endl;

	ippsConj_32fc_A24(&exfcc[0], &cexfcc[0], nop);
	for (int i = 0; i < nop; i++) {
		rexfcc[i] = cexfcc[i].re;
		iexfcc[i] = cexfcc[i].im;
	}

	roff = (double)dftshift - estoffsetx*upscalefactor;
	coff = (double)dftshift - estoffsety*upscalefactor;


	ippsMulC_32f(&intj1[0], roff, &intjr1[0], nor*width);
	ippsSub_32f(&intij1[0], &intjr1[0], &intjimr1[0], nor*width);
	ippsSinCos_32f_A21(&intjimr1[0], &intsin1[0], &intcos1[0], nor*width);

	//for (int i = 0; i < nor*width; i++) { kernc[i].im = - intsin1[i]; kernc[i].re = intcos1[i]; }

	ippsMulC_32f(&intj2[0], coff, &intjc2[0], nor*height);
	ippsSub_32f(&intij2[0], &intjc2[0], &intjimc2[0], nor*height);
	ippsSinCos_32f_A21(&intjimc2[0], &intsin2[0], &intcos2[0], nor*height);

	//for (int i = 0; i < nor*height; i++) { kernr[i].im = intsin2[i]; kernr[i].re = intcos2[i]; }
	float alpha = 1.0;


	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, iexfcc.data(), width, intsin1.data(), nor, 0, interre.data(), nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, rexfcc.data(), width, intcos1.data(), nor, 1.0, interre.data(), nor);

	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, iexfcc.data(), width, intcos1.data(), nor, 0, interim.data(), nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, rexfcc.data(), width, intsin1.data(), nor, -1.0, interim.data(), nor);

	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, nor, nor, height, alpha, intsin2.data(), height, interim.data(), nor, 0, output.data(), nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, nor, nor, height, alpha, intcos2.data(), height, interre.data(), nor, -1.0, output.data(), nor);

	ippsMaxIndx_32f(&output[0], output.size(), &max1dval, &max1dpos);
	max1dpos = distance(output.begin(), max_element(output.begin(), output.end()));
	
	offsetx = max1dpos % (nor);
	offsety = max1dpos / (nor);


	offsetx = estoffsetx + (offsetx - dftshift) / upscalefactor;
	offsety = estoffsety + (offsety - dftshift) / upscalefactor;


}




#define PI 3.141592653589793238462643383279


class imageTransform_32f {

	uint16_t imageWidth, imageHeight;
	uint32_t imagePoints;

	//Translation requirements
	IppiSize srcRoi, wrappedRoi;
	int topborderHeight, leftborderWidth;

	//tranform requirements
	float cornerangle, cornerdist;

	double quad[4][2];
	double coeffs[2][3];

	IppiRect wrappedRect;
	IppiWarpSpec* pSpec;
	IppiPoint dstOffset;
	int specSize, initSize, bufSize;
	Ipp8u* pBuffer;
	IppiBorderType   borderType;
	IppiWarpDirection direction;
	Ipp64f boarder;

	std::vector<float> wrapped;
	std::vector<float> transformed;

public:


	imageTransform_32f(uint16_t imageWidthin, uint16_t imageHeightin);

	void imageTranslate(std::vector<float>& inputImage, std::vector<float>& outputImage, float deltaX, float deltaY);

	void transform(std::vector<float>& inputImage, std::vector<float>& outputImage, float angle, float scale, float deltaX, float deltaY);


};

inline imageTransform_32f::imageTransform_32f(uint16_t imageWidthin, uint16_t imageHeightin) {
	imageWidth = imageWidthin;
	imageHeight = imageHeightin;

	imagePoints = imageWidth*imageHeight;

	dstOffset.x = 0;
	dstOffset.y = 0;
	// dstOffset= { 0, 0 }; 
	specSize = 0;
	initSize = 0; 
	bufSize = 0;
	pBuffer = NULL;
	borderType = ippBorderConst;
	direction = ippWarpForward;
	boarder = 0;

	wrapped = std::vector<float>(9 * imagePoints, 0);
	transformed = std::vector<float>(9 * imagePoints, 0);

	srcRoi.width = imageWidth;
	srcRoi.height = imageHeight;
	//srcRoi = { imageWidth, imageHeight };
	wrappedRoi.width = 3 * imageWidth;
	wrappedRoi.height = 3 * imageHeight;
	//wrappedRoi = { 3 * imageWidth, 3 * imageHeight };
	topborderHeight = imageHeight;
	leftborderWidth = imageWidth;

	//for transform

	cornerangle = atan(((double)imageHeight) / ((double)imageWidth));
	cornerdist = sqrt((double)((3.0*imageHeight -1) / 2.0*(3.0*imageHeight -1) / 2.0 + (3.0*imageWidth -1) / 2.0*(3.0*imageWidth -1) / 2.0));

	wrappedRect.x = 0;
	wrappedRect.y = 0;
	wrappedRect.width = 3 * imageWidth;
	wrappedRect.height = 3 * imageHeight;

	//wrappedRect = { 0,0,3 * imageWidth, 3 * imageHeight };

}

inline void imageTransform_32f::imageTranslate(std::vector<float>& inputImage, std::vector<float>& outputImage, float deltaX, float deltaY) {

	outputImage.resize(imagePoints);

	int xint = floor(deltaX);
	int yint = floor(deltaY);

	float dx = deltaX - xint;
	float dy = deltaY - yint;

	while (xint > imageWidth / 2.0)xint = xint - imageWidth;
	while (xint < -1.0*imageWidth / 2)xint = xint + imageWidth;
	while (yint > imageHeight / 2.0)yint = yint - imageHeight;
	while (yint < -1.0*imageHeight / 2)yint = yint + imageHeight;


	//std::cout << "Image Tran x = " << deltaX << " y = " << deltaY << " xint = " << xint << " yint = " << yint << " dx = " << dx << " dy = " << dy << "\n";

	ippiCopyWrapBorder_32f_C1R(inputImage.data(), imageWidth * sizeof(Ipp32f), srcRoi, wrapped.data(), 3 * imageWidth * sizeof(Ipp32f), wrappedRoi, topborderHeight, leftborderWidth);	
	ippiCopySubpix_32f_C1R(&wrapped[(topborderHeight + yint)*(3 * imageWidth) + (leftborderWidth + xint)], 3 * imageWidth * sizeof(Ipp32f), outputImage.data(), imageWidth * sizeof(Ipp32f), srcRoi, dx, dy);


}

inline void imageTransform_32f::transform(std::vector<float>& inputImage, std::vector<float>& outputImage, float angle, float scale, float deltaX, float deltaY) {

	deltaX = -deltaX;// -0.5;
	deltaY = -deltaY;// -0.5;

	quad[0][0] = (3.0*imageWidth - 1) / 2.0 + scale*cornerdist*cos(PI - cornerangle + angle) + deltaX;
	quad[0][1] = (3.0*imageHeight - 1) / 2.0 - scale* cornerdist*sin(PI - cornerangle + angle) + deltaY;

	quad[1][0] = (3.0*imageWidth - 1) / 2.0 + scale*cornerdist*cos(cornerangle + angle) + deltaX;
	quad[1][1] = (3.0*imageHeight - 1) / 2.0 - scale*cornerdist*sin(cornerangle + angle) + deltaY;

	quad[2][0] = (3.0*imageWidth - 1) / 2.0 + scale*cornerdist*cos(-cornerangle + angle) + deltaX;
	quad[2][1] = (3.0*imageHeight - 1) / 2.0 - scale*cornerdist*sin(-cornerangle + angle) + deltaY;

	quad[3][0] = (3.0*imageWidth - 1) / 2.0 + scale*cornerdist*cos(-PI + cornerangle + angle) + deltaX;
	quad[3][1] = (3.0*imageHeight - 1) / 2.0 - scale*cornerdist*sin(-PI + cornerangle + angle) + deltaY;

	ippiGetAffineTransform(wrappedRect, quad, coeffs);

	ippiWarpAffineGetSize(wrappedRoi, wrappedRoi, ipp32f, coeffs, ippLinear, direction, borderType, &specSize, &initSize);

	pSpec = (IppiWarpSpec*)ippsMalloc_8u(2*specSize);

	ippiWarpAffineLinearInit(wrappedRoi, wrappedRoi, ipp32f, coeffs, direction, 1, borderType, &boarder, 0, pSpec);
	ippiWarpGetBufferSize(pSpec, wrappedRoi, &bufSize);

	pBuffer = ippsMalloc_8u(bufSize);


	ippiCopyWrapBorder_32f_C1R(inputImage.data(), imageWidth * sizeof(Ipp32f), srcRoi, wrapped.data(), 3 * imageWidth * sizeof(Ipp32f), wrappedRoi, topborderHeight, leftborderWidth);

	ippiWarpAffineLinear_32f_C1R(wrapped.data(), 3 * imageWidth * sizeof(Ipp32f), transformed.data(), 3 * imageWidth * sizeof(Ipp32f), dstOffset, wrappedRoi, pSpec, pBuffer);

	ippiCopy_32f_C1R(&transformed[(topborderHeight)*(3 * imageWidth) + (leftborderWidth)], 3 * imageWidth * sizeof(Ipp32f), outputImage.data(), imageWidth * sizeof(Ipp32f), srcRoi);

	ippsFree(pBuffer);

	ippsFree(pSpec);

}

#endif