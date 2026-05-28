#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLMatlabParser.h"



int Mean_of_Frames(std::string fileName, size_t positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize, std::string driftfile = "", std::string alignfile = "", std::string outputFileName = "Image_For_Detection_Partial_Mean");

// MATLAB call:
// Mean_of_Frames(fileName, 'Position', positionIn, 'Start', startFrames, 'End', endFrames,
//                'MaxProjection', maxProjectionFlags, 'Weights', weights, 'NoNorm', logicalFlag,
//                'Drift', driftFile, 'Alignment', alignmentFile, 'Output', outputBase)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 1;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        //std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);

        std::string fileName = parseStringMatlab(inputs,0);

        int positionIn = 0;
        bool bNormalize = true;
        std::string driftfile = "", alignfile = "",outputfile = "";
        std::vector<int> start, end, bvMaxProject;
        std::vector<float>  weights;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "NoNorm") bNormalize = ((bool)inputs[paramcount + 1][0]==false);
            else if (optionArg == "Drift")driftfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Output")outputfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Start")parse1DMatlabArray(inputs, paramcount + 1, start);
            else if (optionArg == "End")parse1DMatlabArray(inputs, paramcount + 1, end);
            else if (optionArg == "MaxProjection")parse1DMatlabArray(inputs, paramcount + 1, bvMaxProject);
            else if (optionArg == "Weights")parse1DMatlabArray(inputs, paramcount + 1, weights);
            else if (optionArg == "Alignment")alignfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Position")positionIn = inputs[paramcount + 1][0];
        }

        Mean_of_Frames(fileName, positionIn, start, end, bvMaxProject, weights, bNormalize, driftfile, alignfile, outputfile);

    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        std::string errormsg =
            "Mean_of_Frames requires at least 1 input.\n"
            "Usage: Mean_of_Frames(fileName, 'Position', positionIn, 'Start', startFrames, 'End', endFrames, "
            "'MaxProjection', maxProjectionFlags, 'Weights', weights, 'NoNorm', logicalFlag, "
            "'Drift', driftFile, 'Alignment', alignmentFile, 'Output', outputBase)\n"
            "Option details:\n"
            "- Position: scalar position index (default 0)\n"
            "- Start/End: integer arrays, one value per channel\n"
            "- MaxProjection: integer array, one value per channel (0 = mean/sum, non-zero = max)\n"
            "- Weights: numeric array, one value per channel\n"
            "- NoNorm: logical scalar where true disables normalization\n";

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(errormsg) }));
        }

    }
};
