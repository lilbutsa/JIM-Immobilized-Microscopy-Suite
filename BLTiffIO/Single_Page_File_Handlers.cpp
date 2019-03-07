#include "stdafx.h"
#include "BLTiffIO.h"
#include <iostream>


void BLTiffIO::WriteSinglePage1D(std::vector<double>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}
void BLTiffIO::WriteSinglePage1D(std::vector<float>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}
void BLTiffIO::WriteSinglePage1D(std::vector<int>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}
void BLTiffIO::WriteSinglePage1D(std::vector<long>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}
void BLTiffIO::WriteSinglePage1D(std::vector<uint8_t>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}
void BLTiffIO::WriteSinglePage1D(std::vector<uint16_t>& imagein, std::string filename, int imageWidth, int imageDepth) {
	int height = imagein.size() / imageWidth;
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, imageWidth, height);
	imageoutput.WriteImage1d(0, imagein);
}









void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<double>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}
void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<float>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}
void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<int>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}
void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<long>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}
void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<uint8_t>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}
void BLTiffIO::WriteSinglePage2D(std::vector<std::vector<uint16_t>>& imagein, std::string filename, int imageDepth) {
	int width = imagein.size();
	int height = imagein[0].size();
	BLTiffIO::MultiPageTiffOutput imageoutput(filename, 1, imageDepth, width, height);
	imageoutput.WriteImage2d(0, imagein);
}







void BLTiffIO::ReadSinglePage1D(std::vector<double>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage1D(std::vector<float>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage1D(std::vector<int>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage1D(std::vector<long>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage1D(std::vector<uint8_t>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage1D(std::vector<uint16_t>& imageout, std::string filename, int &imageWidth, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage1d(0, imageout);
	imageWidth = imageinput.imageWidth();
	imageDepth = imageinput.imageBitDepth();
}












void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<double>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<float>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<int>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<long>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<uint8_t>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
void BLTiffIO::ReadSinglePage2D(std::vector<std::vector<uint16_t>>& imageout, std::string filename, int &imageDepth) {
	BLTiffIO::MultiPageTiffInput imageinput(filename);
	imageinput.GetImage2d(0, imageout);
	imageDepth = imageinput.imageBitDepth();
}
