// reading a metadata file
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
using namespace std;


void Read_Micromanager_Metadata(string filename, vector<vector<int>>& stackorder) {
	stackorder.clear();


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

	else cout << "Unable to open file";


	//for (size_t i = 0; i<stackorder.size(); i++) cout << "Total : " << i << " Frame : " << stackorder[i][0] << " Channel : " << stackorder[i][1] << "\n";
}