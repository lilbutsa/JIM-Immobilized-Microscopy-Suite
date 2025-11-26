#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Step_Fitting(std::string output, std::string inputfile, double TThreshold, int maxSteps, int method);

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 5;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        filebaseChar = inputs[1];
        std::string inputfile = filebaseChar.toAscii();

        double TThreshold = inputs[2][0];

        int maxSteps = inputs[3][0];
        int method = inputs[4][0];

        Step_Fitting(filebase, inputfile, TThreshold, maxSteps, method);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least 5 inputs required - Standard input :int Step_Fitting(std::string output, std::string inputfile,double TThreshold, int maxSteps, int method) ") }));
        }

    }
};