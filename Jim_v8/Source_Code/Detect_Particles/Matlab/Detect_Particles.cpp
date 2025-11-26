#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>

int Detect_Particles(std::string fileBase, std::string inputfile, double gaussStdDev, double binarizecutoff, double minSeparation, double leftminDistFromEdge, double rightminDistFromEdge, double topminDistFromEdge, double bottomminDistFromEdge,
    double minEccentricity, double maxEccentricity, double minLength, double maxLength, double minCount, double maxCount, double maxDistFromLinear, bool includeSmall);
//Standard input : ([Output File Base],[Input Image] , NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)

class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 17;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::cout << "Starting detection\n";
        checkArguments(outputs, inputs);
        matlab::data::CharArray filebaseChar = inputs[0];
        std::string filebase = filebaseChar.toAscii();
        filebaseChar = inputs[1];
        std::string inputfile = filebaseChar.toAscii();

        double gaussStdDev = inputs[2][0];
        double binarizecutoff = inputs[3][0];
        double minSeparation = inputs[4][0];
        double leftminDistFromEdge = inputs[5][0];
        double rightminDistFromEdge = inputs[6][0];
        double topminDistFromEdge = inputs[7][0];
        double bottomminDistFromEdge = inputs[8][0];
        double minEccentricity = inputs[9][0];
        double maxEccentricity = inputs[10][0];
        double minLength = inputs[11][0];
        double maxLength = inputs[12][0];
        double minCount = inputs[13][0];
        double maxCount = inputs[14][0];
        double maxDistFromLinear = inputs[15][0];
        bool includeSmall = inputs[16][0];


        Detect_Particles(filebase, inputfile, gaussStdDev, binarizecutoff, minSeparation, leftminDistFromEdge, rightminDistFromEdge, topminDistFromEdge, bottomminDistFromEdge,
            minEccentricity, maxEccentricity, minLength, maxLength, minCount, maxCount, maxDistFromLinear, includeSmall);
        std::cout << "Finished dectection\n";
    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar("At least 16 inputs required - Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)") }));
        }

    }
};