#pragma once
#include<vector>

class JimParams {
	//alignment
	std::string workingFolder;
	std::string fileName;
	int startFrame;
	int endFrame;
	size_t positionIn;
	std::vector<std::vector<float>>& alignments;
	bool skipIndependentDrifts;
	float maxShift;
	bool outputAligned;
	int numOfChannels = 1;
	bool filesSplitByChannelIn = false;

	//mean of frames
	struct MOFParameters {
		std::vector<int> start;
		std::vector<int> end;
		std::vector<int> bvMaxProject;
		std::vector<float> weights;
		bool bNormalize;
		std::string driftfile;
		std::string alignfile;
		std::string outputFileName;
	}
	std::vector< detectParameters> vMOFRepeats;

	//Detect Particles
	struct detectParameters {
		std::string detectOutputfileBase;
		std::string inputfile;
		double gaussStdDev;
		double binarizecutoff;
		double minSeparation;
		double leftminDistFromEdge;
		double rightminDistFromEdge;
		double topminDistFromEdge;
		double bottomminDistFromEdge;
		double minEccentricity;
		double maxEccentricity;
		double minLength;
		double maxLength;
		double minCount;
		double maxCount;
		double maxDistFromLinear;
		bool includeSmall
	}
	std::vector< detectParameters> vdetectRepeats;

	//Expand Shapes
	std::string output;
	std::string foregroundposfile;
	std::string backgroundposfile;
	std::string extraBackgroundFileName;
	std::string channelAlignmentFileName;
	float boundaryDist;
	float backinnerradius;
	float backgroundDist;


	//calculate traces add a class for each channel
	struct calculateTracesChannel {
		size_t channelIn;
		std::string ROIfile;
		std::string backgroundfile;
		std::string driftfile = "";
		std::string weightImageFile = "";
	};
	std::vector< calculateTracesChannel> vTracesChannelInfo;
	int calculateTracesStartFrame = 1;
	int calculateTracesEndFrame = -1;



}