#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>

using namespace std;

void numberimage(std::vector< std::vector<float> >& filteredcents, std::vector<uint8_t>& fn, int iw,int ih) {
	for (int i = 0; i < filteredcents.size(); i++) {
		int xc = round(filteredcents[i][0]);
		int y0 = round(filteredcents[i][1]) - 2;

		if (y0 < 0)y0 = 0;
		if (y0 > ih - 6)y0 = ih - 6;

		int numofdigits = ceil(log10(i + 2));

		if (xc - 2 * numofdigits + 1 < 0)xc = 2 * numofdigits - 1;
		if (xc + 2 * (numofdigits - 1) + 4 > iw)xc = iw - 2 * (numofdigits - 1) - 4;


		for (int j = 0; j < numofdigits; j++) {
			int x0 = xc + 4 * j - 2 * numofdigits + 1;
			int digitval = ((int)((i + 1) / pow(10, (numofdigits-1-j))) % 10);
			if (digitval == 0) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255;									fn[(x0 + 2) + iw*(y0 + 2)] = 255;
				fn[(x0 + 0) + iw*(y0 + 3)] = 255;									fn[(x0 + 2) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 1) {
				fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 1)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 3)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 2) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
				fn[(x0 + 0) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 3) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 4) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255;									fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 3)] = 255;
																					 fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 5) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 6) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
				fn[(x0 + 0) + iw*(y0 + 3)] = 255;									fn[(x0 + 2) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 7) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 1)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 2)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 3)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 8) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
				fn[(x0 + 0) + iw*(y0 + 3)] = 255;									fn[(x0 + 2) + iw*(y0 + 3)] = 255;
				fn[(x0 + 0) + iw*(y0 + 4)] = 255; fn[(x0 + 1) + iw*(y0 + 4)] = 255; fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
			else if (digitval == 9) {
				fn[(x0 + 0) + iw*(y0 + 0)] = 255; fn[(x0 + 1) + iw*(y0 + 0)] = 255; fn[(x0 + 2) + iw*(y0 + 0)] = 255;
				fn[(x0 + 0) + iw*(y0 + 1)] = 255;									fn[(x0 + 2) + iw*(y0 + 1)] = 255;
				fn[(x0 + 0) + iw*(y0 + 2)] = 255; fn[(x0 + 1) + iw*(y0 + 2)] = 255; fn[(x0 + 2) + iw*(y0 + 2)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 3)] = 255;
																					fn[(x0 + 2) + iw*(y0 + 4)] = 255;
			}
		}


	}


}