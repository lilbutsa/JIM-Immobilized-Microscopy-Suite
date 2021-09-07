#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"


using namespace std;

void Read_Micromanager_Metadata(string filename, vector<vector<int>>& stackorder);

void getStackOrder(vector<BLTiffIO::TiffInput*>& vis, vector<vector<vector<int>>>& stackorderout);

int main(int argc, char* argv[])
{
	bool bmetadata = true;
	bool bBigTiff = false;
	string metadatafile;
	vector<string> inputfiles;

	if (argc < 3) { cout << "could not read files" << endl; return 1; }
	string outputfile = argv[1];

	for (int i = 2; i < argc; i++) {
		string argin = argv[i];
		if (argin.find("-") == 0)break;
		else inputfiles.push_back(argin);
	}

	int totchannelnum = 2;

	for (int i = 2 + inputfiles.size(); i < argc; i++) {
		if (std::string(argv[i]) == "-NumberOfChannels") {
			if (i + 1 < argc) {
				totchannelnum = stoi(argv[i + 1]);
				cout << "Number of channels set to " << totchannelnum << endl;
			}
			else { std::cout << "error inputting number of channels" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-DisableMetadata") {
			bmetadata = false;
			cout << "Metadata Disabled" << endl;
		}
		if (std::string(argv[i]) == "-BigTiff") bBigTiff = true;

	}


	int numInputFiles = inputfiles.size();
	if (numInputFiles > 1)bBigTiff = true;
	vector<BLTiffIO::TiffInput*> vis(numInputFiles);
	for (int i = 0; i < numInputFiles; i++) {
		vis[i] = new BLTiffIO::TiffInput(inputfiles[i]);
		if (vis[i]->bigtiff)bBigTiff = true;
	}

	int imageDepth = vis[0]->imageDepth;
	int imageWidth = vis[0]->imageWidth;
	int imageHeight = vis[0]->imageHeight;

	if (bBigTiff) cout << "Outputting Big Tiff" << endl;

	vector<float> image;

	if (bmetadata && vis[0]->OMEmetadataDetected) {
		cout << "OME metadata Detected\n";
		vector < vector<vector<int>>> stackorderout;
		getStackOrder(vis, stackorderout);

		for (int i = 0; i < stackorderout.size(); i++) {
			string outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);
			for (int j = 0; j < stackorderout[i].size(); j++) {
				if (stackorderout[i][j][0] == -1) {
					cout << "Warning image " << j + 1 << " of channel " << i+1 << " not found\n"; continue;
				}
				vis[stackorderout[i][j][0]]->read1dImage(stackorderout[i][j][1], image);
				output.write1dImage(image);
			}
		}

	}
	else {
		cout << "OME metadata was NOT Detected\n";
		int totnumofframes = 0;
		for (int i = 0; i < numInputFiles; i++) {
			totnumofframes += vis[i]->numOfFrames;
			if (vis[i]->imageDepth != imageDepth || vis[i]->imageHeight != imageHeight || vis[i]->imageWidth != imageWidth) {
				cout << "All Images Must Be the same size " << endl;
				return -1;
			}
		}

		int framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;


		for (int i = 0; i < totchannelnum; i++) {
			string outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);
			for (int j = i; j < totnumofframes; j = j + totchannelnum) {
				int imageNumber = j;
				int fileNumber = 0;
				while (imageNumber >= (vis[fileNumber]->numOfFrames)) {
					imageNumber = imageNumber - (vis[fileNumber]->numOfFrames);
					fileNumber++;
				}
				vis[fileNumber]->read1dImage(imageNumber, image);
				output.write1dImage(image);
			}
		}
	}

	return 0;

}
/*
	if(bBigTiff) cout << "Outputting Big Tiff" << endl;

	vector<float> image;
	int framesperchannel;

	if (bmetadata) {
		vector<vector<int>> stackorder;
		Read_Micromanager_Metadata(metadatafile, stackorder);		

		totchannelnum = stackorder.size();
		framesperchannel = stackorder[0].size();
		

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;

		//vector<BLTiffIO::TiffOutput*> voutput(totchannelnum);
		//for (int i = 0; i < totchannelnum; i++)voutput[i] = new BLTiffIO::TiffOutput(outputfile + "_Channel_" + to_string(i + 1) + ".tiff", imageWidth, imageHeight, imageDepth, bBigTiff);

		for (int i = 0; i < totchannelnum; i++) {
			string outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);
			for (int j = 0; j < stackorder[i].size(); j++) {
				if (stackorder[i][j] == -1) {
					cout << "Warning image "<<j+1<<" of channel "<<i<<"not found\n"; continue;
				}
				int imageNumber = stackorder[i][j];
				int fileNumber = 0;
				while (imageNumber >= (vis[fileNumber]->numOfFrames)) {
					imageNumber = imageNumber - (vis[fileNumber]->numOfFrames);
					fileNumber++;
				}
				vis[fileNumber]->read1dImage(imageNumber, image);
				output.write1dImage(image);
			}
		}

	}
	else {

		framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;


		for (int i = 0; i < totchannelnum; i++) {
			string outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);
			for (int j = i; j < totnumofframes; j = j + totchannelnum) {
				int imageNumber = j;
				int fileNumber = 0;
				while (imageNumber >= (vis[fileNumber]->numOfFrames)) {
					imageNumber = imageNumber - (vis[fileNumber]->numOfFrames);
					fileNumber++;
				}
				vis[fileNumber]->read1dImage(imageNumber, image);
				output.write1dImage(image);
			}
		}
	}
}
*/


/*

int main(int argc, char* argv[])
{
	bool bmetadata = false;
	string metadatafile;

	if (argc < 3) { cout << "could not read files" << endl; return 1; }
	string inputfile = argv[1];
	string outputfile = argv[2];

	int totchannelnum = 2;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-NumberOfChannels") {
			if (i + 1 < argc) {
				totchannelnum = stoi(argv[i + 1]);
				cout << "Number of channels set to " << totchannelnum << endl;
			}
			else { std::cout << "error inputting number of channels" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-MetadataFile") {
			if (i + 1 < argc) {
				metadatafile = argv[i + 1];
				bmetadata = true;
				cout << "Metadata being read from " << metadatafile << endl;
			}
			else { std::cout << "error inputting metadata file" << std::endl; return 1; }
		}
	}


	cout << "Input : " << inputfile << endl;
	cout << "Output : " << outputfile << endl;

	BLTiffIO::TiffInput inputstack(inputfile);


	string outputfilename;

	int imageDepth = inputstack.imageDepth;
	int imageWidth = inputstack.imageWidth;
	int imageHeight = inputstack.imageHeight;
	int totnumofframes = inputstack.numOfFrames;

	vector<float> image;
	int framesperchannel;

	if (bmetadata) {
		vector<vector<int>> stackorder;
		Read_Micromanager_Metadata(metadatafile, stackorder);

		if (stackorder.size() != totnumofframes) {
			cout << "Error : Total number of frames in the Image Stack (" << totnumofframes << ") does not match the number of frames in the metadata (" << stackorder.size() << ")\n";
			return 1;
		}

		totchannelnum = (*max_element(stackorder.begin(), stackorder.end(), ColumnAdapter< int >(1)))[1] + 1;

		framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;

		for (int i = 0; i < totchannelnum; i++) {
			BLTiffIO::TiffInput inputstack2(inputfile);
			outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth);
			for (int j = 0; j < totnumofframes; j++) {
				//cout << i << "\n";
				inputstack2.read1dImage(j, image);
				if (stackorder[j][1] == i) {
					//cout << "Adding image " << j << " to channel " << i << "\n";
					output.write1dImage(image);
				}
			}
		}
	}
	else {

		framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;


		for (int i = 0; i < totchannelnum; i++) {
			BLTiffIO::TiffInput inputstack2(inputfile);
			outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << "Writing out " << outputfilename << endl;
			BLTiffIO::TiffOutput output(outputfilename, imageWidth, imageHeight, imageDepth);
			for (int j = 0; j < totnumofframes; j++) {
				inputstack2.read1dImage(j, image);
				if (j % totchannelnum == i) {
					//cout << "Adding image " << j << " to channel " << i << "\n";
					output.write1dImage(image);
				}
			}
		}
	}
	//	system("PAUSE");
}


*/










