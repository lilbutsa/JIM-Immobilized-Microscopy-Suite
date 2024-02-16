#include <vector>
#include <algorithm>

using namespace std;

void vertFlipImage(std::vector< std::vector<float>>& imageio) {

	vector<vector<float>> imageout(imageio.size(),vector<float>(imageio[0].size(),0.0));
	uint32_t imageHeight = imageio[0].size();

	for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[i][imageHeight - j - 1] = imageio[i][j];
	imageio = imageout;

}

void horzFlipImage(std::vector< std::vector<float>>& imageio) {

	vector<vector<float>> imageout(imageio.size(), vector<float>(imageio[0].size(), 0.0));
	uint32_t imageWidth = imageio.size();

	for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageWidth-1-i][j] = imageio[i][j];
	imageio = imageout;

}

void rotateImage(std::vector< std::vector<float>>& imageio,int angle) {
	uint32_t imageWidth = imageio.size();
	uint32_t imageHeight = imageio[0].size();

	if (angle == 180) {
		vector<vector<float>> imageout(imageio.size(), vector<float>(imageio[0].size(), 0.0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageWidth - 1 - i][imageHeight - 1 - j] = imageio[i][j];
		imageio = imageout;
	}
	else if (angle == 90) {
		vector<vector<float>> imageout(imageio[0].size(), vector<float>(imageio.size(), 0.0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[imageHeight - 1 - j][i] = imageio[i][j];
		imageio = imageout;
	}
	else if (angle == 270) {
		vector<vector<float>> imageout(imageio[0].size(), vector<float>(imageio.size(), 0.0));
		for (int i = 0; i < imageio.size(); i++)for (int j = 0; j < imageio[0].size(); j++)imageout[j][imageWidth - 1 - i] = imageio[i][j];
		imageio = imageout;
	}

}