#pragma once
#include <iostream>
#include <vector>
#include <math.h>
#include <numeric>
#include <algorithm>
#include "mkl.h"
#include "ipp.h"



class imageTransform_32f {
	int widthin, heightin;
	IppiSize srcSize;
	int srcStep;
	double coeffs[2][3];
	double angle, xCenter, yCenter;
	int specSize, initSize, bufSize;
	IppiPoint dstOffset;
	Ipp8u* pBufferR;
	IppiWarpSpec* pSpecR;
	IppiRect rect;

	std::vector<float> pxMap0, pyMap0, pxMap, pyMap;
	std::vector<float> pxSMap0, pySMap0, pxSMap, pySMap;

public:
	imageTransform_32f(int width, int height);
	~imageTransform_32f();
	void imageRotate(std::vector<float> &imagein, std::vector<float> &imageout, double angle);
	void imageTranslate(std::vector<float> &imagein, std::vector<float> &imageout, float deltaX, float deltaY);
	void imageScale(std::vector<float> &imagein, std::vector<float> &imageout, float scaleFactor);
};

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

	void imageAlign(std::vector<float>& gaus1, std::vector<float>& gaus2);
	void imageAligntopixel(std::vector<float>& gaus1, std::vector<float>& gaus2);

	float max1dval;
	double offsetx, offsety;
};




alignImages_32f::~alignImages_32f() {
	if (pDFTWorkBuf) ippFree(pDFTWorkBuf);
	if (pDFTSpec) ippFree(pDFTSpec);
}

alignImages_32f::alignImages_32f(int upscalefactorin, int widthin, int heightin) {
	upscalefactor = upscalefactorin;

	width = widthin;
	height = heightin;
	nop = width*height;
	//gaus1 = std::vector<float>(nop); gaus2= std::vector<float>(nop);

	roiSize = { width, height };

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

	roiSize2 = { 2 * width, 2 * height };
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

inline void alignImages_32f::imageAligntopixel(std::vector<float>& gaus1, std::vector<float>& gaus2) {
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

}

inline void alignImages_32f::imageAlign(std::vector<float>& gaus1, std::vector<float>& gaus2) {


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
	//estoffsetx = 11;
	//estoffsety = 11;
	//while (abs(estoffsetx) > 10 || abs(estoffsety) > 11) {
	ippsMaxIndx_32f(&rcc[0], 4 * nop, &max1dval, &max1dpos);
	//rcc[max1dpos] = 0;
	estoffsetx = max1dpos % (2 * width);
	estoffsety = max1dpos / (2 * width);
	if (estoffsetx > (2 * width) / 2)estoffsetx += -2 * width;
	if (estoffsety > (2 * height) / 2)estoffsety += -2 * height;

	estoffsetx *= 0.5;
	estoffsety *= 0.5;
	//}
	//cout << "Initial estimated offset " << estoffsetx << " " << estoffsety << endl;


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

	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, &iexfcc[0], width, &intsin1[0], nor, 0, &interre[0], nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, &rexfcc[0], width, &intcos1[0], nor, 1.0, &interre[0], nor);

	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, &iexfcc[0], width, &intcos1[0], nor, 0, &interim[0], nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, height, nor, width, alpha, &rexfcc[0], width, &intsin1[0], nor, -1.0, &interim[0], nor);

	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, nor, nor, height, alpha, &intsin2[0], height, &interim[0], nor, 0, &output[0], nor);
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, nor, nor, height, alpha, &intcos2[0], height, &interre[0], nor, -1.0, &output[0], nor);

	ippsMaxIndx_32f(&output[0], output.size(), &max1dval, &max1dpos);
	max1dpos = distance(output.begin(), max_element(output.begin(), output.end()));
	offsetx = max1dpos % (nor);
	offsety = max1dpos / (nor);


	offsetx = estoffsetx + (offsetx - dftshift) / upscalefactor;
	offsety = estoffsety + (offsety - dftshift) / upscalefactor;



}



imageTransform_32f::imageTransform_32f(int width, int height) {

	srcSize = { width,height };
	srcStep = width * sizeof(float);
	angle = -10.0;
	xCenter = width / 2.0;
	yCenter = height / 2.0;

	int nop = width * height;



	pxMap0 = std::vector<float>(nop);
	pyMap0 = std::vector<float>(nop);
	pxMap = std::vector<float>(nop);
	pyMap = std::vector<float>(nop);

	pxSMap0 = std::vector<float>(nop);
	pySMap0 = std::vector<float>(nop);
	pxSMap = std::vector<float>(nop);
	pySMap = std::vector<float>(nop);

	for (int i = 0; i < width; i++)for (int j = 0; j < height; j++) {
		pxMap0[i + j*width] = i;
		pyMap0[i + j*width] = j;
		pxSMap0[i + j*width] = i - width / 2.0;
		pySMap0[i + j*width] = j - height / 2.0;
	}

	rect = { 0, 0, width, height };

	widthin = width;
	heightin = height;




}

imageTransform_32f::~imageTransform_32f() {

	ippsFree(pSpecR);
	ippsFree(pBufferR);
}

inline void imageTransform_32f::imageRotate(std::vector<float> &imagein, std::vector<float> &imageout, double angle) {

	imageout.resize(imagein.size());
	float halfwidth = (widthin) / 2.0;
	float halfheight = (heightin) / 2.0;
	float cosin = cos(angle);
	float sinin = sin(angle);

	ippiMulC_32f_C1R(pxSMap0.data(), srcStep, sinin, pxSMap.data(), srcStep, srcSize);
	ippiMulC_32f_C1R(pxSMap0.data(), srcStep, cosin, pxMap.data(), srcStep, srcSize);
	ippiMulC_32f_C1R(pySMap0.data(), srcStep, -sinin, pySMap.data(), srcStep, srcSize);
	ippiMulC_32f_C1R(pySMap0.data(), srcStep, cosin, pyMap.data(), srcStep, srcSize);

	ippiAdd_32f_C1IR(pySMap.data(), srcStep, pxMap.data(), srcStep, srcSize);
	ippiAdd_32f_C1IR(pxSMap.data(), srcStep, pyMap.data(), srcStep, srcSize);

	ippiAddC_32f_C1IR(halfwidth, pxMap.data(), srcStep, srcSize);
	ippiAddC_32f_C1IR(halfheight, pyMap.data(), srcStep, srcSize);


	for (int i = 0; i < pxMap.size(); i++) {
		if (pxMap[i] < 0)pxMap[i] += widthin;
		if (pxMap[i] >widthin)pxMap[i] += -(widthin);
		if (pyMap[i] < 0)pyMap[i] += (heightin);
		if (pyMap[i] >heightin)pyMap[i] += -(heightin);
	}


	ippiRemap_32f_C1R(imagein.data(), srcSize, srcStep, rect, pxMap.data(), srcStep, pyMap.data(), srcStep, imageout.data(), srcStep, srcSize, IPPI_INTER_LINEAR);


}

inline void imageTransform_32f::imageTranslate(std::vector<float> &imagein, std::vector<float> &imageout, float deltaX, float deltaY) {
	imageout.resize(imagein.size());



	ippiAddC_32f_C1R(pxMap0.data(), srcStep, deltaX, pxMap.data(), srcStep, srcSize);
	ippiAddC_32f_C1R(pyMap0.data(), srcStep, deltaY, pyMap.data(), srcStep, srcSize);

	for (int i = 0; i < pxMap.size(); i++) {
		while (pxMap[i] < 0)pxMap[i] += widthin;
		while (pxMap[i] > widthin)pxMap[i] += -widthin;
		while (pyMap[i] < 0)pyMap[i] += heightin;
		while (pyMap[i] > heightin)pyMap[i] += -heightin;
	}

	ippiRemap_32f_C1R(imagein.data(), srcSize, srcStep, rect, pxMap.data(), srcStep, pyMap.data(), srcStep, imageout.data(), srcStep, srcSize, IPPI_INTER_LINEAR);

}


inline void imageTransform_32f::imageScale(std::vector<float> &imagein, std::vector<float> &imageout, float scaleFactor) {
	imageout.resize(imagein.size());
	float halfwidth = (widthin) / 2.0;
	float halfheight = (heightin) / 2.0;
	ippiMulC_32f_C1R(pxSMap0.data(), srcStep, 1 / scaleFactor, pxSMap.data(), srcStep, srcSize);
	ippiMulC_32f_C1R(pySMap0.data(), srcStep, 1 / scaleFactor, pySMap.data(), srcStep, srcSize);

	ippiAddC_32f_C1IR(halfwidth, pxSMap.data(), srcStep, srcSize);
	ippiAddC_32f_C1IR(halfheight, pySMap.data(), srcStep, srcSize);

	for (int i = 0; i < pxSMap.size(); i++) {
		while (pxSMap[i] < 0)pxSMap[i] += widthin;
		while (pxSMap[i] > widthin)pxSMap[i] += -widthin;
		while (pySMap[i] < 0)pySMap[i] += heightin;
		while (pySMap[i] > heightin)pySMap[i] += -heightin;
	}


	ippiRemap_32f_C1R(imagein.data(), srcSize, srcStep, rect, pxSMap.data(), srcStep, pySMap.data(), srcStep, imageout.data(), srcStep, srcSize, IPPI_INTER_LINEAR);

}
