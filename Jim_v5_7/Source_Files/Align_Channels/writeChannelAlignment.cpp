#include "myHeader.hpp"

void writeChannelAlignment(string outputfile, vector<float>&angle, vector<float>&scale, vector<float>&xoffset, vector<float>&yoffset,int imageWidth, int imageHeight) {

	int numchan = angle.size();

	vector< vector<float> > channelalignment(numchan, vector<float>(11, 0.0));

	for (int i = 0; i < numchan; i++) {
		channelalignment[i][0] = i+2;
		channelalignment[i][1] = angle[i];
		channelalignment[i][2] = scale[i];
		channelalignment[i][3] = xoffset[i];
		channelalignment[i][4] = yoffset[i];

		channelalignment[i][5] = cos(angle[i] * 3.14159 / 180.0) / scale[i];
		channelalignment[i][6] = -sin(angle[i] * 3.14159 / 180.0) / scale[i];
		channelalignment[i][7] = sin(angle[i] * 3.14159 / 180.0) / scale[i];
		channelalignment[i][8] = cos(angle[i] * 3.14159 / 180.0) / scale[i];

		channelalignment[i][9] = imageWidth / 2.0;
		channelalignment[i][10] = imageHeight / 2.0;
	}


	BLCSVIO::writeCSV(outputfile + "_channel_alignment.csv", channelalignment, "Channel Number,Angle of Rotation, Scale, X offset, Y offset, X component of X translated, Y Component of X translated,X component of Y translated, Y Component of Y translated,X Rotation Point,Y Rotation Point\n");


}