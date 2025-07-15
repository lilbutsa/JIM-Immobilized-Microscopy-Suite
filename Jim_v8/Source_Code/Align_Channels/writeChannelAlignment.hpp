#pragma once
#ifndef WRITESTUFF_H_
#define WRITESTUFF_H_

/**
 * @file writeChannelAlignment.hpp
 * @brief Utilities for writing alignment and drift correction results to CSV files.
 *
 * Contains inline functions for outputting computed inter-channel alignment parameters
 * and per-frame drift corrections. The outputs are written in CSV format using BLCSVIO.
 *
 * Functions:
 * - writeChannelAlignment:
 *     Outputs channel-to-channel alignment parameters including rotation angle,
 *     scale, translation offsets, and the transformation matrix components.
 *     Saves results as "[OutputFile]_Channel_To_Channel_Alignment.csv".
 *
 * - writeDrifts:
 *     Outputs frame-by-frame X and Y drift values for each channel. Transforms
 *     drift vectors for non-reference channels using the channel alignment matrix.
 *     Saves each channel's drift data as "[OutputFile]_Channel_X.csv".
 *
 * Output CSV columns:
 * - writeChannelAlignment:
 *     Channel Number, Angle of Rotation, Scale, X offset, Y offset,
 *     X/Y components of translation matrix, and rotation point (image center).
 * - writeDrifts:
 *     X Drift, Y Drift per frame, transformed into each channel's reference frame.
 *
 * Dependencies:
 *   - BLCSVIO (for CSV writing)
 *
 * Author: James Walsh
 * Date: July 2020
 */


#include "BLCSVIO.h"


inline void writeChannelAlignment(std::string outputfile, std::vector< std::vector< float>>& alignments,int imageWidth, int imageHeight) {

	int numchan = alignments.size();

	std::vector< std::vector<float> > channelalignment(numchan, std::vector<float>(11, 0.0));

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

inline void writeDrifts(std::string outputfile, const std::vector< std::vector< float>>driftsout, const std::vector< std::vector< float>>& alignment, int imageWidth, int imageHeight) {

	std::string myFileName = outputfile + "_Channel_1.csv";
	BLCSVIO::writeCSV(myFileName, driftsout, "X Drift, Y Drift\n");

	for (int chancount = 0; chancount < alignment.size(); chancount++) {
		float x1 = cos(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
		float y1 = -sin(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
		float x2 = sin(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
		float y2 = cos(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
		//std::cout << "transform = " << chancount << " " << x1 << " " <<y1 << " " << x2 << " " << y2 << "\n";

		std::vector<std::vector<float>> transformedDrifts = driftsout;
		for (int pos = 0; pos < transformedDrifts.size(); pos++) {
			float xin = transformedDrifts[pos][0];
			float yin = transformedDrifts[pos][1];

			transformedDrifts[pos][0] = xin * x1 + yin * y1;
			transformedDrifts[pos][1] = xin * x2 + yin * y2;

		}

		myFileName = outputfile + "_Channel_" + std::to_string(chancount + 2) + ".csv";
		BLCSVIO::writeCSV(myFileName, transformedDrifts, "X Drift, Y Drift\n");
	}

}

#endif