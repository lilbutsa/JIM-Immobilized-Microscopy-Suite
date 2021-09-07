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


//column search
template< class T >
struct ColumnAdapter {
	ColumnAdapter(size_t column) : m_column(column) {}
	bool operator()(const std::vector< T >& left, const std::vector< T >& right) {
		return left.at(m_column) < right.at(m_column);
	}
private:
	size_t m_column;
};

void Read_Micromanager_Metadata(string filename, vector<vector<int>>& stackorderout) {
	vector<vector<int>> stackorder;


	vector<int> slicecoords(2, 0);
	string line, lineval;
	size_t colonpos, commapos;
	ifstream myfile(filename);
	if (myfile.is_open())
	{
		while (getline(myfile, line))
		{
			if (line.find("completeCoords") != std::string::npos) {
				for (int i = 0; i < 4; i++) {
					getline(myfile, line);
					colonpos = line.find(":") + 2;
					commapos = line.find(",");
					lineval = line.substr(colonpos, commapos - colonpos);
					//cout << line << "\n";
					if (line.find("time") != std::string::npos)slicecoords[0] = stoi(lineval);
					else if (line.find("channel") != std::string::npos)slicecoords[1] = stoi(lineval);
				}
				stackorder.push_back(slicecoords);
			}

		}
		myfile.close();
	}

	else {
		cout << "Unable to open file";
		return;
	}

	cout << "Total number of images = " << stackorder.size() << "\n";
	for (size_t i = 0; i<stackorder.size(); i++) cout << "Total : " << i << " Frame : " << stackorder[i][0] << " Channel : " << stackorder[i][1] << "\n";

	int totchannelnum = (*max_element(stackorder.begin(), stackorder.end(), ColumnAdapter< int >(1)))[1] + 1;
	int totnumofframes = stackorder.size();
	int framesperchannel = totnumofframes / totchannelnum;

	stackorderout = vector<vector<int>>(3, vector<int>(framesperchannel,-1));

	for (int i = 0; i < totnumofframes; i++) {
		stackorderout[stackorder[i][1]][stackorder[i][0]] = i;
	}


}
