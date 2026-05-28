#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLMatlabParser.h"

int Detect_Particles(std::string fileBase, std::string inputfile, double gaussStdDev, double binarizecutoff, double minSeparation, double leftminDistFromEdge, double rightminDistFromEdge, double topminDistFromEdge, double bottomminDistFromEdge,
    double minEccentricity, double maxEccentricity, double minLength, double maxLength, double minCount, double maxCount, double maxDistFromLinear, bool includeSmall);
// MATLAB call:
// Detect_Particles(inputImage, binarizeCutoff, 'GaussianStdDev', value, 'MinSeparation', value,
//                  'MinDistFromEdge', value, 'LeftMinDistFromEdge', value, 'RightMinDistFromEdge', value,
//                  'TopMinDistFromEdge', value, 'BottomMinDistFromEdge', value,
//                  'MinEccentricity', value, 'MaxEccentricity', value, 'MinLength', value, 'MaxLength', value,
//                  'MinCount', value, 'MaxCount', value, 'MaxDistFromLinear', value,
//                  'IncludeSmall', logicalValue, 'Output', outputBase)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 2;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting detection\n";
        checkArguments(outputs, inputs);

        std::string fileName = parseStringMatlab(inputs, 0);
        double binarizecutoff = inputs[1][0];

        std::string outputBase = "";

        double gaussStdDev = 5, minSeparation = 0,leftminDistFromEdge = 0,rightminDistFromEdge = 0,topminDistFromEdge = 0,bottomminDistFromEdge = 0;
        double minEccentricity = -0.1, maxEccentricity = 1.1, minLength = 0, maxLength = 100000000, minCount = 0, maxCount = 100000000, maxDistFromLinear = 100000000;
        bool includeSmall = true;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "IncludeSmall") includeSmall = inputs[paramcount + 1][0];
            else if (optionArg == "Output")outputBase = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "GaussianStdDev")gaussStdDev = inputs[paramcount + 1][0];
            else if (optionArg == "MinSeparation")minSeparation = inputs[paramcount + 1][0];
            else if (optionArg == "MinDistFromEdge") {
                leftminDistFromEdge = inputs[paramcount + 1][0];
                rightminDistFromEdge = inputs[paramcount + 1][0];
                topminDistFromEdge = inputs[paramcount + 1][0];
                bottomminDistFromEdge = inputs[paramcount + 1][0];
            }
            else if (optionArg == "LeftMinDistFromEdge")leftminDistFromEdge = inputs[paramcount + 1][0];
            else if (optionArg == "RightMinDistFromEdge")rightminDistFromEdge = inputs[paramcount + 1][0];
            else if (optionArg == "TopMinDistFromEdge")topminDistFromEdge = inputs[paramcount + 1][0];
            else if (optionArg == "BottomMinDistFromEdge")bottomminDistFromEdge = inputs[paramcount + 1][0];
            else if (optionArg == "MinEccentricity")minEccentricity = inputs[paramcount + 1][0];
            else if (optionArg == "MaxEccentricity")maxEccentricity = inputs[paramcount + 1][0];
            else if (optionArg == "MinLength")minLength = inputs[paramcount + 1][0];
            else if (optionArg == "MaxLength")maxLength = inputs[paramcount + 1][0];
            else if (optionArg == "MinCount")minCount = inputs[paramcount + 1][0];
            else if (optionArg == "MaxCount")maxCount = inputs[paramcount + 1][0];
            else if (optionArg == "MaxDistFromLinear")maxDistFromLinear = inputs[paramcount + 1][0];

        }


        Detect_Particles(outputBase, fileName, gaussStdDev, binarizecutoff, minSeparation, leftminDistFromEdge, rightminDistFromEdge, topminDistFromEdge, bottomminDistFromEdge,
            minEccentricity, maxEccentricity, minLength, maxLength, minCount, maxCount, maxDistFromLinear, includeSmall);
        std::cout << "Finished dectection\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Detect_Particles requires at least 2 inputs.\n"
                    "Usage: Detect_Particles(inputImage, binarizeCutoff, 'Output', outputBase, 'GaussianStdDev', value, "
                    "'MinSeparation', value, 'MinDistFromEdge', value, 'LeftMinDistFromEdge', value, 'RightMinDistFromEdge', value, "
                    "'TopMinDistFromEdge', value, 'BottomMinDistFromEdge', value, 'MinEccentricity', value, 'MaxEccentricity', value, "
                    "'MinLength', value, 'MaxLength', value, 'MinCount', value, 'MaxCount', value, 'MaxDistFromLinear', value, "
                    "'IncludeSmall', logicalValue)") }));
        }

    }
};
