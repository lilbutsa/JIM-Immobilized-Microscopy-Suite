#pragma once
#ifndef IMAGETRANSFORMCLASS_H_
#define IMAGETRANSFORMCLASS_H_

/**
 * @file    image_transforms.hpp
 * @brief   Fourier-based image alignment and geometric transformation utilities.
 *
 * This header defines a set of classes and functions for performing fast and accurate
 * image alignment and transformation tasks on float images. 
 *
 * The code is organized into two main components:
 *
 * ------------------------------------------------------------------------
 * [1] alignImages_32f:
 *      - Performs image alignment via cross-correlation.
 *      - Uses PocketFFT to compute FFTs for efficient convolution.
 *      - Supports subpixel peak localization via quadratic fitting.
 *      - Optional Laplacian of Gaussian filtering in frequency domain.
 *
 *      Key methods:
 *        - FFTForward / FFTBackward: FFT wrappers
 *        - alignLoadIm1 / alignIm2: Load reference & align target
 *        - fitSubPixelQuadratic: Subpixel maximum estimation
 *        - laplaciandOfGaussian: Frequency-space LOG filter
 *
 * ------------------------------------------------------------------------
 * [2] imageTransform_32f:
 *      - Applies geometric transformations (translate, rotate, scale) to images.
 *      - Uses bilinear interpolation with edge clamping.
 *
 *      Key methods:
 *        - transform: Rotation + scaling + translation
 *        - translate: Translation only
 *
 * ------------------------------------------------------------------------
 * [3] Utility Functions:
 *      - meanAndStdDev<T>: Computes mean and standard deviation.
 *      - normalizeVector<T>: Normalizes a vector to zero-mean, unit-stddev.
 *
 * Dependencies:
 *      - Requires PocketFFT (single-header version). (https://github.com/mreineck/pocketfft)
 *
 * Example usage:
 *      alignImages_32f aligner(w, h);
 *      aligner.alignLoadIm1(image1, maxDist);
 *      aligner.alignIm2(image2);
 *      float dx = aligner.quadFitX, dy = aligner.quadFitY;
 *
 *      imageTransform_32f transformer(w, h);
 *      transformer.transform(imageIn, imageOut, dx, dy, angle, scale);
 * 
 * @author James Walsh  james.walsh@phys.unsw.edu.au
 * @date 2020-02-09
 */


#include <complex>
#include <cmath>
#include <vector>
#include <iostream>
#include <algorithm>
#include <numeric>
#include <utility>
#include <string>

#include "pocketfft_hdronly.h"

class alignImages_32f {

    uint16_t imageWidth, imageHeight, imagePoints;

    pocketfft::shape_t shape_in;
    pocketfft::stride_t stride_in, stride_out;

    pocketfft::shape_t axes;

    float forwardFactor, backwardFactor;

    std::vector<std::vector<int>> searchPositions;
public:
    std::vector<float> realDataOut, cc;

    std::vector<std::complex<float>> complexDataOut, fftCh1, fftCh2Rotated, fftCh2, fftcc;

    std::vector<int> minPos;

    int xAlign, yAlign;
    float quadFitX, quadFitY;
    const float pi = 3.1415926;
    float maxCCVal;

    inline alignImages_32f(int16_t imageWidthIn, uint16_t imageHeightIn) : imageWidth(imageWidthIn), imageHeight(imageHeightIn) {
        imagePoints = imageWidth * imageHeight;
        shape_in = pocketfft::shape_t{ imageWidth,imageHeight };                                              // dimensions of the input shape

        ptrdiff_t strideWidth = sizeof(float) * imageWidth;
        stride_in = pocketfft::stride_t{ sizeof(float),strideWidth };                    // must have the size of each element. Must have size() equal to shape_in.size()
        strideWidth = sizeof(std::complex<float>) * imageWidth;
        stride_out = pocketfft::stride_t{ sizeof(std::complex<float>),strideWidth }; // must have the size of each element. Must have size() equal to shape_in.size()
        axes = pocketfft::shape_t{ 0,1 };                                                 // 0 to shape.size()-1 inclusive
        realDataOut = std::vector<float>(imagePoints);
        complexDataOut = std::vector<std::complex<float>>(imagePoints);                                // output data (FFT(input))
        forwardFactor = 1.0f;
        backwardFactor = 1.0f / (imagePoints);

        xAlign = 0;
        yAlign = 0;
        quadFitX = 0;
        quadFitY = 0;
        maxCCVal = 0;


    }

    inline void FFTForward(std::vector<float>& dataIn) {
        //pocketfft::r2c(shape_in, stride_in, stride_out, axes, pocketfft::FORWARD, dataIn.data(), complexDataOut.data(), forwardFactor);
        std::vector<std::complex<float>> data2(dataIn.size());
        for (int i = 0;i < dataIn.size();i++)data2[i] = dataIn[i];

        pocketfft::c2c(shape_in, stride_out, stride_out, axes, pocketfft::FORWARD, data2.data(), complexDataOut.data(), forwardFactor);
    }

    inline void FFTBackward(std::vector<std::complex<float>> dataIn) {
        pocketfft::c2r(shape_in, stride_out, stride_in, axes, pocketfft::BACKWARD, dataIn.data(), realDataOut.data(), backwardFactor);

    }

    inline void alignLoadIm1(std::vector<float>& dataIm1, float maxDist) {
        fftCh1.resize(imagePoints);
        pocketfft::r2c(shape_in, stride_in, stride_out, axes, pocketfft::FORWARD, dataIm1.data(), fftCh1.data(), forwardFactor);
        std::transform(fftCh1.begin(), fftCh1.end(), fftCh1.begin(), [](const std::complex<float>& c) -> std::complex<float> { return std::conj(c); });

        searchPositions.clear();
        float xmax = std::max(std::min(maxDist, ((float)imageWidth) / 2), (float)0);
        float ymax = std::max(std::min(maxDist, ((float)imageHeight) / 2), (float)0);
        for (int i = -ceil(xmax); i <= ceil(xmax);i++)
            for (int j = -ceil(ymax); j <= ceil(ymax);j++)
                if (i * i + j * j <= maxDist * maxDist + 0.000001)searchPositions.push_back({ (i < 0 ? imageWidth + i : i) + imageWidth * (j < 0 ? imageHeight + j : j),i,j });

    }

    inline void alignWithLogLoadIm1(std::vector<float>& dataIm1, float maxDist, float gaussStdDev) {
        alignLoadIm1(dataIm1, maxDist);

        for (int i = 0;i < imagePoints;i++) {

            int xIn = i % imageWidth;
            int yIn = i / imageWidth;
            if (xIn >= imageWidth / 2)xIn += -imageWidth;
            if (yIn >= imageHeight / 2)yIn += -imageHeight;
            float kSquared = ((float)(xIn * xIn)) / (imageWidth * imageWidth) + ((float)(yIn * yIn)) / (imageHeight * imageHeight);
            float logVal = (-kSquared * sqrt(pi * sqrt(2.0f) * gaussStdDev) * exp(-kSquared * pi * pi * sqrt(2.0f) * gaussStdDev));

            fftCh1[i] = fftCh1[i] * (logVal * logVal);

        }

    }

    inline void alignIm2(std::vector<float>& dataIm2) {
        fftCh2.resize(imagePoints);
        fftCh2Rotated.resize(imagePoints);
        pocketfft::r2c(shape_in, stride_in, stride_out, axes, pocketfft::FORWARD, dataIm2.data(), fftCh2.data(), forwardFactor);

        std::transform(fftCh1.begin(), fftCh1.end(), // Input range 1
            fftCh2.begin(),             // Input range 2
            fftCh2Rotated.begin(),             // Output range (in-place)
            std::multiplies<std::complex<float>>());  // Binary operation

        pocketfft::c2r(shape_in, stride_out, stride_in, axes, pocketfft::BACKWARD, fftCh2Rotated.data(), realDataOut.data(), backwardFactor);

        minPos = *max_element(searchPositions.begin(), searchPositions.end(), [&](std::vector<int> i, std::vector<int> j) { return realDataOut[i[0]] < realDataOut[j[0]];});


        xAlign = -minPos[1];
        yAlign = -minPos[2];

        maxCCVal = realDataOut[minPos[0]];

    }

    inline void fitSubPixelQuadratic() {

        float xyz = 0, yz = 0, xz = 0, x2zm2z = 0, y2zm2z = 0, z;
        for (int i = -2;i < 3;i++)for (int j = -2;j < 3;j++) {
            int xin = -xAlign + i;
            if (xin < 0)xin += imageWidth;
            if (xin >= imageWidth)xin += -imageWidth;
            int yin = -yAlign + j;
            if (yin < 0)yin += imageHeight;
            if (yin >= imageHeight)yin += -imageHeight;

            z = realDataOut[xin + yin * imageWidth];


            xz += i * z;
            yz += j * z;
            xyz += i * j * z;
            x2zm2z += (i * i - 2) * z;
            y2zm2z += (j * j - 2) * z;
        }

        quadFitX = (98 * xyz * yz - 280 * xz * y2zm2z) / (-49 * xyz * xyz + 400 * x2zm2z * y2zm2z);
        quadFitY = (98 * xyz * xz - 280 * yz * x2zm2z) / (-49 * xyz * xyz + 400 * x2zm2z * y2zm2z);


        quadFitX = xAlign - quadFitX;
        quadFitY = yAlign - quadFitY;



        //end subpixel stuff

    }

    inline void laplaciandOfGaussian(std::vector<float>& dataIn, float gaussStdDev) {
        pocketfft::r2c(shape_in, stride_in, stride_out, axes, pocketfft::FORWARD, dataIn.data(), complexDataOut.data(), forwardFactor);

        for (int i = 0;i < imagePoints;i++) {

            int xIn = i % imageWidth;
            int yIn = i / imageWidth;
            if (xIn >= imageWidth / 2)xIn += -imageWidth;
            if (yIn >= imageHeight / 2)yIn += -imageHeight;
            float kSquared = ((float)(xIn * xIn)) / (imageWidth * imageWidth) + ((float)(yIn * yIn)) / (imageHeight * imageHeight);

            complexDataOut[i] = complexDataOut[i] * (kSquared * sqrt(pi * sqrt(2.0f) * gaussStdDev) * exp(-kSquared * pi * pi * sqrt(2.0f) * gaussStdDev));
        }

        pocketfft::c2r(shape_in, stride_out, stride_in, axes, pocketfft::BACKWARD, complexDataOut.data(), realDataOut.data(), backwardFactor);

    }
};


class imageTransform_32f {
    uint16_t imageWidth, imageHeight, imagePoints;

    float xcentre, ycentre;

public:

    inline imageTransform_32f(int16_t imageWidthIn, uint16_t imageHeightIn) : imageWidth(imageWidthIn), imageHeight(imageHeightIn) {
        xcentre = imageWidth / 2.0;
        ycentre = imageHeight / 2.0;
        imagePoints = imageWidth * imageHeight;
    };

    template <typename vectortype>
    inline void transform(const std::vector<vectortype>& input, std::vector<vectortype>& output, float xOffset, float yOffset, float angle, float scale) {

        output.resize(imagePoints);

        const float cosVal = cos(angle * 3.14159 / 180.0) / scale;
        const float sinVal = sin(angle * 3.14159 / 180.0) / scale;
        const float xConst = xcentre * (1 - cosVal) + ycentre * sinVal+ xOffset;
        const float yConst = -xcentre * sinVal + ycentre * (1 - cosVal)+ yOffset;



        for (int i = 0; i < imageWidth; i++)for (int j = 0; j < imageHeight; j++) {
            float xout = i * cosVal - j * sinVal + xConst;
            float yout = i * sinVal + j * cosVal + yConst;

            int xInt = floor(xout);
            int yInt = floor(yout);

            float xRem = xout - xInt;
            float yRem = yout - yInt;

            int xInt2 = (xInt < 0 ? 0 : (xInt > imageWidth - 1 ? imageWidth - 1 : xInt));
            int yInt2 = (yInt < 0 ? 0 : (yInt > imageHeight - 1 ? imageHeight - 1 : yInt));
            vectortype f00 = input[xInt2 + yInt2 * imageWidth];
            yInt2 = (yInt + 1 < 0 ? 0 : (yInt + 1 > imageHeight - 1 ? imageHeight - 1 : yInt + 1));
            vectortype f01 = input[xInt2 + yInt2 * imageWidth];
            xInt2 = (xInt + 1 < 0 ? 0 : (xInt + 1 > imageWidth - 1 ? imageWidth - 1 : xInt + 1));
            yInt2 = (yInt < 0 ? 0 : (yInt > imageHeight - 1 ? imageHeight - 1 : yInt));
            vectortype f10 = input[xInt2 + yInt2 * imageWidth];
            yInt2 = (yInt + 1 < 0 ? 0 : (yInt + 1 > imageHeight - 1 ? imageHeight - 1 : yInt + 1));
            vectortype f11 = input[xInt2 + yInt2 * imageWidth];

            output[i + j * imageWidth] = f00+(f10-f00)*xRem+(f01-f00)*yRem+(f11-f10-f01+f00)*xRem*yRem;
        }

    }


    template <typename vectortype>
    inline void translate(std::vector<vectortype>& input, std::vector<vectortype>& output, float xOffset, float yOffset) {

        output.resize(imagePoints);

        for (int i = 0; i < imageWidth; i++)for (int j = 0; j < imageHeight; j++) {
            float xout = i + xOffset;
            float yout = j + yOffset;

            int xInt = floor(xout);
            int yInt = floor(yout);

            float xRem = xout - xInt;
            float yRem = yout - yInt;

            int xInt2 = (xInt < 0 ? 0 : (xInt > imageWidth - 1 ? imageWidth - 1 : xInt));
            int yInt2 = (yInt < 0 ? 0 : (yInt > imageHeight - 1 ? imageHeight - 1 : yInt));
            vectortype f00 = input[xInt2 + yInt2 * imageWidth];
            yInt2 = (yInt+1 < 0 ? 0 : (yInt+1 > imageHeight - 1 ? imageHeight - 1 : yInt+1));
            vectortype f01 = input[xInt2 + yInt2 * imageWidth];
            xInt2 = (xInt+1 < 0 ? 0 : (xInt+1 > imageWidth - 1 ? imageWidth - 1 : xInt+1));
            yInt2 = (yInt < 0 ? 0 : (yInt > imageHeight - 1 ? imageHeight - 1 : yInt));
            vectortype f10 = input[xInt2 + yInt2 * imageWidth];
            yInt2 = (yInt + 1 < 0 ? 0 : (yInt + 1 > imageHeight - 1 ? imageHeight - 1 : yInt + 1));
            vectortype f11 = input[xInt2 + yInt2 * imageWidth];

            output[i + j * imageWidth] = f00 + (f10 - f00) * xRem + (f01 - f00) * yRem + (f11 - f10 - f01 + f00) * xRem * yRem;
        }
    }

};

template <typename vectortype>
inline void meanAndStdDev(std::vector<vectortype> const& v , double& mean, double& stdDev)
{
    mean = std::accumulate(std::begin(v), std::end(v), 0.0);
    mean = mean / v.size();

    double accum = 0.0;
    std::for_each(std::begin(v), std::end(v), [&](const vectortype d) {
        accum += (d - mean) * (d - mean);
        });

    stdDev = sqrt(accum / (v.size()-1));
}

template <typename vectortype>
inline void meanAndStdDev(std::vector<vectortype> const& v, float& mean, float& stdDev)
{
    mean = std::accumulate(std::begin(v), std::end(v), 0.0f);
    mean = mean / v.size();

    float accum = 0.0;
    std::for_each(std::begin(v), std::end(v), [&](const vectortype d) {
        accum += (d - mean) * (d - mean);
        });

    stdDev = sqrt(accum / (v.size() - 1));
}

template <typename vectortype>
inline void normalizeVector(std::vector<vectortype>& v) {

    double mean=0, stddev=0;

    meanAndStdDev(v, mean, stddev);

    std::transform(v.begin(), v.end(), v.begin(), [&](auto& value) { return (value - mean)/stddev; });

}


#endif