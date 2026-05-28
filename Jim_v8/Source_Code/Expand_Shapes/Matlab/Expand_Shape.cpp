#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Expand_Shapes(std::string foregroundposfile, std::string backgroundposfile, std::string extraBackgroundFileName, float boundaryDist, float backinnerradius, float backgroundDist, std::string output );

// MATLAB call:
// Expand_Shapes(foregroundPositionsFile, backgroundPositionsFile,
//               'BoundaryDist', value, 'BackInnerRadius', value, 'BackgroundDist', value,
//               'ExtraBackgroundFile', extraBackgroundFile, 'Output', outputBase)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 2;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Expanding Shapes\n";
        checkArguments(outputs, inputs);
        std::string foregroundposfile = parseStringMatlab(inputs, 0);
        std::string backgroundposfile = parseStringMatlab(inputs, 1);
        std::string extraBackgroundFileName = "",outputFile = "";
        float boundaryDist = 4.1, backinnerradius = 7.1, backgroundDist = 30;
        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "BoundaryDist") boundaryDist = inputs[paramcount + 1][0];
            else if (optionArg == "BackInnerRadius")backinnerradius = inputs[paramcount + 1][0];
            else if (optionArg == "BackgroundDist")backgroundDist = inputs[paramcount + 1][0];
            else if (optionArg == "ExtraBackgroundFile")extraBackgroundFileName = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Output")outputFile = parseStringMatlab(inputs, paramcount + 1);
        }

        Expand_Shapes( foregroundposfile, backgroundposfile, extraBackgroundFileName, boundaryDist, backinnerradius, backgroundDist, outputFile);

        std::cout << "Finished Expanding Shapes\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Expand_Shapes requires at least 2 inputs.\n"
                    "Usage: Expand_Shapes(foregroundPositionsFile, backgroundPositionsFile, "
                    "'BoundaryDist', value, 'BackInnerRadius', value, 'BackgroundDist', value, "
                    "'ExtraBackgroundFile', extraBackgroundFile, 'Output', outputBase)") }));
        }

    }
};
