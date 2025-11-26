#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Picasso_Raw_Converter(std::string outputName, std::string fileIn);

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 9;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();

        filebaseChar = inputs[1];
        std::string fileIn = filebaseChar.toAscii();

        Picasso_Raw_Converter(filebase, fileIn);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least two inputs required - Standard input :int Picasso_Raw_Converter(std::string outputName, std::string fileIn)") }));
        }

    }
};