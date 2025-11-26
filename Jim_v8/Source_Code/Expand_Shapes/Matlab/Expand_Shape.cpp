#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Expand_Shapes(std::string output, std::string foregroundposfile, std::string backgroundposfile, std::string extraBackgroundFileName, std::string channelAlignmentFileName, float boundaryDist, float backinnerradius, float backgroundDist);

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 8;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Expanding Shapes\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        filebaseChar = inputs[1];
        std::string foregroundposfile = filebaseChar.toAscii();
        filebaseChar = inputs[2];
        std::string backgroundposfile = filebaseChar.toAscii();
        filebaseChar = inputs[3];
        std::string extraBackgroundFileName = filebaseChar.toAscii();
        filebaseChar = inputs[4];
        std::string channelAlignmentFileName = filebaseChar.toAscii();
        float boundaryDist = inputs[5][0];
        float backinnerradius = inputs[6][0];
        float backgroundDist = inputs[7][0];

        Expand_Shapes(filebase, foregroundposfile, backgroundposfile, extraBackgroundFileName, channelAlignmentFileName, boundaryDist, backinnerradius, backgroundDist);

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