#include "stdafx.h"
#include "BLImageTransform.h"
#include "ipp.h"

using namespace std;

imageTransform_32f::imageTransform_32f(int width, int height) {

	srcSize = { width,height };
	srcStep = width * sizeof(float);
	angle = -10.0;
	xCenter = width / 2.0;
	yCenter = height / 2.0;

	/*ippiGetRotateTransform(angle, 0, 0, coeffs);

	coeffs[0][2] = xCenter - coeffs[0][0] * xCenter - coeffs[0][1] * yCenter;
	coeffs[1][2] = yCenter - coeffs[1][0] * xCenter - coeffs[1][1] * yCenter;

	dstOffset = { 0, 0 };


	ippiWarpAffineGetSize(srcSize, srcSize, ipp32f, coeffs, ippLinear, ippWarpForward, ippBorderConst, &specSize, &initSize);


	pSpecR = (IppiWarpSpec*)ippsMalloc_8u(specSize);

	ippiWarpGetBufferSize(pSpecR, srcSize, &bufSize);

	pBufferR = ippsMalloc_8u(bufSize);*/




	int nop = width * height;



	pxMap0 = vector<float>(nop);
	pyMap0 = vector<float>(nop);
	pxMap = vector<float>(nop);
	pyMap = vector<float>(nop);

	pxSMap0 = vector<float>(nop);
	pySMap0 = vector<float>(nop);
	pxSMap = vector<float>(nop);
	pySMap = vector<float>(nop);

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

void imageTransform_32f::imageRotate(vector<float> &imagein, vector<float> &imageout, double angle) {

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

void imageTransform_32f::imageTranslate(vector<float> &imagein, vector<float> &imageout, float deltaX, float deltaY) {
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


void imageTransform_32f::imageScale(vector<float> &imagein, vector<float> &imageout, float scaleFactor) {
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