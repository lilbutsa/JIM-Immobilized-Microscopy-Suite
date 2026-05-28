#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Isolate_Particle(std::string fileName, size_t positionIn, size_t particle, int startFrame = 1, int endFrame = -1, size_t numMontageImages = 10, bool bOutputImageStack = false, size_t numOfChannels = 1, bool filesSplitByChannelIn = false, std::string driftfile = "", std::string alignfile = "", std::string measurementsfile = "", std::string outputfile = "");

// MATLAB call:
// Isolate_Particle(fileName, positionIn, particle,
//                  'Start', startFrame, 'End', endFrame, 'MontageImages', n,
//                  'OutputImageStack', logicalValue, 'NumberOfChannels', n,
//                  'FilesSplitByChannel', logicalValue, 'Drift', driftFile,
//                  'Alignment', alignmentFile, 'Measurement', measurementFile, 'Output', outputBase)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 3;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        std::string fileName = parseStringMatlab(inputs, 0);
        int position = inputs[1][0];
        int particle = inputs[2][0];

        int start = 1, end = -1, montageImages = 10, numOfChannels = 1;
        std::string outputfile = "", driftfile = "", alignfile = "", measurementsfile = "";
        bool bOutputImageStack = false, splitByChannel = false;

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "Start") start = inputs[paramcount + 1][0];
            else if (optionArg == "End")end = inputs[paramcount + 1][0];
            else if (optionArg == "MontageImages")montageImages = inputs[paramcount + 1][0];
            else if (optionArg == "NumberOfChannels")numOfChannels = inputs[paramcount + 1][0];
            else if (optionArg == "OutputImageStack") bOutputImageStack = inputs[paramcount + 1][0];
            else if (optionArg == "FilesSplitByChannel") splitByChannel = inputs[paramcount + 1][0];
            else if (optionArg == "Drift")driftfile = parseStringMatlab(inputs, paramcount+1);
            else if (optionArg == "Alignment")alignfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Measurement")measurementsfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "Output")outputfile = parseStringMatlab(inputs, paramcount + 1);

        }

        Isolate_Particle(fileName, position, particle, start, end, montageImages, bOutputImageStack, numOfChannels, splitByChannel, driftfile, alignfile, measurementsfile, outputfile);

        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Isolate_Particle requires at least 3 inputs.\n"
                    "Usage: Isolate_Particle(fileName, positionIn, particle, "
                    "'Start', startFrame, 'End', endFrame, 'MontageImages', n, 'OutputImageStack', logicalValue, "
                    "'NumberOfChannels', n, 'FilesSplitByChannel', logicalValue, 'Drift', driftFile, "
                    "'Alignment', alignmentFile, 'Measurement', measurementFile, 'Output', outputBase)") }));
        }

    }
};
