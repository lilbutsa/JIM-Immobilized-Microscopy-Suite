#pragma once
#include <vector>
#include <string>

namespace BLCSVIO {
	void readCSV(std::string inputfile, std::vector<std::vector<double>>& tableout);
	void readCSV(std::string inputfile, std::vector<std::vector<float>>& tableout);
	void readCSV(std::string inputfile, std::vector<std::vector<int>>& tableout);
	void readCSV(std::string inputfile, std::vector<std::vector<long>>& tableout);
	void readCSV(std::string inputfile, std::vector<std::vector<uint8_t>>& tableout);
	void readCSV(std::string inputfile, std::vector<std::vector<uint16_t>>& tableout);

	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<double>>& tableout);
	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<float>>& tableout);
	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<int>>& tableout);
	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<long>>& tableout);
	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<uint8_t>>& tableout);
	void readVariableWidthCSV(std::string inputfile, std::vector<std::vector<uint16_t>>& tableout);

	

	void writeCSV(std::string filename, std::vector<std::vector<double>> file_out, std::string headerline);
	void writeCSV(std::string filename, std::vector<std::vector<float>> file_out, std::string headerline);
	void writeCSV(std::string filename, std::vector<std::vector<int>> file_out, std::string headerline);
	void writeCSV(std::string filename, std::vector<std::vector<long>> file_out, std::string headerline);
	void writeCSV(std::string filename, std::vector<std::vector<uint8_t>> file_out, std::string headerline);
	void writeCSV(std::string filename, std::vector<std::vector<uint16_t>> file_out, std::string headerline);

	void writeCSV(std::string filename, std::vector<std::vector<double>> file_out, std::vector<std::string> headerline);
	void writeCSV(std::string filename, std::vector<std::vector<float>> file_out, std::vector<std::string> headerline);
	void writeCSV(std::string filename, std::vector<std::vector<int>> file_out, std::vector<std::string> headerline);
	void writeCSV(std::string filename, std::vector<std::vector<long>> file_out, std::vector<std::string> headerline);
	void writeCSV(std::string filename, std::vector<std::vector<uint8_t>> file_out, std::vector<std::string> headerline);
	void writeCSV(std::string filename, std::vector<std::vector<uint16_t>> file_out, std::vector<std::string> headerline);
}