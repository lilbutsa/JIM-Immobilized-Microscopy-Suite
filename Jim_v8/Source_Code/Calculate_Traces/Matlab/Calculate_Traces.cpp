#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Calculate_Traces(std::string output, std::string inputfile, std::string ROIfile, std::string backgroundfile, std::string driftfile, bool veboseoutput);


//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 6;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        filebaseChar = inputs[1];
        std::string inputfile = filebaseChar.toAscii();
        filebaseChar = inputs[2];
        std::string ROIfile = filebaseChar.toAscii();
        filebaseChar = inputs[3];
        std::string backgroundfile = filebaseChar.toAscii();
        filebaseChar = inputs[4];
        std::string driftfile = filebaseChar.toAscii();
        bool veboseoutput = inputs[5][0];


        Calculate_Traces(filebase, inputfile, ROIfile, backgroundfile, driftfile, veboseoutput);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least six inputs required - Standard input : Calculate_Traces(std::string output, std::string inputfile, std::string ROIfile, std::string backgroundfile, std::string driftfile, bool veboseoutput)") }));
        }

    }
};