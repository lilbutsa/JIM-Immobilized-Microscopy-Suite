// reading a metadata file
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"

using namespace std;

void getStackOrder(vector<BLTiffIO::TiffInput*>& vis, vector<vector<vector<int>>>& stackorderout) {

	vector<int> maxFrames(1,0);

	for (int i = 0; i < vis.size(); i++) {
		for (int j = 0; j<vis[i]->imageOrder.size(); j++) {
			if (vis[i]->imageOrder[j][1] > maxFrames.size() - 1)maxFrames.resize(vis[i]->imageOrder[j][1] + 1, 0);

			if (maxFrames[vis[i]->imageOrder[j][1]] < vis[i]->imageOrder[j][0])maxFrames[vis[i]->imageOrder[j][1]] = vis[i]->imageOrder[j][0];
		}
	}


	for (int i = 0; i < maxFrames.size(); i++)std::cout << "Channel " << i + 1 << " has " << maxFrames[i]+1 << " Frames\n";

	stackorderout = vector<vector<vector<int>>>(maxFrames.size());

	for (int i = 0; i < maxFrames.size(); i++) stackorderout[i] = vector<vector<int>>(maxFrames[i] + 1, vector<int>(2, -1));

	for (int i = 0; i < vis.size(); i++) {
		for (int j = 0; j < vis[i]->imageOrder.size(); j++) {
			stackorderout[vis[i]->imageOrder[j][1]][vis[i]->imageOrder[j][0]][0] = i;
			stackorderout[vis[i]->imageOrder[j][1]][vis[i]->imageOrder[j][0]][1] = vis[i]->imageOrder[j][3];
		}
	}

}

