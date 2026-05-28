#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Picasso_Raw_Converter(std::string outputName, std::string fileIn);

// MATLAB call:
// Picasso_Raw_Converter(outputBase, inputTiff)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 2;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();

        filebaseChar = inputs[1];
        std::string fileIn = filebaseChar.toAscii();

        Picasso_Raw_Converter(filebase, fileIn);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Picasso_Raw_Converter requires 2 inputs.\n"
                    "Usage: Picasso_Raw_Converter(outputBase, inputTiff)") }));
        }

    }
};
