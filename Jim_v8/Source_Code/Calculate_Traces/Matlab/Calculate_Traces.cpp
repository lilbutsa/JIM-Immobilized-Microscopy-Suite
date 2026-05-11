#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Calculate_Traces(std::string fileName, size_t positionIn, size_t channelIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, bool veboseoutput = false, std::string driftfile = "", int numOfChannels = 1, bool filesSplitByChannelIn = false);



//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 7;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        std::string filebase = parseStringMatlab(inputs, 0);
        int positionIn = inputs[1][0];
        int channelIn = inputs[2][0];
        std::string foregroundposFile = parseStringMatlab(inputs, 3);
        std::string backgroundposfile = parseStringMatlab(inputs, 4);
        int startFrame = inputs[5][0];
        int endFrame = inputs[6][0];

        std::string driftfile = "";
        bool verbose = false;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "Verbose") verbose = inputs[paramcount + 1][0];
            else if (optionArg == "Drift")driftfile = parseStringMatlab(inputs, paramcount + 1); 
        }

        Calculate_Traces(filebase, (size_t) positionIn, (size_t) channelIn, foregroundposFile, backgroundposfile,startFrame,endFrame, verbose, driftfile);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least six inputs required - Standard input : Calculate_Traces(std::string output, std::string inputfile, std::string ROIfile, std::string backgroundfile, int startFrame, int endFrame)") }));
        }

    }
};