#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;


int main(int argc, char *argv[])
{

	bool inputalignment = false;

	if (argc < 2) { cout << "could not read files" << endl; return 1; }
	string outputfile = argv[1];

	int numInputFiles = 0;

	for (int i = 2; i < argc && std::string(argv[i]) != "-Alignment"; i++) numInputFiles++;

	vector<string> inputfiles(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 2];

	cout << "Aligning " << numInputFiles << " Image Stacks" << endl;


	vector<BLTiffIO::MultiPageTiffInput> vcinput(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)vcinput[i] = BLTiffIO::MultiPageTiffInput(inputfiles[i]);

	int imageDepth = vcinput[0].imageBitDepth();
	int imageWidth = vcinput[0].imageWidth();
	int imageHeight = vcinput[0].imageHeight();
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = vcinput[0].totalNumberofFrames();


	imageTransform_32f transformclass(imageWidth, imageHeight);

	IppiSize roiSize = { imageWidth,imageHeight };
	int srcStep = imageWidth * sizeof(float);



	//int trimmedwidth = imageWidth, trimmedheight = imageHeight, firstpoint = 0;


	vector<float> image1(imagePoints,0);
	vector<vector<float>> meanimage(numInputFiles, vector<float>(imagePoints, 0.0));
	vector<float> alignedimage(imagePoints, 0.0),combinedfull(imagePoints, 0.0);



	int trimmedwidth = round(0.9*imageWidth), trimmedheight = round(0.9*imageHeight), firstpoint = (int)(imageWidth - trimmedwidth) / 2 + ((int)((imageHeight - trimmedheight) / 2))*imageWidth;

	vector<float> trimmedimage(trimmedwidth*trimmedheight), trimmedchannel1(trimmedwidth*trimmedheight);
	alignImages_32f alignclasst(10, trimmedwidth, trimmedheight);
	IppiSize trimmedroiSize = { trimmedwidth, trimmedheight };

	ippiCopy_32f_C1R(&meanimage[0][firstpoint], srcStep, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);

	vector<float> rotimage(imagePoints), scaleimage(imagePoints);

	vector<vector<float>> channelalignment(numInputFiles - 1, vector<float>(11, 0.0));
	vector<vector<float>> drifts(totnumofframes, vector<float>(2, 0.0));

	vector<float> combinedimage(trimmedwidth*trimmedheight), combinedimage2(trimmedwidth*trimmedheight);
	ippiAdd_32f_C1IR(trimmedchannel1.data(), trimmedwidth * sizeof(float), combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);

	float maxcc = 0, maxangle = 0, maxscale = 1, deltain = 100, hmaxscale, hmaxangle, xoffset, yoffset;

	vector<float> translated(imagePoints);

	float invnum = 1.0 / (totnumofframes);
	string adjustedOutputFilename;

	alignImages_32f alignclass(10, imageWidth, imageHeight);

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Alignment") {
			inputalignment = true;
			for (int j = 0; j < numInputFiles-1; j++) {
				if (i + 4 * j < argc) {


					xoffset = stod(argv[i + (4 * j) + 1]);
					yoffset = stod(argv[i + (4 * j) + 2]);
					maxangle = stod(argv[i + (4 * j) + 3]);
					maxscale = stod(argv[i + (4 * j) + 4]);

					channelalignment[j][0] = 0;
					channelalignment[j][1] = maxangle;
					channelalignment[j][2] = maxscale;
					channelalignment[j][3] = xoffset;
					channelalignment[j][4] = yoffset;

					channelalignment[j][5] = cos(maxangle * 3.14159 / 180.0) / maxscale;
					channelalignment[j][6] = -sin(maxangle * 3.14159 / 180.0) / maxscale;
					channelalignment[j][7] = sin(maxangle * 3.14159 / 180.0) / maxscale;
					channelalignment[j][8] = cos(maxangle * 3.14159 / 180.0) / maxscale;

					channelalignment[j][9] = imageWidth / 2.0;
					channelalignment[j][10] = imageHeight / 2.0;

					cout << "Alignment for Channel "<<j+2<<" xoffset set to  " <<xoffset<< " yoffset set to  " << yoffset << " rotation set to  " << maxangle<< " scale set to  "<< maxscale<<"\n";
				}
				else { std::cout << "error inputting alignment" << std::endl; return 1; }
			}

			ippiMulC_32f_C1IR(1.0 / numInputFiles, combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
		}

	}


	if (inputalignment) {
		cout << "Creating initial combined mean\n";


		for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
			cout << "Creating Mean of Channel " << channelcount + 1 << endl;

			for (int imcount = 0; imcount < totnumofframes; imcount++) {
				vcinput[channelcount].GetImage1d(imcount, image1);
				ippiAdd_32f_C1IR(image1.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
			}
			ippiMulC_32f_C1IR(invnum, meanimage[channelcount].data(), srcStep, roiSize);
			adjustedOutputFilename = outputfile + "_initial_mean_" + to_string(channelcount + 1) + ".tiff";
			BLTiffIO::WriteSinglePage1D(meanimage[channelcount], adjustedOutputFilename, imageWidth, imageDepth);

			if (channelcount == 0) {
				maxangle = 0;
				maxscale = 1;
				xoffset = 0;
				yoffset = 0;

			}
			else {
				maxangle = channelalignment[channelcount - 1][1];
				maxscale = channelalignment[channelcount - 1][2];
				xoffset = channelalignment[channelcount - 1][3];
				yoffset = channelalignment[channelcount - 1][4];

			}
			//cout << "Alignment for Channel " << channelcount << " xoffset set to  " << xoffset << " yoffset set to  " << yoffset << " rotation set to  " << maxangle << " scale set to  " << maxscale << "\n";


			transformclass.imageRotate(meanimage[channelcount], rotimage, maxangle*3.14159 / 180.0);
			transformclass.imageScale(rotimage, scaleimage, maxscale);
			transformclass.imageTranslate(scaleimage, translated, -xoffset, -yoffset);

			ippiCopy_32f_C1R(&translated[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
			ippiAdd_32f_C1IR(trimmedimage.data(), trimmedwidth * sizeof(float), combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
		}

		ippiMulC_32f_C1IR(1.0/(numInputFiles), combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);


		cout << "Calculating Aligned Mean" << endl;

		for (int iterativecount = 0; iterativecount < 3; iterativecount++) {
			cout << "Iteration " << iterativecount + 1 << endl;
			for (int imcount = 0; imcount < totnumofframes; imcount++) {
				vcinput[0].GetImage1d(imcount, image1);
				combinedfull = image1;
				ippiCopy_32f_C1R(&image1[firstpoint], srcStep, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);
				for (int channelcount = 1; channelcount < numInputFiles; channelcount++) {
					vcinput[channelcount].GetImage1d(imcount, image1);

					transformclass.imageRotate(image1, rotimage, channelalignment[channelcount - 1][1] * 3.14159 / 180.0);
					transformclass.imageScale(rotimage, scaleimage, channelalignment[channelcount - 1][2]);
					transformclass.imageTranslate(scaleimage, alignedimage, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4]);

					ippiCopy_32f_C1R(&alignedimage[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
					ippiAdd_32f_C1IR(trimmedimage.data(), trimmedwidth * sizeof(float), trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);

					ippiAdd_32f_C1IR(alignedimage.data(), imageWidth * sizeof(float), combinedfull.data(), imageWidth * sizeof(float), roiSize);
				}

				ippiMulC_32f_C1IR(1.0 / numInputFiles, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);

				alignclasst.imageAlign(combinedimage, trimmedchannel1);

				drifts[imcount][0] = alignclasst.offsetx;
				drifts[imcount][1] = alignclasst.offsety;
				//cout << drifts[imcount][0] << " " << drifts[imcount][1] << endl;

				//Align Iteratively
				transformclass.imageTranslate(combinedfull, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);


				ippiCopy_32f_C1R(&alignedimage[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
				ippiAdd_32f_C1IR(trimmedimage.data(), trimmedwidth * sizeof(float), combinedimage2.data(), trimmedwidth * sizeof(float), trimmedroiSize);
			}
			ippiMulC_32f_C1IR(1.0 / totnumofframes, combinedimage2.data(), trimmedwidth * sizeof(float), trimmedroiSize);
			combinedimage = combinedimage2;
			combinedimage2 = vector<float>(trimmedwidth*trimmedheight, 0.0);
		}

	}





	if (inputalignment == false) {
		
		for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
			cout << "Creating Mean of Channel " << channelcount + 1 << endl;

			for (int imcount = 0; imcount < totnumofframes; imcount++) {
				vcinput[channelcount].GetImage1d(imcount, image1);
				ippiAdd_32f_C1IR(image1.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
			}
			ippiMulC_32f_C1IR(invnum, meanimage[channelcount].data(), srcStep, roiSize);
			adjustedOutputFilename = outputfile + "_initial_mean_" + to_string(channelcount + 1) + ".tiff";
			BLTiffIO::WriteSinglePage1D(meanimage[channelcount], adjustedOutputFilename, imageWidth, imageDepth);
		}


		vector<vector<float>> meanimage2(numInputFiles, vector<float>(imagePoints, 0.0));


		vector<float>translatedintermediate(4 * imagePoints);
		IppiSize interroiSize = { 2 * imageWidth,2 * imageHeight };
		int intersrcStep = 2 * imageWidth * sizeof(float);
		int zeroval = imageWidth / 2 + imagePoints;

		cout << "Creating secondary Mean " << endl;
		for (int loopcount = 0; loopcount < 3; loopcount++) {
			cout << "Iteration " << loopcount + 1 << endl;
			for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {


				for (int imcount = 0; imcount < totnumofframes; imcount++) {
					vcinput[channelcount].GetImage1d(imcount, image1);

					//alignclass.imageAligntopixel(meanimage[channelcount], image1);
					//ippiCopyWrapBorder_32f_C1R(image1.data(), srcStep, roiSize, translatedintermediate.data(), intersrcStep, interroiSize, imageHeight / 2, imageWidth / 2);
					//ippiCopy_32f_C1R(&translatedintermediate[zeroval - alignclass.offsetx - alignclass.offsety * 2 * imageWidth], intersrcStep, translated.data(), srcStep, roiSize);

					alignclass.imageAlign(meanimage[channelcount], image1);
					transformclass.imageTranslate(image1, translated, -alignclass.offsetx, -alignclass.offsety);

					ippiAdd_32f_C1IR(translated.data(), srcStep, meanimage2[channelcount].data(), srcStep, roiSize);
					//cout << alignclass.offsetx << " " << alignclass.offsety << endl;
				}
				ippiMulC_32f_C1IR(invnum, meanimage2[channelcount].data(), srcStep, roiSize);
				//cout << endl;
			}

			for (int i = 0; i < numInputFiles; i++)meanimage[i] = meanimage2[i];
		}
		/*	for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
				adjustedOutputFilename = outputfile + "_secondary_mean_" + to_string(channelcount + 1) + ".tiff";
				BLTiffIO::WriteSinglePage1D(meanimage[channelcount], adjustedOutputFilename, imageWidth, imageDepth);
			}*/


		ippiCopy_32f_C1R(&meanimage[0][firstpoint], srcStep, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);


		for (int i = 1; i < numInputFiles; i++) {
			cout << "Aligning Channel " << i + 1 << endl;
			maxcc = 0;
			deltain = 10;
			for (int delta = 0; delta < 3; delta++) {
				deltain *= 0.1;
				hmaxscale = maxscale;
				hmaxangle = maxangle;


				for (double scale = hmaxscale - 0.0075*deltain; scale <= hmaxscale + 0.00751*deltain; scale = scale + 0.0025*deltain)for (double angle = hmaxangle - 0.75*deltain; angle <= hmaxangle + 0.75*deltain; angle = angle + 0.125*deltain) {
					transformclass.imageRotate(meanimage[i], rotimage, angle*3.14159 / 180.0);
					transformclass.imageScale(rotimage, scaleimage, scale);

					alignclass.imageAligntopixel(meanimage[0], scaleimage);

					ippiCopyWrapBorder_32f_C1R(scaleimage.data(), srcStep, roiSize, translatedintermediate.data(), intersrcStep, interroiSize, imageHeight / 2, imageWidth / 2);
					ippiCopy_32f_C1R(&translatedintermediate[zeroval - alignclass.offsetx - alignclass.offsety * 2 * imageWidth], intersrcStep, translated.data(), srcStep, roiSize);

					ippiCopy_32f_C1R(&translated[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
					alignclasst.imageAligntopixel(trimmedchannel1, trimmedimage);

					if (alignclasst.max1dval > maxcc) {
						maxcc = alignclasst.max1dval;
						maxangle = angle;
						maxscale = scale;
						xoffset = alignclasst.offsetx + alignclass.offsetx;
						yoffset = alignclasst.offsety + alignclass.offsety;
						//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;
					}
				}

			}

			//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;
			cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

			if (abs(maxangle) > 0.59 || abs(maxscale-1) > 0.007) {
				cout << "WARNING SEEM TO BE FITTING NOISE:WILL IGNORE ROTATION AND SCALING" << endl;
				maxcc = 0;
				maxangle = 0;
				maxscale = 1;
			}


			//Might need to Improve here
			transformclass.imageRotate(meanimage[i], rotimage, maxangle*3.14159 / 180.0);
			transformclass.imageScale(rotimage, scaleimage, maxscale);
			alignclass.imageAligntopixel(meanimage[0], scaleimage);
			ippiCopyWrapBorder_32f_C1R(scaleimage.data(), srcStep, roiSize, translatedintermediate.data(), intersrcStep, interroiSize, imageHeight / 2, imageWidth / 2);
			ippiCopy_32f_C1R(&translatedintermediate[zeroval - alignclass.offsetx - alignclass.offsety * 2 * imageWidth], intersrcStep, translated.data(), srcStep, roiSize);
			ippiCopy_32f_C1R(&translated[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
			alignclasst.imageAlign(trimmedchannel1, trimmedimage);
			xoffset = alignclasst.offsetx + alignclass.offsetx;
			yoffset = alignclasst.offsety + alignclass.offsety;

			//end imporove


			cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;
			if (abs(xoffset) > 40 || abs(yoffset) > 40) {
				cout << "alignment failed" << endl;
				maxcc = 0;
				maxangle = 0;
				maxscale = 1;
				xoffset = 0;
				yoffset = 0;
			}



			channelalignment[i - 1][0] = maxcc;
			channelalignment[i - 1][1] = maxangle;
			channelalignment[i - 1][2] = maxscale;
			channelalignment[i - 1][3] = xoffset;
			channelalignment[i - 1][4] = yoffset;

			channelalignment[i - 1][5] = cos(maxangle * 3.14159 / 180.0) / maxscale;
			channelalignment[i - 1][6] = -sin(maxangle * 3.14159 / 180.0) / maxscale;
			channelalignment[i - 1][7] = sin(maxangle * 3.14159 / 180.0) / maxscale;
			channelalignment[i - 1][8] = cos(maxangle * 3.14159 / 180.0) / maxscale;

			channelalignment[i - 1][9] = imageWidth / 2.0;
			channelalignment[i - 1][10] = imageHeight / 2.0;


			transformclass.imageRotate(meanimage[i], rotimage, maxangle*3.14159 / 180.0);
			transformclass.imageScale(rotimage, scaleimage, maxscale);
			transformclass.imageTranslate(scaleimage, translated, -xoffset, -yoffset);


			//adjustedOutputFilename = outputfile + "initial_aligned_mean_"+to_string(i+1)+".tiff";
			//BLTiffIO::WriteSinglePage1D(translated, adjustedOutputFilename, imageWidth, imageDepth);

			ippiCopy_32f_C1R(&translated[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
			ippiAdd_32f_C1IR(trimmedimage.data(), trimmedwidth * sizeof(float), combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);
		}

		ippiMulC_32f_C1IR(1.0 / numInputFiles, combinedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);

		//adjustedOutputFilename = outputfile + "_mean_Combined.tiff";
		//BLTiffIO::WriteSinglePage1D(combinedimage, adjustedOutputFilename, trimmedwidth, imageDepth);
	}


	cout << "Calculating Drifts" << endl;
	for (int imcount = 0; imcount < totnumofframes; imcount++) {
		vcinput[0].GetImage1d(imcount, image1);
		ippiCopy_32f_C1R(&image1[firstpoint], srcStep, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);
		for (int channelcount = 1; channelcount < numInputFiles; channelcount++) {
			vcinput[channelcount].GetImage1d(imcount, image1);

			transformclass.imageRotate(image1, rotimage, channelalignment[channelcount - 1][1] * 3.14159 / 180.0);
			transformclass.imageScale(rotimage, scaleimage, channelalignment[channelcount - 1][2]);
			transformclass.imageTranslate(scaleimage, alignedimage, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4]);
			ippiCopy_32f_C1R(&alignedimage[firstpoint], srcStep, trimmedimage.data(), trimmedwidth * sizeof(float), trimmedroiSize);

			ippiAdd_32f_C1IR(trimmedimage.data(), trimmedwidth * sizeof(float), trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);
		}

		ippiMulC_32f_C1IR(1.0 / numInputFiles, trimmedchannel1.data(), trimmedwidth * sizeof(float), trimmedroiSize);

		alignclasst.imageAlign(combinedimage, trimmedchannel1);

		drifts[imcount][0] = alignclasst.offsetx;
		drifts[imcount][1] = alignclasst.offsety;
		//cout << drifts[imcount][0] << " " << drifts[imcount][1] << endl;

	}

	float transxoffset, transyoffset;
	cout << "Generating Mean Images" << endl;
	meanimage = vector<vector<float>>(numInputFiles, vector<float>(imagePoints, 0.0));

	vector<float>Combinedmeanimage = vector<float>(imagePoints, 0.0);
	


	for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
		if (channelcount == 0) {
			for (int imcount = 0; imcount < totnumofframes; imcount++) {
				vcinput[channelcount].GetImage1d(imcount, image1);
				transformclass.imageTranslate(image1, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);
				ippiAdd_32f_C1IR(alignedimage.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
			}
			
		}
		else {
			for (int imcount = 0; imcount < totnumofframes; imcount++) {
				/*transxoffset = (-drifts[imcount][0])*cos(channelalignment[channelcount - 1][1] * 3.14159 / 180.0) - (-drifts[imcount][1])*sin(channelalignment[channelcount - 1][1] * 3.14159 / 180.0);
				transxoffset *= 1 / channelalignment[channelcount - 1][2];
				transyoffset = (-drifts[imcount][0])*sin(channelalignment[channelcount - 1][1] * 3.14159 / 180.0) + (-drifts[imcount][1])*cos(channelalignment[channelcount - 1][1] * 3.14159 / 180.0);
				transyoffset *= 1 / channelalignment[channelcount - 1][2];*/
				transxoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][5] + (-drifts[imcount][1])*channelalignment[channelcount - 1][6];
				transyoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][7] + (-drifts[imcount][1])*channelalignment[channelcount - 1][8];
				vcinput[channelcount].GetImage1d(imcount, image1);
				transformclass.imageTranslate(image1, alignedimage, transxoffset, transyoffset);
				ippiAdd_32f_C1IR(alignedimage.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
			}
		}
		ippiMulC_32f_C1IR(invnum, meanimage[channelcount].data(), srcStep, roiSize);

		adjustedOutputFilename = outputfile + "_final_mean_" + to_string(channelcount + 1) + ".tiff";
		BLTiffIO::WriteSinglePage1D(meanimage[channelcount], adjustedOutputFilename, imageWidth, imageDepth);

		if (channelcount > 0) {
			transformclass.imageRotate(meanimage[channelcount], rotimage, channelalignment[channelcount - 1][1] * 3.14159 / 180.0);
			transformclass.imageScale(rotimage, scaleimage, channelalignment[channelcount - 1][2]);
			transformclass.imageTranslate(scaleimage, translated, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4]);

			adjustedOutputFilename = outputfile + "_final_mean_aligned_" + to_string(channelcount + 1) + ".tiff";
			BLTiffIO::WriteSinglePage1D(translated, adjustedOutputFilename, imageWidth, imageDepth);

			ippiAdd_32f_C1IR(translated.data(), srcStep, Combinedmeanimage.data(), srcStep, roiSize);
		}
		else ippiAdd_32f_C1IR(meanimage[0].data(), srcStep, Combinedmeanimage.data(), srcStep, roiSize);
	}

	ippiMulC_32f_C1IR(1.0/numInputFiles, Combinedmeanimage.data(), srcStep, roiSize);

	BLCSVIO::writeCSV(outputfile + "_Drifts.csv", drifts, "X Drift, Y Drift\n");

	if (numInputFiles > 1) {
		adjustedOutputFilename = outputfile + "_final_Combined_Mean_Image.tiff";
		BLTiffIO::WriteSinglePage1D(Combinedmeanimage, adjustedOutputFilename, imageWidth, imageDepth);
		BLCSVIO::writeCSV(outputfile + "_channel_alignment.csv", channelalignment, "Cross Correlation,Angle of Rotation, Scale, X offset, Y offset, X component of X translated, Y Component of X translated,X component of Y translated, Y Component of Y translated,X Rotation Point,Y Rotation Point\n");
	}
	

	//system("PAUSE");



}