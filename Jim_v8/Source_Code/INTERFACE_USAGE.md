# JIM Interface Usage

Last updated: 2026-05-28

## Conventions

- CLI flags are case-sensitive and use a leading `-` (example: `-Start`).
- CLI boolean flags are switch-style: include the flag to set it `true` (no value required).
- MATLAB MEX interfaces use positional required inputs followed by name/value pairs unless noted.
- Defaults below are documented as currently implemented in source.

## Align_Channels

### CLI

```text
Align_Channels <fileName> [options]
```

Required positional arguments:

- `fileName`: Input TIFF stack or input base.

Options:

- `-Start <int>` default `1`
- `-End <int>` default `-1` (all frames)
- `-Position <int>` default `0` (all positions)
- `-MaxShift <float>` default `FLT_MAX` (effectively unlimited)
- `-OutputAligned` default `false`
- `-SkipIndependentDrifts` default `false`
- `-Alignment <v1 ... v4N>` default empty. Must be `4` values per extra channel.
- `-NumberOfChannels <int>` default `1`
- `-FilesSplitByChannel` default `false`
- `-Output <string>` default empty

### MATLAB MEX

```matlab
Align_Channels(fileName, ...
  'Start', startFrame, ...
  'End', endFrame, ...
  'Position', positionIn, ...
  'Alignment', alignmentMatrix, ...
  'SkipIndependentDrifts', logicalValue, ...
  'MaxShift', value, ...
  'OutputAligned', logicalValue, ...
  'NumberOfChannels', n, ...
  'FilesSplitByChannel', logicalValue, ...
  'Output', outputBase)
```

Defaults match CLI.

## Bleach_Correct

### CLI

```text
Bleach_Correct <input_csv> <output_base> <mean_bleach_frame>
```

Required positional arguments:

- `input_csv`: CSV file of traces.
- `output_base`: output base name.
- `mean_bleach_frame`: bleaching decay timescale.

### MATLAB MEX

```matlab
Bleach_Correct(outputBase, inputCsv, meanBleachFrame)
```

## Calculate_Traces

### CLI

```text
Calculate_Traces <fileName> <positionIn> <ROIfile> <backgroundfile> [options]
```

Required positional arguments:

- `fileName`
- `positionIn`
- `ROIfile`
- `backgroundfile`

Options:

- `-Start <int>` default `1`
- `-End <int>` default `-1`
- `-Drift <file>` default empty
- `-Alignment <file>` default empty
- `-NumberOfChannels <int>` default `1`
- `-FilesSplitByChannel` default `false`
- `-Output <string>` default empty

### MATLAB MEX

```matlab
Calculate_Traces(fileName, positionIn, ROIfile, backgroundfile, ...
  'Start', startFrame, ...
  'End', endFrame, ...
  'Drift', driftFile, ...
  'Alignment', alignmentFile, ...
  'NumberOfChannels', n, ...
  'FilesSplitByChannel', logicalValue, ...
  'Output', outputBase)
```

Defaults match CLI.

## Detect_Particles

### CLI

```text
Detect_Particles <input_tiff> <binarize_cutoff> [options]
```

Required positional arguments:

- `input_tiff`
- `binarize_cutoff`

Options:

- `-Output <string>` default empty
- `-GaussianStdDev <float>` default `5` (if supplied value `<= 0`, code resets to `5`)
- `-MinSeparation <float>` default `0`
- `-MinDistFromEdge <float>` default `-0.1`
- `-LeftMinDistFromEdge <float>` default `-0.1`
- `-RightMinDistFromEdge <float>` default `-0.1`
- `-TopMinDistFromEdge <float>` default `-0.1`
- `-BottomMinDistFromEdge <float>` default `-0.1`
- `-MinEccentricity <float>` default `-0.1`
- `-MaxEccentricity <float>` default `1.1`
- `-MinLength <float>` default `0`
- `-MaxLength <float>` default `10000000000.0`
- `-MinCount <float>` default `0`
- `-MaxCount <float>` default `1000000000.0`
- `-MaxDistFromLinear <float>` default `10000000.0`
- `-IncludeSmall` default `false`

### MATLAB MEX

```matlab
Detect_Particles(inputImage, binarizeCutoff, ...
  'Output', outputBase, ...
  'GaussianStdDev', value, ...
  'MinSeparation', value, ...
  'MinDistFromEdge', value, ...
  'LeftMinDistFromEdge', value, ...
  'RightMinDistFromEdge', value, ...
  'TopMinDistFromEdge', value, ...
  'BottomMinDistFromEdge', value, ...
  'MinEccentricity', value, ...
  'MaxEccentricity', value, ...
  'MinLength', value, ...
  'MaxLength', value, ...
  'MinCount', value, ...
  'MaxCount', value, ...
  'MaxDistFromLinear', value, ...
  'IncludeSmall', logicalValue)
```

MEX defaults as implemented:

- `GaussianStdDev=5`
- `MinSeparation=0`
- Edge distances default `0`
- `MinEccentricity=-0.1`, `MaxEccentricity=1.1`
- `MinLength=0`, `MaxLength=100000000`
- `MinCount=0`, `MaxCount=100000000`
- `MaxDistFromLinear=100000000`
- `IncludeSmall=true`

## Expand_Shapes

### CLI

```text
Expand_Shapes <foreground_positions_csv> <background_positions_csv> [options]
```

Required positional arguments:

- `foreground_positions_csv`
- `background_positions_csv`

Options:

- `-BoundaryDist <float>` default `4.1`
- `-BackInnerRadius <float>` default effectively `BoundaryDist` (if less than boundary, code resets to boundary)
- `-BackgroundDist <float>` default `20.0`
- `-ExtraBackgroundFile <file>` default empty
- `-Output <string>` default empty

### MATLAB MEX

```matlab
Expand_Shapes(foregroundPositionsFile, backgroundPositionsFile, ...
  'BoundaryDist', value, ...
  'BackInnerRadius', value, ...
  'BackgroundDist', value, ...
  'ExtraBackgroundFile', extraBackgroundFile, ...
  'Output', outputBase)
```

MEX defaults as implemented:

- `BoundaryDist=4.1`
- `BackInnerRadius=7.1`
- `BackgroundDist=30`
- `ExtraBackgroundFile=''`
- `Output=''`

## Isolate_Particle

### CLI

```text
Isolate_Particle <fileName> <positionIn> <particle> [options]
```

Required positional arguments:

- `fileName`
- `positionIn`
- `particle`

Options:

- `-Start <int>` default `1`
- `-End <int>` default `-1`
- `-MontageImages <int>` default `10`
- `-OutputImageStack` default `false`
- `-NumberOfChannels <int>` default `1`
- `-FilesSplitByChannel` default `false`
- `-Drift <file>` default empty
- `-Alignment <file>` default empty
- `-Measurement <file>` default empty
- `-Output <string>` default empty

### MATLAB MEX

```matlab
Isolate_Particle(fileName, positionIn, particle, ...
  'Start', startFrame, ...
  'End', endFrame, ...
  'MontageImages', n, ...
  'OutputImageStack', logicalValue, ...
  'NumberOfChannels', n, ...
  'FilesSplitByChannel', logicalValue, ...
  'Drift', driftFile, ...
  'Alignment', alignmentFile, ...
  'Measurement', measurementFile, ...
  'Output', outputBase)
```

Defaults match CLI.

## Mean_of_Frames

### CLI

```text
Mean_of_Frames <fileName> [options]
```

Required positional arguments:

- `fileName`

Options:

- `-Position <int>` default `0`
- `-Start <v1 v2 ...>` default empty vector (function-level default behavior)
- `-End <v1 v2 ...>` default empty vector (function-level default behavior)
- `-MaxProjection <v1 v2 ...>` default empty vector
- `-Weights <w1 w2 ...>` default empty vector
- `-NoNorm` default `false` (if present, normalization disabled)
- `-Drift <file>` default empty
- `-Alignment <file>` default empty
- `-Output <string>` default empty

### MATLAB MEX

```matlab
Mean_of_Frames(fileName, ...
  'Position', positionIn, ...
  'Start', startFrames, ...
  'End', endFrames, ...
  'MaxProjection', maxProjectionFlags, ...
  'Weights', weights, ...
  'NoNorm', logicalFlag, ...
  'Drift', driftFile, ...
  'Alignment', alignmentFile, ...
  'Output', outputBase)
```

Defaults:

- `Position=0`
- `Start=[]`, `End=[]`, `MaxProjection=[]`, `Weights=[]`
- Normalization enabled by default.
- For MEX, pass `'NoNorm', true` to disable normalization.

## Picasso_Raw_Converter

### CLI

```text
Picasso_Raw_Converter <input_tiff> <output_base>
```

Required positional arguments:

- `input_tiff`
- `output_base`

### MATLAB MEX

```matlab
Picasso_Raw_Converter(outputBase, inputTiff)
```

Note: MEX argument order is `outputBase` first, then `inputTiff`.

## Step_Fitting

### CLI

```text
Step_Fitting <input_csv> [options]
```

Required positional arguments:

- `input_csv`

Options:

- `-TThreshold <float>` default `1.96`
- `-MaxSteps <int>` default `-1`
- `-Output <string>` default empty
- `-Aggarwal` (method `0`, default)
- `-TTest` (method `1`)
- `-AutoStepFit` (method `2`)
- `-ChangePoint` (method `3`)

### MATLAB MEX

```matlab
Step_Fitting(inputfile, ...
  'TThreshold', value, ...
  'MaxSteps', value, ...
  'Output', outputBase, ...
  'Aggarwal' | 'TTest' | 'AutoStepFit' | 'ChangePoint')
```

Defaults match CLI.

Current behavior note:

- The core implementation currently writes output using a fixed `StepFit` base path and does not apply the provided `Output` value.
