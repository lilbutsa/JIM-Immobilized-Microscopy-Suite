#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned, int numOfChannels = 1, bool filesSplitByChannelIn = false);
//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe, Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 8;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Alignment\n";
        checkArguments(outputs, inputs);

        std::vector<std::vector<float>> alignments;
        std::string fileName = parseStringMatlab(inputs, 0);
        int startFrame = inputs[1][0];
        int endFrame = inputs[2][0];
        int position = inputs[3][0];
        parse2DMatlabArray(inputs, 4, alignments);
        bool skipIndependentDrifts = inputs[5][0];
        float maxShift = inputs[6][0];
        bool outputAligned = inputs[7][0];
        int numberOfChannels = 1;
        if(inputs.size()>8)numberOfChannels = inputs[8][0];
        bool filesSplitByChannelIn = false;
        if (inputs.size() > 9)numberOfChannels = inputs[9][0];

        Align_Channels(fileName,startFrame, endFrame, position, alignments, skipIndependentDrifts, maxShift, outputAligned, numberOfChannels, filesSplitByChannelIn);
        std::cout << "Finished Aligning\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least 8 inputs required -Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned)") }));
        }

    }
};