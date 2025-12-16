#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned);
//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe, Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 8;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Alignment\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string fileName = filebaseChar.toAscii();
        int startFrame = inputs[1][0];
        int endFrame = inputs[2][0];
        int position = inputs[3][0];
        matlab::data::TypedArray<double> TransformMat = inputs[4];
        matlab::data::ArrayDimensions dims = TransformMat.getDimensions();
        std::vector<std::vector<float>> alignments(dims[0], std::vector<float>(dims[1], 0));
        for (int i = 0;i < dims[0];i++)for (int j = 0;j < dims[1];j++)alignments[i][j] = (float)TransformMat[i][j];
        bool skipIndependentDrifts = inputs[5][0];
        float maxShift = inputs[6][0];
        bool outputAligned = inputs[7][0];

        Align_Channels(filebase, inputFiles, startFrame, endFrame, alignments, skipIndependentDrifts, maxShift, outputAligned);
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