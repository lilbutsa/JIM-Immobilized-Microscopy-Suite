#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>

using namespace std;

void Read_Micromanager_Metadata(string filename, vector<vector<int>>& stackorder);

//column search
template< class T >
struct ColumnAdapter {
	ColumnAdapter(size_t column) : m_column(column) {}
	bool operator()(const std::vector< T > & left, const std::vector< T > & right) {
		return left.at(m_column) < right.at(m_column);
	}
private:
	size_t m_column;
};



int main(int argc, char *argv[])
{
	bool bmetadata = false;
	string metadatafile;

	if (argc < 3) { cout << "could not read files" << endl; return 1; }
	string inputfile = argv[1];
	string outputfile = argv[2];

	int totchannelnum = 2;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-NumberOfChannels") {.

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
	

	BLTiffIO::MultiPageTiffInput inputstack(inputfile);

	string outputfilename;

	int imageDepth = inputstack.imageBitDepth();
	int imageWidth = inputstack.imageWidth();
	int imageHeight = inputstack.imageHeight();
	int totnumofframes = inputstack.totalNumberofFrames();

	vector<float> image;
	int framesperchannel;

	if (bmetadata) {
		vector<vector<int>> stackorder;
		Read_Micromanager_Metadata(metadatafile, stackorder);

		if (stackorder.size() != totnumofframes) { 
			cout << "Error : Total number of frames in the Image Stack (" << totnumofframes << ") does not match the number of frames in the metadata (" << stackorder.size() << ")\n";
			return 1;
		}
		totchannelnum = (*max_element(stackorder.begin(), stackorder.end(), ColumnAdapter< int >(1)))[1]+1;

		framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;

		for (int i = 0; i < totchannelnum; i++) {
			outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout <<"Writing out "<< outputfilename << endl;
			BLTiffIO::MultiPageTiffOutput output(outputfilename, framesperchannel, imageDepth, imageWidth, imageHeight);
			for (int j = 0; j < totnumofframes; j++) {
				if (stackorder[j][1] == i) {
					//cout << "Adding image " << j << " to channel " << i << "\n";
					inputstack.GetImage1d(j, image);
					output.WriteImage1d(stackorder[j][0], image);
				}
			}
		}
	}
	else {

		framesperchannel = totnumofframes / totchannelnum;

		cout << "Total Number of Frames : " << totnumofframes << endl;
		cout << "Frames Per Channel : " << framesperchannel << endl;



		for (int i = 0; i < totchannelnum; i++) {
			outputfilename = outputfile + "_Channel_" + to_string(i + 1) + ".tiff";
			cout << outputfilename << endl;
			BLTiffIO::MultiPageTiffOutput output(outputfilename, framesperchannel, imageDepth, imageWidth, imageHeight);
			for (int j = 0; j < framesperchannel; j++) {
				inputstack.GetImage1d(j*totchannelnum + i, image);
				output.WriteImage1d(j, image);
			}
		}
	}
	//system("PAUSE");
}













