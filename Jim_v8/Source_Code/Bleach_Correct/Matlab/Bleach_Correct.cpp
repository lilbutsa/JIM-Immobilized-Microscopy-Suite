#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Bleach_Correct(std::string fileBase, std::string inputfile, double meanBleachFrame)
//Standard input : ([Output File Base],[Input Traces] ,meanBleachFrame)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 3;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Bleach Correcting\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        filebaseChar = inputs[1];
        std::string inputfile = filebaseChar.toAscii();
        double meanBleachFrame = inputs[2];

        Bleach_Correct(filebase, inputfile, meanBleachFrame)
        std::cout << "Finished Bleach Correcting\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least three inputs required - Standard input : ([Output File Base],[Input Traces] ,meanBleachFrame)") }));
        }

    }
};