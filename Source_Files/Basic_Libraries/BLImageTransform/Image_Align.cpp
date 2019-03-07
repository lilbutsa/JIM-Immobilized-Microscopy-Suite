#include "stdafx.h"
#include "BLImageTransform.h"
#include <math.h>
#include <numeric>
#include <algorithm>
#include "mkl.h"

using namespace std;

alignImages_32f::~alignImages_32f() {
	if (pDFTWorkBuf) ippFree(pDFTWorkBuf);
	if (pDFTSpec) ippFree(pDFTSpec);
}

alignImages_32f::alignImages_32f(int upscalefactorin, int widthin, int heightin) {
	upscalefactor = upscalefactorin;

	width = widthin;
	height = heightin;
	nop = width*height;
	//gaus1 = vector<float>(nop); gaus2= vector<float>(nop);

	roiSize = { width, height };

	ippiDFTGetSize_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, &sizeDFTSpec, &sizeDFTInitBuf, &sizeDFTWorkBuf);
	// Alloc DFT buffers
	pDFTSpec = (IppiDFTSpec_R_32f*)ippsMalloc_8u(sizeDFTSpec);
	pDFTInitBuf = ippsMalloc_8u(sizeDFTInitBuf);
	pDFTWorkBuf = ippsMalloc_8u(sizeDFTWorkBuf);

	// Initialize DFT
	ippiDFTInit_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, pDFTSpec, pDFTInitBuf);
	if (pDFTInitBuf) ippFree(pDFTInitBuf);

	fgaus1 = vector<float>(nop); fgaus2 = vector<float>(nop); fcc = vector<float>(4 * nop); rcc = vector<float>(4 * nop);

	singlepixelrcc = vector<float>(nop);

	roiSize2 = { 2 * width, 2 * height };
	ippiDFTGetSize_R_32f(roiSize2, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, &sizeDFTSpec2, &sizeDFTInitBuf2, &sizeDFTWorkBuf2);
	// Alloc DFT buffers
	pDFTSpec2 = (IppiDFTSpec_R_32f*)ippsMalloc_8u(sizeDFTSpec2);
	pDFTInitBuf2 = ippsMalloc_8u(sizeDFTInitBuf2);
	pDFTWorkBuf2 = ippsMalloc_8u(sizeDFTWorkBuf2);

	// Initialize DFT
	ippiDFTInit_R_32f(roiSize2, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, pDFTSpec2, pDFTInitBuf2);
	if (pDFTInitBuf2) ippFree(pDFTInitBuf2);

	exfcc = vector<Ipp32fc>(nop); expaddedfcc = vector<Ipp32fc>(4 * nop); cexfcc = vector<Ipp32fc>(nop);
	paddedfcc = vector<float>(4 * nop);


	dftshift = (int)ceil(upscalefactor*1.5) / 2;
	nor = ceil(upscalefactor*1.5);//also noc


	intij1 = vector<float>(nor*width); intj1 = vector<float>(nor*width); intjr1 = vector<float>(nor*width); intjimr1 = vector<float>(nor*width); intsin1 = vector<float>(nor*width); intcos1 = vector<float>(nor*width);
	intij2 = vector<float>(nor*height); intj2 = vector<float>(nor*height); intjc2 = vector<float>(nor*height); intjimc2 = vector<float>(nor*height); intsin2 = vector<float>(nor*height); intcos2 = vector<float>(nor*height);
	double someconst1 = -2 * 3.141592653589 / (width*upscalefactor), someconst2 = -2 * 3.141592653589 / (height*upscalefactor);

	for (int i = 0; i < nor; i++)for (int j = 0; j < width; j++) {
		intj1[i + j*nor] = j < (width + 1) / 2 ? someconst1*j : someconst1*(j - width);
		intij1[i + j*nor] = j < (width + 1) / 2 ? someconst1*j*i : someconst1*(j - width)*i;
	}

	for (int i = 0; i < nor; i++)for (int j = 0; j < height; j++) {
		intj2[i*height + j] = j < (height + 1) / 2 ? someconst2*j : someconst2*(j - height);
		intij2[i*height + j] = j < (height + 1) / 2 ? someconst2*j*i : someconst2*(j - height)*i;
	}

	rexfcc = vector<float>(nop); iexfcc = vector<float>(nop); interre = vector<float>(nor*height); interim = vector<float>(nor*height); output = vector<float>(nor*nor);


}

void alignImages_32f::imageAligntopixel(vector<float>& gaus1, vector<float>& gaus2) {
	ippiDFTFwd_RToPack_32f_C1R(&gaus1[0], width * sizeof(float), &fgaus1[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);
	ippiDFTFwd_RToPack_32f_C1R(&gaus2[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	//find cross correlation
	ippiMulPackConj_32f_C1R(&fgaus1[0], width * sizeof(float), &fgaus2[0], width * sizeof(float), &fcc[0], width * sizeof(float), roiSize);

	ippiDFTInv_PackToR_32f_C1R(&fcc[0],  width * sizeof(float), &singlepixelrcc[0], width * sizeof(float), pDFTSpec, pDFTWorkBuf);

	ippsMaxIndx_32f(&singlepixelrcc[0],  nop, &max1dval, &max1dpos);
	offsetx = max1dpos % ( width);
	offsety = max1dpos / (  width);
	if (offsetx > ( width) / 2)offsetx += - width;
	if (offsety > ( height) / 2)offsety += - height;

}

void alignImages_32f::imageAlign(vector<float>& gaus1, vector<float>& gaus2) {


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
