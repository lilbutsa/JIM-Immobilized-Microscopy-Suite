#pragma once
#include <iostream>
#include <vector>
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