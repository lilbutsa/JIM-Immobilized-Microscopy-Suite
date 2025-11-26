#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Mean_of_Frames(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::vector<int> start, std::vector<int> end, bool bPercent, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize);

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 10;
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

        matlab::data::TypedArray<double> TransformMat = inputs[inputs.size() - minNumOfInputs + 5];
        matlab::data::ArrayDimensions dims = TransformMat.getDimensions();
        std::vector<int> start(dims[0], 0);
        for (int i = 0;i < dims[0];i++)start[i]= (int)TransformMat[i][0];

        TransformMat = inputs[inputs.size() - minNumOfInputs + 6];
        dims = TransformMat.getDimensions();
        std::vector<int> end(dims[0], 0);
        for (int i = 0;i < dims[0];i++)end[i] = (int)TransformMat[i][0];

        bool bPercent = inputs[inputs.size() - minNumOfInputs + 7][0];

        TransformMat = inputs[inputs.size() - minNumOfInputs + 8];
        dims = TransformMat.getDimensions();
        std::vector<int> bvMaxProject(dims[0], 0);
        for (int i = 0;i < dims[0];i++)bvMaxProject[i] = (int)TransformMat[i][0];


        TransformMat = inputs[inputs.size() - minNumOfInputs + 9];
        dims = TransformMat.getDimensions();
        std::vector<float> weights(dims[0], 0);
        for (int i = 0;i < dims[0];i++)weights[i] = (float)TransformMat[i][0];

        bool bNormalize = inputs[inputs.size() - minNumOfInputs + 10][0];


        Mean_of_Frames(filebase, inputFiles, driftfile, alignfile, start, end, bPercent, bvMaxProject, weights, bNormalize);

        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least nine inputs required - int Mean_of_Frames(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::vector<int> start, std::vector<int> end, bool bPercent, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize)") }));
        }

    }
};