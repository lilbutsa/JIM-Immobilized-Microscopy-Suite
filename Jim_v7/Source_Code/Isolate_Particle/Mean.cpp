#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;

//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char* argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		cout<<"Standard input: [channel alignment file] [Drift Correction File] [Particle Measurements File] [Output File Base] [Input Image Stack Channel 1]... Options\n";
		cout << "Options:\n";
		cout << "-Particle i (Default i = 1) Specify particle i to isolate\n";
		cout << "-Start i (Default i = 1) Specify frame i to start isolating from\n";
		cout << "-End i (Default i = total number of frames) Specify frame i to end isolating from\n";
		cout << "-Delta i (Default i = 1) Specify steps in frames between isolated images\n";
		cout << "-Average i (Default i = 1) Specify number of frames around each step to average image (Must Be Odd)\n";
		cout << "-outputImageStack Output the ROI for the particle as a tiff stack \n";
		return 0;
	}

	int numInputFiles = 0;
	int particle = 1, start = 0, end = 100000000, delta = 1, average = 1;
	int imageDepth, imageWidth, imageHeight, imagePoints, totnumofframes;
	vector< vector<double> > measurements(3000, vector<double>(19, 0.0)), drifts(3000, vector<double>(2, 0.0)), channelalignment(11, vector<double>(2, 0.0));
	std::string outputfile;
	vector<BLTiffIO::TiffInput*> vcinput;
	bool bOutputImageStack = false;

	try {
		if (argc<5)throw std::invalid_argument("Insufficient Arguments");
		for (int i = 5; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if(numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

		std::vector<std::string> headerLine;
		if (numInputFiles > 1)BLCSVIO::readCSV(argv[1], channelalignment, headerLine);
		BLCSVIO::readCSV(argv[2], drifts, headerLine);
		BLCSVIO::readCSV(argv[3], measurements, headerLine);

		outputfile = argv[4];

		vector<string> inputfiles(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 5];

		vcinput.resize(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);
		imageDepth = vcinput[0]->imageDepth;
		imageWidth = vcinput[0]->imageWidth;
		imageHeight = vcinput[0]->imageHeight;
		imagePoints = imageWidth * imageHeight;
		totnumofframes = vcinput[0]->numOfFrames;
		end = totnumofframes;

		for (int i = 1; i < argc; i++) {
			if (std::string(argv[i]) == "-Particle") {
				if (i + 1 >= argc)throw std::invalid_argument("No Particle Input Value");
				try { particle = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Particle Number\nInput :" + std::string(argv[i + 1])+"\n"); }
				particle = max(0, min(particle, (int)measurements.size()));
				cout << "Isolating Particle " << particle << endl;
			}
			if (std::string(argv[i]) == "-Start") {
				if (i + 1 >= argc)throw std::invalid_argument("No Start Input Value");
				try { start = stoi(argv[i + 1])-1; }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Start Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				start = max(start, 0);
				cout << "Isolating the particle starting from frame " << start + 1 << endl;
			}
			if (std::string(argv[i]) == "-End") {
				if (i + 1 >= argc)throw std::invalid_argument("No End Input Value");
				try { end = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid End Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				end = min(end, totnumofframes);
				cout << "Isolating the particle up to frame " << end << endl;
			}
			if (std::string(argv[i]) == "-Delta") {
				if (i + 1 >= argc)throw std::invalid_argument("No Delta Input Value");
				try { delta = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Delta Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				cout << "Montage Delta = " << delta << "\n";
			}
			if (std::string(argv[i]) == "-Average") {
				if (i + 1 >= argc)throw std::invalid_argument("No Averaging Input Value");
				try { average = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Averaging Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				cout << "Averaging over " << average << " frames\n";
				if(average%2==0)throw std::invalid_argument("Averaging Value Must Be Odd");
				average = (average - 1) / 2;
			}
			if (std::string(argv[i]) == "-outputImageStack") {
				bOutputImageStack = true;
				cout << "Outputting Image Stack\n";
			}
		}
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}



	vector<float> image1(imagePoints), alignedimage(imagePoints, 0.0);
	
	uint32_t numOutputImages =floor( ((end - start) / delta)+1);
	uint32_t outputStart = (measurements[particle - 1][14]-3) + (measurements[particle - 1][16]-3) * imageWidth;
	uint32_t outputWidth = measurements[particle - 1][15] - measurements[particle - 1][14] + 7;
	uint32_t outputHeight = measurements[particle - 1][17] - measurements[particle - 1][16] + 7;
	uint32_t outputImagePoints = outputWidth * outputHeight;
	uint32_t outputMontageWidth = (outputWidth + 2) * numOutputImages;
	uint32_t outputMontagePoints = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * numInputFiles;

	vector<float> montage(outputMontagePoints, 65000);

	//vector< vector<float>> avimageout( numOutputImages, vector<float>(outputImagePoints, 0.0));
	//vector<float> flattenedimout(outputImagePoints * numOutputImages, 0.0);

	
	vector<float> translated(imagePoints);
	int CountImAveraged;
	float transxoffset, transyoffset;

	imageTransform_32f transformclass(imageWidth, imageHeight);
	vector<float> imagein(imagePoints), imaget(imagePoints),singleFrame(outputImagePoints);
	vector< vector<float> > outputImageStack(numOutputImages,vector<float>(outputImagePoints));
	
	BLTiffIO::TiffOutput* tiffout = NULL;

	//BLTiffIO::TiffOutput troubleshooting(outputfile + "troubleshooting.tiff", imageWidth, imageHeight, imageDepth, false);
	for (int chancount = 0; chancount < numInputFiles; chancount++) {
		cout << "Starting Output for Channel "<<to_string(chancount+1)<<"\n";

		if (bOutputImageStack) {
			std::string fileOutName = outputfile + "_Trace_" + to_string(particle) + "_Channel_" + to_string(chancount + 1) + ".tiff";
			cout << fileOutName << "\n";
			tiffout = new BLTiffIO::TiffOutput(fileOutName, outputWidth, outputHeight, imageDepth, false);
		}
		//BLTiffIO::TiffOutput tiffout(fileOutName, imageWidth, imageHeight, imageDepth, false);

		for (int imcount = 0; imcount < numOutputImages; imcount++) {
			vector<float> meanimage(imagePoints, 0.0);
			CountImAveraged = 0;
			for (int avcount = -average; avcount <= average; avcount++) {
				int iminnum = start + imcount * delta + avcount;
				if (iminnum >= 0 && iminnum < totnumofframes) {
					vcinput[chancount]->read1dImage(iminnum, imagein);

					if (chancount > 0) {
						//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
						transformclass.transform(imagein, imaget, channelalignment[chancount - 1][1] * 3.14159 / 180.0, channelalignment[chancount - 1][2], -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4]);
						imagein = imaget;
					}
					//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
					transformclass.imageTranslate(imagein, imaget, -drifts[iminnum][0], -drifts[iminnum][1]);

					ippsAdd_32f_I(imaget.data(), meanimage.data(), imagePoints);
					CountImAveraged++;
				}
			}
			ippsDivC_32f_I((float)CountImAveraged, meanimage.data(), imagePoints);

			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					outputImageStack[imcount][i + j * outputWidth] = meanimage[pos];
				}
			}
			
			//tiffout.write1dImage(outputImageStack[imcount]);
			//tiffout.write1dImage(meanimage);
		}


		//make the montage
		std::vector<float> flattenedimout;
		for (auto const& v : outputImageStack) {
			flattenedimout.insert(flattenedimout.end(), v.begin(), v.end());
		}
		std::sort(flattenedimout.begin(), flattenedimout.end());
		float mymin = flattenedimout[round(0.03 * outputImagePoints * numOutputImages)];
		float mymax = flattenedimout[round(0.97 * outputImagePoints * numOutputImages)];

		for (int imcount = 0; imcount < numOutputImages; imcount++)
			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint16_t pos = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * chancount;
				pos += (outputWidth + 2) * imcount + i + 1 + (j + 1) * outputMontageWidth;
				float toout = outputImageStack[imcount][i + j * outputWidth];
				montage[pos] = max(min(65000 * (toout - mymin) / (mymax - mymin), (float)65000), (float)1);
			}


		//output full stacks for particle

		for (int imcount = 0; imcount < totnumofframes; imcount++) {

			vcinput[chancount]->read1dImage(imcount, imagein);

			if (chancount > 0) {
				//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
				transformclass.transform(imagein, imaget, channelalignment[chancount - 1][1] * 3.14159 / 180.0, channelalignment[chancount - 1][2], -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4]);
				imagein = imaget;
			}
			//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
			transformclass.imageTranslate(imagein, imaget, -drifts[imcount][0], -drifts[imcount][1]);

			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					float toout = imaget[pos];
					singleFrame[i + j * outputWidth] = max(min(65000 * (toout - mymin) / (mymax - mymin), (float)65000), (float)1);
				}
			}

			if(bOutputImageStack && tiffout!=NULL)tiffout->write1dImage(singleFrame);

		}


	}



	BLTiffIO::TiffOutput(outputfile + "_Trace_" + to_string(particle) + "_Range_" + to_string(start + 1) + "_" + to_string(delta) + "_" + to_string(end) + "_montage.tiff", outputMontageWidth, (outputHeight + 2) * numInputFiles, 16, false).write1dImage(montage);




/*
	for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
		BLTiffIO::TiffOutput tiffout(outputfile + "_Particle_" + to_string(particle) + "_Range_" + to_string(start + 1) + "_" + to_string(delta) + "_" + to_string(end)+"_Channel_"+ to_string(channelcount+1)+".tiff", outputWidth, outputHeight, imageDepth, false);
		for (int imcount = 0; imcount < numOutputImages; imcount++) {
			vector<float> meanimage(imagePoints, 0.0);
			CountImAveraged = 0;
			for (int avcount = -average; avcount <= average; avcount++) {
				int iminnum = start + imcount * delta + avcount;
				if (iminnum >= 0 && iminnum < totnumofframes) {
					vcinput[channelcount]->read1dImage(iminnum, image1);
					
					if (channelcount > 0) {
						transxoffset = (-drifts[iminnum][0]) * channelalignment[channelcount - 1][5] + (-drifts[iminnum][1]) * channelalignment[channelcount - 1][6];
						transyoffset = (-drifts[iminnum][0]) * channelalignment[channelcount - 1][7] + (-drifts[iminnum][1]) * channelalignment[channelcount - 1][8];
					}
					else {
						transxoffset = (-drifts[iminnum][0]);
						transyoffset = (-drifts[iminnum][1]);
					}
					//cout << transxoffset << " " << transyoffset<<"\n";
					transformclass.imageTranslate(image1, alignedimage, transxoffset, transyoffset);
					ippsAdd_32f_I(alignedimage.data(), meanimage.data(), imagePoints);
					CountImAveraged++;
				}
			}
			ippsDivC_32f_I((float) CountImAveraged, meanimage.data(), imagePoints);


			if (channelcount > 0) transformclass.transform(meanimage, translated, channelalignment[channelcount - 1][1] * 3.14159 / 180.0, channelalignment[channelcount - 1][2], -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4]);
			else translated = meanimage;

			//troubleshooting.write1dImage(translated);
			//cout << measurements[particle - 1][14] << " " << measurements[particle - 1][15] << " " << measurements[particle - 1][16] << " " << measurements[particle - 1][17] <<" "<< outputStart<<" "<<imagePoints<< "\n";

			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					avimageout[imcount][i + j * outputWidth] = translated[pos];
					flattenedimout[imcount* outputImagePoints +i + j * outputWidth] = translated[pos];
					//cout << pos <<" "<< outputStart <<" "<< outputStart + i + j * imageWidth << "\n";
				}
			}

			tiffout.write1dImage(avimageout[imcount]);
		}


		std::sort(flattenedimout.begin(), flattenedimout.end());
		float mymin = flattenedimout[round(0.03 * outputImagePoints * numOutputImages)];
		float mymax = flattenedimout[round(0.97 * outputImagePoints * numOutputImages)];
		for (int imcount = 0; imcount < numOutputImages; imcount++)
			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
			uint16_t pos = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * channelcount;
			pos += (outputWidth + 2) * imcount + i + 1 + (j + 1) * outputMontageWidth;
			float toout = avimageout[imcount][i + j * outputWidth];
			montage[pos] = max(min(65000*(toout - mymin) / (mymax - mymin), (float)65000), (float)1);
		}
		BLTiffIO::TiffOutput(outputfile + "_Particle_" + to_string(particle) + "_Range_" + to_string(start + 1) + "_" + to_string(delta) + "_" + to_string(end) + "montage.tiff", outputMontageWidth, (outputHeight + 2)* numInputFiles, 16, false).write1dImage(montage);

	}
	*/
	//system("PAUSE");
	return 0;
}