#pragma once
#include <vector>
#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <algorithm>



namespace BLCSVIO {
	template <typename vectortype>
	inline int readCSV(std::string inputfile, std::vector<std::vector<vectortype> >& tableout, std::vector<std::string>& headerLine) {
		//std::vector<std::string>& headerLine = std::vector<std::string>(0)
		std::ifstream myfile(inputfile.c_str()); //file opening constructor
									
		if (myfile.is_open()) {//Operation to check if the file opened
			std::string line;

			getline(myfile, line);

			std::string s = line;
			size_t n = std::count(s.begin(), s.end(), ',');
			int numofcolumns = n + 1;

			headerLine.resize(numofcolumns);
			std::istringstream ss(line);
			for (int i = 0; i < numofcolumns; i++)getline(ss, headerLine[i], ',');

			char c1;  // to eat the commas
			std::vector<vectortype> dataline(numofcolumns);

			tableout.clear();
			while (getline(myfile, line)) {
				std::istringstream ss(line);  // note we use istringstream, we don't need the o part of stringstream
				for (int i = 0; i < numofcolumns - 1; i++)ss >> dataline[i] >> c1;
				ss >> dataline[numofcolumns - 1];
				tableout.push_back(dataline);
			}

			myfile.close();

		}
		else {
			std::invalid_argument("ERROR: Unable to open the file!\n"+inputfile+"\n");
			return 1;
		}
		return 0;
	}


	template <typename vectortype>
	inline int readVariableWidthCSV(std::string inputfile, std::vector<std::vector<vectortype> >& tableout, std::vector<std::string>& headerLine,bool ignoreEmpty = true) {
		//std::vector<std::string>& headerLine = std::vector<std::string>(0)
		std::ifstream myfile(inputfile.c_str()); //file opening constructor
											//Operation to check if the file opened
		if (myfile.is_open()) {
			std::string line;

			getline(myfile, line);

			std::string s = line;
			size_t n = std::count(s.begin(), s.end(), ',');
			int numofcolumns = n + 1;

			headerLine.resize(numofcolumns);
			std::istringstream ss(line);
			for (int i = 0; i < numofcolumns; i++)getline(ss, headerLine[i], ',');


			char c1;  // to eat the commas
			size_t fixpos;
			int streampos;
			std::vector<vectortype> dataline(numofcolumns);
			tableout.clear();
			while (getline(myfile, line)) {
				s = line;
				if (ignoreEmpty) {
					fixpos = s.find("\"\"");
					if (fixpos != 0 && fixpos != std::string::npos)fixpos = s.find(",\"\"");
					while (fixpos != std::string::npos) {
						s.replace(s.begin() + fixpos, s.begin() + fixpos + 3, "");
						fixpos = s.find(",\"\"");
					}
				}


				n = std::count(s.begin(), s.end(), ',');
				numofcolumns = n + 1;
				dataline.clear();
				dataline.resize(numofcolumns);
				//dataline = std::vector<vectortype>(numofcolumns);
				std::stringstream ss(line);  // note we use istringstream, we don't need the o part of stringstream
				for (int i = 0; i < numofcolumns - 1; i++) {
					streampos = ss.tellg();
					ss >> dataline[i] >> c1;
					if (ss.fail()) {
						std::string tofix = ss.str().substr(streampos);
						fixpos = tofix.find(',');
						if (fixpos != std::string::npos) tofix = tofix.substr(fixpos + 1);
						else break;
						std::cout << "WARNING: Invalid value in CSV File! Line : "<<tableout.size()+1<<"\n";
							ss.clear();
						ss = std::stringstream(tofix);
					}
				}
				ss >> dataline[numofcolumns - 1];
				tableout.push_back(dataline);
			}

			myfile.close();


		}
		else {
			std::invalid_argument("ERROR: Unable to open the file!\n" + inputfile + "\n");
			return 1;
		}

		return 0;
	}

	template <typename vectortype>
	inline void writeCSV(std::string filename, std::vector<std::vector<vectortype> > file_out, std::string headerline)
	{
		std::ofstream myfile;
		myfile.open(filename.c_str());
		myfile << headerline;
		std::string strout;
		for (int count = 0; count < file_out.size(); count++)
		{
			strout = file_out[count].size()>0 ? std::to_string(file_out[count][0]) : "";
			for (int paramc = 1; paramc < file_out[count].size(); paramc++)strout = strout + "," + std::to_string(file_out[count][paramc]);
			strout = strout + "\n";
			//std::cout << strout;
			myfile << strout;
		}
		myfile.close();
	}

	template <typename vectortype>
	inline void writeCSV(std::string filename, std::vector< std::vector<vectortype> > file_out, std::vector<std::string> headerline)
	{
		std::ofstream myfile;
		myfile.open(filename.c_str());

		std::string headerout = headerline.size()>0 ? headerline[0] : "";
		for (int paramc = 1; paramc < headerline.size(); paramc++)headerout = headerout + "," + headerline[paramc];
		headerout = headerout + "\n";
		myfile << headerout;
		std::string strout;
		for (int count = 0; count < file_out.size(); count++)
		{
			strout = file_out[count].size()>0 ? std::to_string(file_out[count][0]) : "";
			for (int paramc = 1; paramc < file_out[count].size(); paramc++)strout = strout + "," + std::to_string(file_out[count][paramc]);
			strout = strout + "\n";
			//std::cout << strout;
			myfile << strout;
		}
		myfile.close();
	}


	template <typename vectortype>
	inline void writeCSVVariableOrder(std::string filename, std::vector<std::vector<vectortype> > file_out, std::string headerline, std::vector<int> order)
	{
		std::ofstream myfile;
		myfile.open(filename.c_str());
		myfile << headerline;
		std::string strout;

		for (int i = 0; i < order.size(); i++)
		{
			int count = order[i];
			strout = file_out[count].size() > 0 ? std::to_string(file_out[count][0]) : "";
			for (int paramc = 1; paramc < file_out[count].size(); paramc++)strout = strout + "," + std::to_string(file_out[count][paramc]); 
			strout = strout + "\n";
			//std::cout << strout;
			myfile << strout;
		}
		myfile.close();
	}
}
