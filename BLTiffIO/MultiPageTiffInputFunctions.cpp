#include "stdafx.h"
#include "BLTiffIO.h"

//extern "C" {

extern "C" {
	FILE* __iob_func = NULL;
}

	BLTiffIO::MultiPageTiffInput::MultiPageTiffInput(std::string inputfile) {
		TIFFSetWarningHandler(NULL);

		inputstr = inputfile;

		TIFF* input_tiff = TIFFOpen(inputstr.c_str(), "r");

		numofframe = TIFFNumberOfDirectories(input_tiff);

		TIFFGetField(input_tiff, TIFFTAG_IMAGEWIDTH, &width);
		TIFFGetField(input_tiff, TIFFTAG_IMAGELENGTH, &height);

		TIFFGetField(input_tiff, TIFFTAG_BITSPERSAMPLE, &depth);
		TIFFGetField(input_tiff, TIFFTAG_SAMPLESPERPIXEL, &channels);

		if (input_tiff)TIFFClose(input_tiff);
	}




	int BLTiffIO::MultiPageTiffInput::totalNumberofFrames() {
		return numofframe;
	}

	int BLTiffIO::MultiPageTiffInput::imageBitDepth() {
		return depth;
	}

	int BLTiffIO::MultiPageTiffInput::imageWidth() {
		return width;
	}

	int BLTiffIO::MultiPageTiffInput::imageHeight() {
		return height;
	}

	template <typename outputvectortype>
	int GetImage2dFunc(int framenum, std::vector<std::vector<outputvectortype>>& imageout,int width,int height,int depth,int channels,int numofframe, std::string inputstr){
		TIFF* input_tiff = TIFFOpen(inputstr.c_str(), "r");
		//imageout.clear();
		imageout.resize(width);
		for (int i = 0; i < width; i++)imageout[i].resize(height, 0);

		if (framenum >= numofframe)return 1;

		TIFFSetDirectory(input_tiff, framenum);
		tdata_t firstpagebuffer;
		if (depth == 8) {
			firstpagebuffer = _TIFFmalloc(sizeof(uint8)*width*channels);
			for (int i = 0; i < width; i++)((uint8*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i][j] = ((uint8*)firstpagebuffer)[i*channels];
			}
		}
		else if (depth == 32) {
			firstpagebuffer = _TIFFmalloc(sizeof(uint32)*width*channels);
			for (int i = 0; i < width; i++)((uint32*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i][j] = ((uint32*)firstpagebuffer)[i*channels];
			}
		}
		else {
			firstpagebuffer = _TIFFmalloc(sizeof(uint16)*width*channels);
			for (int i = 0; i < width; i++)((uint16*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i][j] = ((uint16*)firstpagebuffer)[i*channels];
			}
		}

		if (firstpagebuffer)_TIFFfree(firstpagebuffer);
		return 0;
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<double>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<int>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<long>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<float>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<uint8_t>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage2d(int framenum, std::vector<std::vector<uint16_t>>& imageout)
	{
		GetImage2dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}


	template <typename outputvectortype>
	int GetImage1dFunc(int framenum, std::vector<outputvectortype>& imageout, int width, int height, int depth, int channels,int numofframe, std::string inputstr) {
		TIFF* input_tiff = TIFFOpen(inputstr.c_str(), "r");
		//imageout.clear();
		imageout.resize(height*width);
		if (framenum > numofframe)return 1;
		TIFFSetDirectory(input_tiff, framenum);
		tdata_t firstpagebuffer;
		if (depth == 8) {
			firstpagebuffer = _TIFFmalloc(sizeof(uint8)*width*channels);
			for (int i = 0; i < width; i++)((uint8*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i + j*width] = ((uint8*)firstpagebuffer)[i*channels];
			}
		}
		else if (depth == 32) {
			firstpagebuffer = _TIFFmalloc(sizeof(uint32)*width*channels);
			for (int i = 0; i < width; i++)((uint32*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i + j*width] = ((uint32*)firstpagebuffer)[i*channels];
			}
		}
		else {
			firstpagebuffer = _TIFFmalloc(sizeof(uint16)*width*channels);
			for (int i = 0; i < width; i++)((uint16*)firstpagebuffer)[i] = 0;
			for (int j = 0; j < height; ++j) {
				TIFFReadScanline(input_tiff, firstpagebuffer, j);
				for (int i = 0; i < width; i++)imageout[i + j*width] = ((uint16*)firstpagebuffer)[i*channels];
			}
		}
		if (input_tiff)TIFFClose(input_tiff);
		if (firstpagebuffer)_TIFFfree(firstpagebuffer);
		return 0;
	}


	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<double>& imageout)
	{
		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<float>& imageout)
	{

		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<int>& imageout)
	{
		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<long>& imageout)
	{
		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<uint8_t>& imageout)
	{
		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}

	void BLTiffIO::MultiPageTiffInput::GetImage1d(int framenum, std::vector<uint16_t>& imageout)
	{
		GetImage1dFunc(framenum, imageout, width, height, depth, channels, numofframe, inputstr);
	}







//}