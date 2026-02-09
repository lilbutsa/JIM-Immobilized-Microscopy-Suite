#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Expand_Shapes(std::string output, std::string foregroundposfile, std::string backgroundposfile, std::string extraBackgroundFileName, std::string channelAlignmentFileName, float boundaryDist, float backinnerradius, float backgroundDist);

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 2;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Expanding Shapes\n";
        checkArguments(outputs, inputs);
        std::string foregroundposfile = parseStringMatlab(inputs, 0);
        std::string backgroundposfile = parseStringMatlab(inputs, 1);
        std::string extraBackgroundFileName = "", channelAlignmentFileName = "",fileBase = "";
        float boundaryDist = 4.1, backinnerradius = 7.1, backgroundDist = 30;
        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "BoundaryDist") boundaryDist = inputs[paramcount + 1][0];
            else if (optionArg == "BackInnerRadius")backinnerradius = inputs[paramcount + 1][0];
            else if (optionArg == "BackgroundDist")backgroundDist = inputs[paramcount + 1][0];
            else if (optionArg == "ExtraBackgroundFile")extraBackgroundFileName = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "AlignFile")channelAlignmentFileName = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "OutputFile")fileBase = parseStringMatlab(inputs, paramcount + 1);
        }

        Expand_Shapes(fileBase, foregroundposfile, backgroundposfile, extraBackgroundFileName, channelAlignmentFileName, boundaryDist, backinnerradius, backgroundDist);

        std::cout << "Finished Expanding Shapes\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least 8 inputs required - Standard input :Expand_Shapes(std::string output, std::string foregroundposfile, std::string backgroundposfile, std::string extraBackgroundFileName, std::string channelAlignmentFileName, float boundaryDist, float backinnerradius, float backgroundDist)") }));
        }

    }
};