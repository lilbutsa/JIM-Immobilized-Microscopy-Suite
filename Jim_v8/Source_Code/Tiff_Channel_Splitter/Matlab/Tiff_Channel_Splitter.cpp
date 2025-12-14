#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Tiff_Channel_Splitter(std::string inputfile, std::vector<std::vector<int>>& tranformations, bool bmetadata, int numOfChan, bool bAcrossMultifiles);


//Standard input : (std::string inputfile, std::vector<std::vector<int>>& tranformations, bool bmetadata, int numOfChan, bool bAcrossMultifiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 5;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string inputFile = filebaseChar.toAscii();

        std::vector<std::vector<int>> Transform;
        if (inputs.size() >= 2) {
            matlab::data::TypedArray<double> TransformMat = inputs[1];
            matlab::data::ArrayDimensions dims = TransformMat.getDimensions();
            std::vector<std::vector<int>> TransformIn(dims[0], std::vector<int>(dims[1], 0));
            for (int i = 0; i < dims[0]; i++)for (int j = 0; j < dims[1]; j++)TransformIn[i][j] = (int)TransformMat[i][j];
            Transform = TransformIn;
        }

        bool bmetadata = (inputs.size() >= 3 ? inputs[2][0] : true);
        int NumberOfChannels = inputs.size() >= 4 ? inputs[3][0] : 2;
        bool bAcrossMultifiles = false;
        if(inputs.size() >= 5) bAcrossMultifiles =  inputs[4][0];

        Tiff_Channel_Splitter(inputFile,Transform, bmetadata, NumberOfChannels, bAcrossMultifiles);
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("Standard input :int Tiff_Channel_Splitter(std::string inputfile, std::vector<std::vector<int>>& tranformations, bool bmetadata, int numOfChan, bool bAcrossMultifiles);") }));
        }

    }
};