#include <vector>
#include <algorithm>
#include <stdint.h>

using namespace std;

void vertFlipImage(std::vector< std::vector<uint16_t>>& imageio) {

	vector<vector<uint16_t>> imageout(imageio.size(),vector<uint16_t>(imageio[0].size(), (uint16_t)0));
	size_t imageHeight = imageio[0].size();

	for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[i][imageHeight - j - 1] = imageio[i][j];
	imageio = imageout;

}

void horzFlipImage(std::vector< std::vector<uint16_t>>& imageio) {

	vector<vector<uint16_t>> imageout(imageio.size(), vector<uint16_t>(imageio[0].size(), (uint16_t)0));
	size_t imageWidth = imageio.size();

	for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageWidth-1-i][j] = imageio[i][j];
	imageio = imageout;

}

void rotateImage(std::vector< std::vector<uint16_t>>& imageio,int angle) {
	size_t imageWidth = imageio.size();
	size_t imageHeight = imageio[0].size();

	if (angle == 180) {
		vector<vector<uint16_t>> imageout(imageio.size(), vector<uint16_t>(imageio[0].size(), (uint16_t)0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageWidth - 1 - i][imageHeight - 1 - j] = imageio[i][j];
		imageio = imageout;
	}
	else if (angle == 90) {
		vector<vector<uint16_t>> imageout(imageio[0].size(), vector<uint16_t>(imageio.size(), (uint16_t)0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageHeight - 1 - j][i] = imageio[i][j];
		imageio = imageout;
	}
	else if (angle == 270) {
		vector<vector<uint16_t>> imageout(imageio[0].size(), vector<uint16_t>(imageio.size(), (uint16_t)0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[j][imageWidth - 1 - i] = imageio[i][j];
		imageio = imageout;
	}

}