#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include "BLMatlabParser.h"

int Step_Fitting(std::string inputfile, double TThreshold = 1.96, int method = 0, int maxSteps = -1, std::string output = "");

// MATLAB call:
// Step_Fitting(inputfile, 'TThreshold', value, 'MaxSteps', value, 'Output', outputBase,
//              'Aggarwal' | 'TTest' | 'AutoStepFit' | 'ChangePoint')
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 1;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        std::string fileName = parseStringMatlab(inputs, 0);

        double TThreshold = 1.96;
        int method = 0, maxSteps = -1;
        std::string outputfile = "";
        
        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size(); paramcount++) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "TThreshold" && paramcount + 1 < inputs.size()) {
                TThreshold = inputs[paramcount + 1][0];
                paramcount++;
            }
            else if (optionArg == "MaxSteps" && paramcount + 1 < inputs.size()) {
                maxSteps = inputs[paramcount + 1][0];
                paramcount++;
            }
            else if (optionArg == "Output" && paramcount + 1 < inputs.size()) {
                outputfile = parseStringMatlab(inputs, paramcount + 1);
                paramcount++;
            }
            else if (optionArg == "Aggarwal")method = 0;
            else if (optionArg == "TTest")method = 1;
            else if (optionArg == "AutoStepFit")method = 2;
            else if (optionArg == "ChangePoint")method = 3;
        }

        Step_Fitting(fileName, TThreshold, method, maxSteps, outputfile);
        std::cout << "Finishing Program\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(
                    "Step_Fitting requires at least 1 input.\n"
                    "Usage: Step_Fitting(inputfile, 'TThreshold', value, 'MaxSteps', value, 'Output', outputBase, "
                    "'Aggarwal' | 'TTest' | 'AutoStepFit' | 'ChangePoint')") }));
        }

    }
};
