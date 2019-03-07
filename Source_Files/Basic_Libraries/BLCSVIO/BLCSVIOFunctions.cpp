#include "stdafx.h"
#include "BLCSVIO.h"
#include <fstream>
#include <iostream>
#include <sstream>
#include <algorithm>



using namespace std;

template <typename vectortype>
void readincsv(string inputfile, vector<vector<vectortype>>& tableout) {

	ifstream myfile(inputfile.c_str()); //file opening constructor
										//Operation to check if the file opened
	if (myfile.is_open()) {
		string line;

		getline(myfile, line);

		std::string s = line;
		size_t n = std::count(s.begin(), s.end(), ',');
		int numofcolumns = n + 1;


		char c1;  // to eat the commas
		vector<vectortype> dataline(numofcolumns);
		tableout.clear();
		while (getline(myfile, line)) {
			istringstream ss(line);  // note we use istringstream, we don't need the o part of stringstream
			for (int i = 0; i < numofcolumns - 1; i++)ss >> dataline[i] >> c1;
			ss >> dataline[numofcolumns - 1];
			tableout.push_back(dataline);
		}

		myfile.close();


	}
	else {
		cout << "ERROR: The file isnt open.\n";
	}


}



void BLCSVIO::readCSV(string inputfile, vector<vector<double>>& tableout) {
	readincsv(inputfile, tableout);
}
void BLCSVIO::readCSV(string inputfile, vector<vector<float>>& tableout) {
	readincsv(inputfile, tableout);
}
void BLCSVIO::readCSV(string inputfile, vector<vector<int>>& tableout) {
	readincsv(inputfile, tableout);
}
void BLCSVIO::readCSV(string inputfile, vector<vector<long>>& tableout) {
	readincsv(inputfile, tableout);
}
void BLCSVIO::readCSV(string inputfile, vector<vector<uint8_t>>& tableout) {
	readincsv(inputfile, tableout);
}
void BLCSVIO::readCSV(string inputfile, vector<vector<uint16_t>>& tableout) {
	readincsv(inputfile, tableout);
}

template <typename vectortype>
void readincsvvariablewidth(string inputfile, vector<vector<vectortype>>& tableout) {

	ifstream myfile(inputfile.c_str()); //file opening constructor
										//Operation to check if the file opened
	if (myfile.is_open()) {
		string line;

		getline(myfile, line);

		std::string s = line;
		size_t n = std::count(s.begin(), s.end(), ',');
		int numofcolumns = n + 1;


		char c1;  // to eat the commas
		vector<vectortype> dataline(numofcolumns);
		tableout.clear();
		while (getline(myfile, line)) {
			s = line;
			n = std::count(s.begin(), s.end(), ',');
			numofcolumns = n + 1;
			dataline.resize(numofcolumns);
			istringstream ss(line);  // note we use istringstream, we don't need the o part of stringstream
			for (int i = 0; i < numofcolumns - 1; i++)ss >> dataline[i] >> c1;
			ss >> dataline[numofcolumns - 1];
			tableout.push_back(dataline);
		}

		myfile.close();


	}
	else {
		cout << "ERROR: The file isnt open.\n";
	}


}

void BLCSVIO::readVariableWidthCSV(string inputfile, vector<vector<double>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

void BLCSVIO::readVariableWidthCSV(std::string inputfile, std::vector<std::vector<float>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

void BLCSVIO::readVariableWidthCSV(string inputfile, vector<vector<int>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

void BLCSVIO::readVariableWidthCSV(string inputfile, vector<vector<long>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

void BLCSVIO::readVariableWidthCSV(string inputfile, vector<vector<uint8_t>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

void BLCSVIO::readVariableWidthCSV(string inputfile, vector<vector<uint16_t>>& tableout) {
	readincsvvariablewidth(inputfile, tableout);
}

template <typename vectortype>
void writeoutcsv(string filename, vector<vector<vectortype>> file_out, string headerline)
{
	std::ofstream myfile;
	myfile.open(filename.c_str());
	myfile << headerline;
	std::string strout;
	for (int count = 0; count < file_out.size(); count++)
	{
		strout = file_out[count].size()>0?std::to_string(file_out[count][0]):"";
		for (int paramc = 1; paramc < file_out[count].size(); paramc++)strout = strout + "," + std::to_string(file_out[count][paramc]);
		strout = strout + "\n";
		//std::cout << strout;
		myfile << strout;
	}
	myfile.close();
}

void BLCSVIO::writeCSV(string filename, vector<vector<double>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<float>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<int>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<long>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<uint8_t>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<uint16_t>> file_out, string headerline) {
	writeoutcsv(filename, file_out, headerline);
}

template <typename vectortype>
void writeoutcsv(string filename, vector<vector<vectortype>> file_out, vector<string> headerline)
{
	std::ofstream myfile;
	myfile.open(filename.c_str());

	string headerout = headerline.size()>0 ? headerline[0] : "";
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

void BLCSVIO::writeCSV(string filename, vector<vector<double>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<float>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<int>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<long>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<uint8_t>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}
void BLCSVIO::writeCSV(string filename, vector<vector<uint16_t>> file_out, vector<string> headerline) {
	writeoutcsv(filename, file_out, headerline);
}