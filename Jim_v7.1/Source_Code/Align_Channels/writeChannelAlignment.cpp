#include "myHeader.hpp"

void writeChannelAlignment(string outputfile, vector< vector< float>>& alignments,int imageWidth, int imageHeight) {

	int numchan = alignments.size();

	vector< vector<float> > channelalignment(numchan, vector<float>(11, 0.0));

	for (int i = 0; i < numchan; i++) {
		channelalignment[i][0] = i+2;
		channelalignment[i][1] = alignments[i][2];
		channelalignment[i][2] = alignments[i][3];
		channelalignment[i][3] = alignments[i][0];
		channelalignment[i][4] = alignments[i][1];

		channelalignment[i][5] = cos(alignments[i][2] * 3.14159 / 180.0) / alignments[i][3];
		channelalignment[i][6] = -sin(alignments[i][2] * 3.14159 / 180.0) / alignments[i][3];
		channelalignment[i][7] = sin(alignments[i][2] * 3.14159 / 180.0) / alignments[i][3];
		channelalignment[i][8] = cos(alignments[i][2] * 3.14159 / 180.0) / alignments[i][3];

		channelalignment[i][9] = imageWidth / 2.0;
		channelalignment[i][10] = imageHeight / 2.0;
	}


	BLCSVIO::writeCSV(outputfile + "_Channel_To_Channel_Alignment.csv", channelalignment, "Channel Number,Angle of Rotation, Scale, X offset, Y offset, X component of X translated, Y Component of X translated,X component of Y translated, Y Component of Y translated,X Rotation Point,Y Rotation Point\n");

}