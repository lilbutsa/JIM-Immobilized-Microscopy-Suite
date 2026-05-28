#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned, int numOfChannels = 1, bool filesSplitByChannelIn = false, std::string outputBaseString = "");
// MATLAB call:
// Align_Channels(fileName, 'Start', startFrame, 'End', endFrame, 'Position', positionIn,
//                'Alignment', alignmentMatrix, 'SkipIndependentDrifts', logicalValue,
//                'MaxShift', value, 'OutputAligned', logicalValue,
//                'NumberOfChannels', n, 'FilesSplitByChannel', logicalValue, 'Output', outputBase)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 1;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Alignment\n";
        checkArguments(outputs, inputs);
        std::string fileName = parseStringMatlab(inputs, 0);

        std::vector<std::vector<float>> alignments;
        int position = 0, start = 1, end = -1,  numOfChannels = 1;
        std::string outputfile = "";
        bool outputAligned = false, splitByChannel = false, skipIndependentDrifts = false;
        float maxShift = FLT_MAX;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "Start") start = inputs[paramcount + 1][0];
            else if (optionArg == "End")end = inputs[paramcount + 1][0];
            else if (optionArg == "Position")position = inputs[paramcount + 1][0];
            else if (optionArg == "Alignment")parse2DMatlabArray(inputs, paramcount + 1, alignments);
            else if (optionArg == "NumberOfChannels")numOfChannels = inputs[paramcount + 1][0];
            else if (optionArg == "OutputAligned") outputAligned = inputs[paramcount + 1][0];
            else if (optionArg == "FilesSplitByChannel") splitByChannel = inputs[paramcount + 1][0];
            else if (optionArg == "Output")outputfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "MaxShift")maxShift = inputs[paramcount + 1][0];
            else if (optionArg == "SkipIndependentDrifts")skipIndependentDrifts = inputs[paramcount + 1][0];
        }

        Align_Channels(fileName,start, end, position, alignments, skipIndependentDrifts, maxShift, outputAligned, numOfChannels, splitByChannel, outputfile);
        std::cout << "Finished Aligning\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Align_Channels requires at least 1 input.\n"
                    "Usage: Align_Channels(fileName, 'Start', startFrame, 'End', endFrame, 'Position', positionIn, "
                    "'Alignment', alignmentMatrix, 'SkipIndependentDrifts', logicalValue, 'MaxShift', value, "
                    "'OutputAligned', logicalValue, 'NumberOfChannels', n, 'FilesSplitByChannel', logicalValue, 'Output', outputBase)") }));
        }

    }
};
