#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Align_Channels(std::string fileBase, std::vector<std::string>& inputfiles, int startFrame, int endFrame, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, double maxShift, bool outputAligned);
//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 8;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Alignment\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        std::vector<std::string> inputFiles;
        for (int i = 0;i < inputs.size() - minNumOfInputs + 1;i++) {
            filebaseChar = inputs[i + 1];
            inputFiles.push_back(filebaseChar.toAscii());
        }

        int startFrame = inputs[inputs.size() - minNumOfInputs + 2][0];
        int endFrame = inputs[inputs.size() - minNumOfInputs + 3][0];
        matlab::data::TypedArray<double> TransformMat = inputs[inputs.size() - minNumOfInputs + 4];
        matlab::data::ArrayDimensions dims = TransformMat.getDimensions();
        std::vector<std::vector<float>> alignments(dims[0], std::vector<int>(dims[1], 0));
        for (int i = 0;i < dims[0];i++)for (int j = 0;j < dims[1];j++)alignments[i][j] = (float)TransformMat[i][j];
        bool skipIndependentDrifts = inputs[inputs.size() - minNumOfInputs + 5][0];
        double maxShift = inputs[inputs.size() - minNumOfInputs + 6][0];
        bool outputAligned = inputs[inputs.size() - minNumOfInputs + 7][0];

        Align_Channels(fileBase, inputfiles, startFrame, endFrame, alignments, skipIndependentDrifts, maxShift, outputAligned);
        std::cout << "Finished Aligning\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least nine inputs required - Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)") }));
        }

    }
};