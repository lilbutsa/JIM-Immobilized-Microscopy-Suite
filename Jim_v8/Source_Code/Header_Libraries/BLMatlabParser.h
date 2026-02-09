#ifndef BLFLAGPARSER_HPP
#define BLFLAGPARSER_HPP

#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>


template <typename outputType>
inline void parse1DMatlabArray(matlab::mex::ArgumentList input,size_t pos, std::vector<outputType>& output) {
    matlab::data::ArrayDimensions dims = input[pos].getDimensions();
    output.resize(dims[0] * dims[1]);
    for (size_t i = 0; i < dims[0]; i++)for (size_t j = 0; j < dims[1]; j++) output[i + dims[0] * j] = (outputType)input[pos][i][j];
};

template <typename outputType>
inline void parse2DMatlabArray(matlab::mex::ArgumentList input,size_t pos, std::vector<std::vector<outputType>>& output) {
    matlab::data::ArrayDimensions dims = input[pos].getDimensions();
    output.resize(dims[0]);
    for (size_t i = 0; i < dims[0]; i++) {
        output[i].resize(dims[1]);
        for (size_t j = 0; j < dims[1]; j++) output[i][j] = (outputType)input[pos][i][j];
    }
};

inline std::string parseStringMatlab(matlab::mex::ArgumentList input, size_t pos) {
    matlab::data::CharArray filebaseChar = input[pos];
    std::string output = filebaseChar.toAscii();
    return output;
};


#endif // BLFLAGPARSER_HPP