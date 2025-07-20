**************************
Basic C++ Programs
**************************

This page describes the basic C++ programs included in the JIM image analysis suite. Each tool handles a specific part of the preprocessing and analysis workflow for multi-channel time-lapse microscopy data. These tools are modular, command-line driven, and designed to support batch processing and reproducible workflows.

Tiff Channel Splitter
====================

This program is designed to separate multi-channel TIFF image stacks into individual single-channel TIFF files. It supports both standard TIFF files and OME-TIFF files, which include embedded metadata describing channel layout and image dimensions. If metadata is available, it automatically detects the number of channels and frame order. For non-OME files, users can manually specify the number of channels and their spatial transformations. The program is capable of handling large datasets via BigTIFF support and supports datasets split across multiple TIFF files.

In addition to channel separation, the program supports image transformations to correct for image orientation mismatches, including vertical and horizontal flipping, and rotations of 90, 180, or 270 degrees. 

**Features:**

* Automatically detects the number of channels from OME metadata if available.
* Manual override for the number of channels if metadata is missing.
* Allows per-channel spatial transformations, including:
  * Vertical and horizontal flipping
  * 90°/180°/270° clockwise rotation
* Supports BigTIFF output for large files.
* Selects specific frame ranges to extract.
* Processes individual TIFF files or all TIFFs in a directory.

**Usage:**

./Tiff\_Channel\_Splitter <OutputBase> \<Input1.tif> \[Input2.tif ...] \[Options]

**Positional Arguments:**

* `<OutputBase>`: Output filename base.
* `<Input*.tif>`: One or more input TIFF files.

**Optional Flags:**

* `-NumberOfChannels <int>`: Manually set number of channels to extract (default: 2).
* `-StartFrame <int>`: Starting frame (1-based, negative values index from end).
* `-EndFrame <int>`: Ending frame (inclusive).
* `-DisableMetadata`: Ignore OME metadata and assume interleaved channel ordering.
* `-BigTiff`: Force output in BigTIFF format (for files >4 GB).
* `-DisableBigTiff`: Force output in classic TIFF format.
* `-Transform [channel vertflip horzflip rotateCW ...]`:
  Apply transformations for each channel. Example: `-Transform 1 1 0 90 2 0 1 0`
* `-DetectMultipleFiles`: Automatically detect all TIFFs in input directory.

**Outputs:**

* One TIFF file per channel: `<OutputBase>_Channel_<n>.tif`

**Assumptions:**

* Input images are grayscale.
* Without metadata, channels are assumed to be interleaved frame-wise.

**Dependencies:**

* `BLTiffIO`: TIFF reading/writing and metadata handling.
* Requires C++17 or later.

Align Channels
==============

This program performs drift correction and inter-channel alignment on TIFF image stacks. Its primary function is to compensate for shifts due to sample drift, as well as between imaging channels due to chromatic aberration or misalignment in optical paths.

**Features:**

* Sub-pixel drift correction.
* Inter-channel alignment using either automatic estimation or user defined transforms.
* Optionally writes aligned TIFF output.

**Usage:**

./Align\_Channels <OutputBase> \<Channel1.tif> \<Channel2.tif> ... \[Options]

**Dependencies:**

* `BLTiffIO`: TIFF file reading/writing.
* `BLImageTransform`: Image alignment and transformation operations.
* `BLFlagParser`: Command-line argument parsing.

Mean of Frames
==============

Generates a composite reference image from one or more channels over a defined frame range. The output of this program is typically used for particle detection.

**Features:**

* Applies spatial drift correction and channel alignment.
* Supports weighted averaging or max projection.
* Allows per-channel intensity scaling and flexible frame range selection.
* Normalization across time and/or channels is optional.

**Usage:**

./Mean\_of\_Frames <AlignmentCSV> <DriftCSV> <OutputBase> \<Input1.tif> \[Input2.tif ...] \[Options]

**Optional Flags:**

* `-Start <int...>`: Per-channel start frame (1-based or negative).
* `-End <int...>`: Per-channel end frame.
* `-Percent`: Treat `-Start` and `-End` values as percentages (0–100).
* `-Weights <float...>`: Per-channel intensity scaling.
* `-MaxProjection`: Use max projection instead of average.
* `-NoNorm`: Disable output normalization.

**Output:**

* `<OutputBase>_Partial_Mean.tiff`

**Dependencies:**

* `BLCSVIO`: For reading alignment and drift data.
* `BLTiffIO`: Multi-frame TIFF I/O.
* `BLImageTransform`: Drift and affine transformations.

# Detect\_Particles

This program performs particle detection on images using Laplacian of Gaussian (LoG) filtering before binarized using an intensity threshold to identify candidate regions of interest (ROIs). Detected regions can be further refined through filters based on their shape (such as eccentricity and axis length), size (pixel count), and position (e.g., proximity to image edges or to other particles).

**Features:**

* LoG filter-based region detection.
* Binarization thresholding.
* Filtering based on shape, geometry, and spacing.

**Usage:**

./Detect\_Particles \<TIFF\_Image> <OutputBase> \[Options]

**Optional Flags:**

* `-BinarizeCutoff <float>`: Threshold multiplier (default: 0.2).
* `-minDistFromEdge <float>`: Minimum distance from any image edge.
* `-left/right/top/bottom <float>`: Individual edge margins.
* `-minEccentricity / -maxEccentricity <float>`: Shape filtering.
* `-minLength / -maxLength <float>`: Filter based on major axis.
* `-minCount / -maxCount <float>`: Region size filter.
* `-maxDistFromLinear <float>`: Linear alignment filter.
* `-minSeparation <float>`: Minimum separation between detected ROIs.
* `-GaussianStdDev <float>`: LoG sigma (default: 5).
* `-includeSmall`: Include small regions in nearest-neighbor analysis.

**Outputs:**

* Binary and labeled region TIFFs.
* Raw and filtered ROI measurements in CSV.
* Pixel positions of ROIs in CSV.

**Dependencies:**

* `BLTiffIO`, `BLCSVIO`, `BLImageTransform`, `BLFlagParser`

Expand Shapes
=============

This program takes takes the detected foreground particles and generates spatially expanded masks for both the foreground and background regions associated with each particle.

**Features:**

* Expands ROIs with user-defined distances.
* Additional background pixels can be provided.
* Supports per-channel output and optional alignment.

**Usage:**

./Expand\_Shapes \<ROI\_Positions.csv> \<Background\_Positions.csv> <OutputBase> \[Options]

**Optional Flags:**

* `-boundaryDist <float>`: Foreground ROI expansion (default: 4.1).
* `-backInnerRadius <float>`: Background exclusion radius (default: = boundaryDist).
* `-backgroundDist <float>`: Outer background ROI radius (default: 20).
* `-extraBackgroundFile <file>`: Additional background pixel list.
* `-channelAlignment <file>`: Alignment matrix CSV for multi-channel expansion.

**Outputs:**

* Binary mask TIFFs of expanded ROIs.
* CSV files of pixel indices per channel.

**Notes:**

* First line of each CSV specifies image dimensions and pixel count.

**Dependencies:**

* `BLCSVIO`, `BLTiffIO`, `BLFlagParser`

Calculate Traces
================

Extracts fluorescence traces for each ROI across all frames in a TIFF stack, with background subtraction and optional drift correction.

**Features:**

* Computes background-subtracted intensity per ROI per frame.
* Optionally applies frame-wise drift correction.
* Outputs summary and detailed intensity data.

**Usage:**

./Calculate\_Traces \<TIFF\_Image> \<ROI\_CSV> \<Background\_CSV> <OutputBase> \[-Drift <DriftCSV>] \[-Verbose]

**Outputs:**

* Background-subtracted intensity CSV.
* Background-only intensity CSV.
* Verbose ROI trace CSV (with `-Verbose` flag).

**Dependencies:**

* `BLTiffIO`, `BLCSVIO`, `BLImageTransform`


