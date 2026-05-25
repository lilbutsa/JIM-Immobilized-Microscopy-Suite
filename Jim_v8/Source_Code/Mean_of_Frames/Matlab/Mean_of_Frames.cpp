#include "mex.hpp"
#include "mexAdapter.hpp"
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLMatlabParser.h"



int Mean_of_Frames(std::string fileName, int positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize, std::string driftfile = "", std::string alignfile = "", std::string outputFileName = "Image_For_Detection_Partial_Mean");

//Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe,Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
class MexFunction : public matlab::mex::Function {
public:
    const int minNumOfInputs = 6;
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        //std::cout << "Starting Program\n";
        checkArguments(outputs, inputs);
        std::vector<int> start, end, bvMaxProject;
        std::vector<float>  weights;


        std::string fileName = parseStringMatlab(inputs,0);
        int positionIn = inputs[1][0];
        parse1DMatlabArray(inputs,2, start);
        parse1DMatlabArray(inputs,3, end);
        parse1DMatlabArray(inputs,4, bvMaxProject);
        parse1DMatlabArray(inputs,5, weights);

        bool bNormalize = true;
        std::string driftfile = "", alignfile = "",outputfile = "Image_For_Detection_Partial_Mean";

        for (size_t paramcount = minNumOfInputs; paramcount < inputs.size() - 1; paramcount = paramcount + 2) {
            std::string optionArg = parseStringMatlab(inputs, paramcount);
            if (optionArg == "Normalize") bNormalize = inputs[paramcount + 1][0];
            else if (optionArg == "DriftFile")driftfile = parseStringMatlab(inputs, paramcount + 1);
            else if (optionArg == "OutputFile")outputfile = parseStringMatlab(inputs, paramcount + 1);
        }


        Mean_of_Frames(fileName, positionIn, start, end, bvMaxProject, weights, bNormalize, driftfile, alignfile, outputfile);

    }


    void checkArguments(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlab::data::ArrayFactory factory;

        std::string errormsg = "Mean_of_Frames\nDescription:\nThis program generates a combined reference image from a range of frames across multiple imaging channels.\nIt applies drift correction, channel alignment, and optional normalization.\n";
            errormsg += "Call:\n Mean_of_Frames(folderName,positionIn,start, end, maxProject,weights)\n";
            errormsg += "Variables:\n-folderName:eg.\n";
            errormsg += "start: array with the start frame for each channel. First frame is 1. Needs a value for each channel. Negative values go from endeg.for three channel data [2 -4 5]. Channel 1 would start from the 2nd frame, channel 2 from the 4th last frame and channel 3 from frame 5 \n";
            errormsg += "end: array with the end frame for each channel. Same as start, First frame is 1. Needs a value for each channel. Negative values go back from the last frame. \n";
            errormsg += "maxProject: array with the weight for each channel. Needs a value for each channel. e.g. [0.5 1.5 3] will multiply channels 1 by 0.5, 2 by 1.5 and 3 by 3 before they are added.\n";
            errormsg += "weights: array with the weight for each channel. Needs a value for each channel. e.g. [0.5 1.5 3] will multiply channels 1 by 0.5, 2 by 1.5 and 3 by 3 before they are added.\n";
            errormsg += "Options: \nNormalize: (true or false) whether to normalize all images before mulitplying by weight and summing.(default = true)\n";
            errormsg += "DriftFile: manually set the csv file used for drift correction\n";
            errormsg += "AlignFile: manually set the csv file used for channel alignment\n";

        if (inputs.size() < minNumOfInputs) {
            matlabPtr->feval(u"error",
                0, std::vector<matlab::data::Array>({ factory.createScalar(errormsg) }));
        }

    }
};