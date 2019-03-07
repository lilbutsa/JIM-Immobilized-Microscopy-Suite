#pragma once
#include <string>
#include <vector>
#include <iostream>
#include "tiffio.h"
//extern "C" {

	//using namespace System;



	namespace BLTiffIO {

		class MultiPageTiffInput
		{
		
			int numofframe=0, height=0, width=0,depth=0,channels=0;
			std::string inputstr = "";
		public:
			MultiPageTiffInput() {};
			MultiPageTiffInput(std::string inputfile);

			int totalNumberofFrames();
			int imageBitDepth();
			int imageWidth();
			int imageHeight();


			//template <typename outputvectortype>
			void  GetImage2d(int framenum, std::vector<std::vector<double>>& imageout);
			void  GetImage2d(int framenum, std::vector<std::vector<int>>& imageout);
			void  GetImage2d(int framenum, std::vector<std::vector<long>>& imageout);
			void  GetImage2d(int framenum, std::vector<std::vector<float>>& imageout);
			void  GetImage2d(int framenum, std::vector<std::vector<uint8_t>>& imageout);
			void  GetImage2d(int framenum, std::vector<std::vector<uint16_t>>& imageout);

			void  GetImage1d(int framenum, std::vector<double>& imageout);
			void  GetImage1d(int framenum, std::vector<float>& imageout);
			void  GetImage1d(int framenum, std::vector<int>& imageout);
			void  GetImage1d(int framenum, std::vector<long>& imageout);
			void  GetImage1d(int framenum, std::vector<uint8_t>& imageout);
			void  GetImage1d(int framenum, std::vector<uint16_t>& imageout);
		};

		class MultiPageTiffOutput
		{

			TIFF* output_tiff=NULL;
			int numofframe=0, height=0, width=0, depth=0;
			tdata_t firstpagebuffer=NULL;
		public:
			MultiPageTiffOutput() {};
			MultiPageTiffOutput(std::string outputfile,int numberOfFrames, int imageDepth, int imageWidth, int imageHeight);
			~MultiPageTiffOutput();

			int totalNumberofFrames();
			int imageBitDepth();
			int imageWidth();
			int imageHeight();
			
			//template <typename outputvectortype>
			void  WriteImage2d(int framenum, std::vector<std::vector<double>>& imageout);
			void  WriteImage2d(int framenum, std::vector<std::vector<int>>& imageout);
			void  WriteImage2d(int framenum, std::vector<std::vector<long>>& imageout);
			void  WriteImage2d(int framenum, std::vector<std::vector<float>>& imageout);
			void  WriteImage2d(int framenum, std::vector<std::vector<uint8_t>>& imageout);
			void  WriteImage2d(int framenum, std::vector<std::vector<uint16_t>>& imageout);

			void  WriteImage1d(int framenum, std::vector<double>& imageout);
			void  WriteImage1d(int framenum, std::vector<float>& imageout);
			void  WriteImage1d(int framenum, std::vector<int>& imageout);
			void  WriteImage1d(int framenum, std::vector<long>& imageout);
			void  WriteImage1d(int framenum, std::vector<uint8_t>& imageout);
			void  WriteImage1d(int framenum, std::vector<uint16_t>& imageout);
		};


		void WriteSinglePage1D(std::vector<double>& imagein, std::string filename, int imageWidth, int imageDepth);
		void WriteSinglePage1D(std::vector<float>& imagein, std::string filename, int imageWidth, int imageDepth);
		void WriteSinglePage1D(std::vector<int>& imagein, std::string filename, int imageWidth, int imageDepth);
		void WriteSinglePage1D(std::vector<long>& imagein, std::string filename, int imageWidth, int imageDepth);
		void WriteSinglePage1D(std::vector<uint8_t>& imagein, std::string filename, int imageWidth, int imageDepth);
		void WriteSinglePage1D(std::vector<uint16_t>& imagein, std::string filename, int imageWidth, int imageDepth);

		void WriteSinglePage2DColor(std::vector<std::vector<std::vector<uint8>>>& imagein, std::string filename);

		void WriteSinglePage2D(std::vector<std::vector<double>>& imagein, std::string filename, int imageDepth);
		void WriteSinglePage2D(std::vector<std::vector<float>>& imagein, std::string filename, int imageDepth);
		void WriteSinglePage2D(std::vector<std::vector<int>>& imagein, std::string filename, int imageDepth);
		void WriteSinglePage2D(std::vector<std::vector<long>>& imagein, std::string filename, int imageDepth);
		void WriteSinglePage2D(std::vector<std::vector<uint8_t>>& imagein, std::string filename, int imageDepth);
		void WriteSinglePage2D(std::vector<std::vector<uint16_t>>& imagein, std::string filename, int imageDepth);


		void ReadSinglePage1D(std::vector<double>& imageout, std::string filename, int &imageWidth, int &imageDepth);
		void ReadSinglePage1D(std::vector<float>& imageout, std::string filename, int &imageWidth, int &imageDepth);
		void ReadSinglePage1D(std::vector<int>& imageout, std::string filename, int &imageWidth, int &imageDepth);
		void ReadSinglePage1D(std::vector<long>& imageout, std::string filename, int &imageWidth, int &imageDepth);
		void ReadSinglePage1D(std::vector<uint8_t>& imageout, std::string filename, int &imageWidth, int &imageDepth);
		void ReadSinglePage1D(std::vector<uint16_t>& imageout, std::string filename, int &imageWidth, int &imageDepth);

		void ReadSinglePage2D(std::vector<std::vector<double>>& imageout, std::string filename, int &imageDepth);
		void ReadSinglePage2D(std::vector<std::vector<float>>& imageout, std::string filename, int &imageDepth);
		void ReadSinglePage2D(std::vector<std::vector<int>>& imageout, std::string filename, int &imageDepth);
		void ReadSinglePage2D(std::vector<std::vector<long>>& imageout, std::string filename, int &imageDepth);
		void ReadSinglePage2D(std::vector<std::vector<uint8_t>>& imageout, std::string filename, int &imageDepth);
		void ReadSinglePage2D(std::vector<std::vector<uint16_t>>& imageout, std::string filename, int &imageDepth);
	}
//}