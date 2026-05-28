#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Calculate_Traces(std::string fileName, size_t positionIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, std::string driftfile = "", std::string alignfile = "", std::string outputFileBase = "", int numOfChannels = 1, bool filesSplitByChannelIn = false);

// MATLAB call:
// Calculate_Traces(fileName, positionIn, ROIfile, backgroundfile,
//                  'Start', startFrame, 'End', endFrame, 'Drift', driftFile,
//                  'Alignment', alignmentFile, 'NumberOfChannels', n,
//                  'FilesSplitByChannel', logicalValue, 'Output', outputBase)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 4;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        checkArguments(outputs, inputs);
        std::string filebase = parseStringMatlab(inputs, 0);
        size_t positionIn = inputs[1][0];
        std::string foregroundposFile = parseStringMatlab(inputs, 2);
        std::string backgroundposfile = parseStringMatlab(inputs, 3);


        int start = 1, end = -1, numOfChannels = 1;
        std::string outputfile = "", driftfile = "", alignfile = "";
        bool splitByChannel = false;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "Start") start = inputs[paramcount + 1][0];
            else if (optionArg == "End")end = inputs[paramcount + 1][0];
            else if (optionArg == "NumberOfChannels")numOfChannels = inputs[paramcount + 1][0];
            else if (optionArg == "Drift")driftfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Alignment")alignfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Output")outputfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "FilesSplitByChannel") splitByChannel = inputs[paramcount + 1][0];
        }

        Calculate_Traces(filebase, positionIn, foregroundposFile, backgroundposfile, start, end, driftfile, alignfile, outputfile, numOfChannels, splitByChannel);

    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Calculate_Traces requires at least 4 inputs.\n"
                    "Usage: Calculate_Traces(fileName, positionIn, ROIfile, backgroundfile, "
                    "'Start', startFrame, 'End', endFrame, 'Drift', driftFile, 'Alignment', alignmentFile, "
                    "'NumberOfChannels', n, 'FilesSplitByChannel', logicalValue, 'Output', outputBase)") }));
        }

    }
};
