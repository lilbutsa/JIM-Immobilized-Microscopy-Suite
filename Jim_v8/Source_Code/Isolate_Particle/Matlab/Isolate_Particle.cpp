#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Isolate_Particle(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::string measurementsfile, int particle, int start, int end, int delta, int average, bool bOutputImageStack);


//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 11;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        std::vector<std::string> inputFiles;
        for (int i = 0;i < inputs.size() - minNumOfInputs + 1;i++) {
            filebaseChar = inputs[i + 1];
            inputFiles.push_back(filebaseChar.toAscii());
        }
        filebaseChar = inputs[inputs.size() - minNumOfInputs + 2];
        std::string driftfile = filebaseChar.toAscii();
        filebaseChar = inputs[inputs.size() - minNumOfInputs + 3];
        std::string alignfile = filebaseChar.toAscii();
        filebaseChar = inputs[inputs.size() - minNumOfInputs + 4];
        std::string measurementsfile = filebaseChar.toAscii();


        int particle = inputs[inputs.size() - minNumOfInputs + 5][0];
        int startFrame = inputs[inputs.size() - minNumOfInputs + 6][0];
        int endFrame = inputs[inputs.size() - minNumOfInputs + 7][0];
        int delta = inputs[inputs.size() - minNumOfInputs + 8][0];
        int average = inputs[inputs.size() - minNumOfInputs + 9][0];
        bool bOutputImageStack = inputs[inputs.size() - minNumOfInputs + 10][0];

        Isolate_Particle(filebase, inputFiles, driftfile, alignfile, measurementsfile, particle, startFrame, endFrame, delta, average, bOutputImageStack);

        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least 11 inputs required - Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)") }));
        }

    }
};