Jimbob
======

**Jimbob** is a Micro-Manager plugin for quickly previewing particle
detection, trace generation, and simple trace fitting directly from an open
Micro-Manager dataset. It is a lightweight version of the JIM trace-generation
pipeline: it favours fast feedback and interactive inspection over the full
set of options available in the offline JIM tools.

Jimbob can:

* Build a drift-corrected detection image from a selected frame range.
* Detect particles using a Laplacian-of-Gaussian image and shape filters.
* Measure foreground and local-background-corrected intensity traces.
* Estimate sample drift with FFT cross-correlation.
* Apply manually entered or automatically detected channel-to-channel offsets.
* Display example trace montages, selected traces, mean traces, backgrounds,
  drift plots, and aligned stacks.
* Save trace CSV files, measurements, and plot PNGs.
* Run step fitting and mean-trace fits, including batch fitting across all
  positions in a Micro-Manager dataset.

Limitations
-----------

Jimbob is designed for rapid inspection rather than full pipeline replacement.
The main limitations are:

**Single detection region**
    The FFT alignment reference is taken from a central square region of the
    image. This works best when the central region contains stable signal.

**No image transformation**
    Jimbob assumes images are already correctly oriented. It does not rotate,
    flip, deskew, or otherwise transform images.

**Integer-pixel alignment**
    Drift correction and channel alignment are applied as integer-pixel shifts.

**Single-pass drift correction**
    Drift is estimated once from the alignment ROI and then applied to the
    detection image, aligned stack display, and trace measurement.

**Bounding-box based ROI expansion**
    Detected particles are expanded from the detected component/bounding box to
    define foreground and local-background measurement regions.

**Fits are simple diagnostics**
    Step fitting and mean-trace fitting are intended for quick feedback. For
    final analysis, confirm fit ranges, normalization, and edge cases in the
    saved CSV output.

Installing Jimbob
-----------------

To run Jimbob in Micro-Manager, copy ``Jimbob.jar`` into the ``mmplugins``
folder in your Micro-Manager installation. On a default Windows installation
this is usually:

``C:\Program Files\Micro-Manager-2.0\mmplugins``

Do **not** put the jar in the ``plugins`` folder. Micro-Manager menu plugins
must be placed in ``mmplugins``.

Basic workflow
--------------

1. Open an image dataset in Micro-Manager.
2. Open **Plugins > Jimbob**.
3. Open the **Select File** drop-down and choose the Micro-Manager display to
   analyse. The current position in that display is used for single-position
   operations.
4. Set detection and alignment parameters.
5. Click **Make Detection Image** to build and display the averaged,
   drift-corrected detection image.
6. Click **Detect Particles** to threshold, filter, and expand detected
   particles.
7. Click **Generate Traces** to measure fluorescence and background traces.
8. Use **Show Page of Traces** or **Trace Highlight > Select** to inspect
   individual traces.
9. Choose a **Fit Type** and click **Fit**, or add fits to the batch list and
   click **Batch All Positions**.

Selecting data and output folders
---------------------------------

**Select File**
    Lists image stacks currently open in Micro-Manager. Selecting a display
    updates the image dimensions, number of channels, number of frames, number
    of positions, frame time estimate, and default output directory.

**Folder Path**
    Output folder used when saving traces and plots. Jimbob first tries to use
    the current datastore save path from the selected Micro-Manager display. If
    that is unavailable, it falls back to the dataset metadata directory.

**Browse**
    Opens a directory chooser to manually select the output folder.

Detection and drift parameters
------------------------------

**Align ROI size (2^n)**
    Width and height of the central square region used for FFT alignment. The
    value is clamped to the image size and rounded to a power of two. Larger
    values are usually more robust but slower.

**Align Max Shift**
    Maximum drift/channel shift, in pixels, considered by the FFT
    cross-correlation search. Lower values can prevent incorrect large shifts
    when the alignment signal is weak.

**Detection Channel**
    Channel used for detection-image creation and alignment. Use ``0`` to sum
    all channels. Use ``1`` for channel 1, ``2`` for channel 2, and so on.

**Drift Only Detect**
    When a detection channel is selected, this controls whether trace drift
    correction is also estimated from only that channel. If it is not selected,
    trace drift correction uses the sum of all channels.

**Start/End Frame**
    Frame range used to build the detection image. The start frame is
    one-based. Negative end-frame values count back from the end of the stack;
    for example, ``-1`` means the last frame.

**Make Detection Image**
    Builds the detection image by summing the selected channel(s), estimating
    drift in the central alignment ROI, and accumulating a drift-corrected mean
    image over the selected frame range.

Particle detection parameters
-----------------------------

**Cutoff**
    Threshold for the Laplacian-of-Gaussian detection image. Typical values are
    in the range ``0.5`` to ``4``.

**Min/Max Eccentricity**
    Shape filters based on the eccentricity of the best-fit ellipse. ``0`` is
    close to circular and ``1`` is close to linear. Use the minimum to exclude
    round objects and the maximum to exclude long, thin objects.

**Min/Max Count**
    Minimum and maximum detected-pixel count for accepting a particle. These
    filters are useful for excluding background speckles and aggregates.

**Min Dist to Edge**
    Excludes particles close to the image edge. This should generally be larger
    than the maximum expected drift.

**Minimum Separation**
    Minimum nearest-neighbour separation in pixels.

**Roi/Back. Padding**
    The first value expands detected particles to define the foreground ROI.
    The second value defines the surrounding local-background region.

**Detect Particles**
    Runs thresholding, connected-component measurement, shape filtering, ROI
    expansion, and optional display of the detection stack with overlays.

Channel alignment
-----------------

**Input**
    Opens a dialog for manually entering channel-to-channel x/y offsets. Channel
    1 is the reference; offsets are entered for channels 2 and above.

**Detect**
    Estimates channel-to-channel offsets automatically over a selected frame
    range. Jimbob sums each channel over the chosen frames, aligns channels 2
    and above to channel 1, stores the detected offsets, and displays an aligned
    channel stack.

Trace generation and inspection
-------------------------------

**Generate Traces**
    Measures foreground and local-background-corrected intensity traces for
    every detected particle, channel, and frame. Drift correction is applied by
    shifting measurement positions according to the FFT drift estimates.

**Show Stack**
    Displays the drift-corrected image stack after trace generation. This can
    use substantial memory for large datasets.

**Save Traces**
    Saves detected-particle measurements, fluorescence traces, background
    traces, mean plots, example trace montages, and fit outputs when applicable.

**Normalize**
    Normalizes plotted traces for easier visual comparison between channels.
    This affects display plots only; saved raw trace CSV files are not changed.

**Show Page of Traces**
    Displays a montage of up to 36 particle traces. The page number controls
    which group of particles is shown.

**Trace Highlight / Select**
    Highlights one particle in the detection or aligned stack, and displays that
    particle's channel traces.

**Frame Time / Units**
    Sets the x-axis scaling and units for trace and fit plots. Jimbob attempts
    to estimate the frame time from Micro-Manager image metadata when a dataset
    is selected.

Fitting
-------

**Fit Type**
    Selects the fit performed by the **Fit** button:

    * **Step Fit** - finds a single best step position in each particle trace,
      classifies traces, plots example traces, and plots step survival and step
      height summaries.
    * **Linear** - fits ``y = a + b t`` to the selected mean trace.
    * **Exponential** - fits ``y = a + b exp(-c t)``.
    * **Nuc Pol** - fits a simple nucleation/polymerisation model without
      bleaching.
    * **Nuc Pol with Input Bleaching** - asks for a bleaching frame and fits
      nucleation/polymerisation with a fixed bleaching rate.
    * **Nuc Pol with Fit Bleaching** - fits nucleation, polymerisation, and
      bleaching parameters.

**Channel to Fit**
    One-based channel number used for step fitting or mean-trace fitting.

**Normalize by**
    Controls how mean-trace fits are normalized:

    * **None** - fit the selected channel's mean trace directly.
    * **Min Channel** - normalize each particle by the minimum value of the
      normalization channel.
    * **Max Channel** - normalize each particle by the maximum value of the
      normalization channel.
    * **Mean Channel** - normalize each particle by the mean of the
      normalization channel.
    * **First Frame Channel** - normalize each particle by frame 1 of the
      normalization channel.
    * **Last Frame Channel** - normalize each particle by the final frame of
      the normalization channel.
    * **Each Frame Channel** - normalize each frame by the same frame of the
      normalization channel.
    * **Constant Value** - divide the selected channel's mean trace by the
      value in the normalization field.

**Norm Channel/Value**
    For channel-based normalization, this is a one-based channel number. For
    constant normalization, this is the constant divisor.

**Fit Min/Max Frame**
    Frame range used for fitting. The minimum frame is one-based. Negative
    maximum-frame values count back from the end of the stack.

**Washin Frame**
    Frame used as the time origin for mean-trace fitting.

**Add Fit To Batch**
    Adds the current fit settings to the batch-fit list.

**Clear Fit Batch**
    Clears the batch-fit list.

**Fit**
    Runs the selected fit for the current position and displays/saves the
    resulting plots and CSV files according to the output settings.

Batch processing
----------------

**Batch All Positions**
    Runs the complete workflow for every position in the selected dataset:
    detection-image creation, particle detection, trace generation, and each fit
    in the batch-fit list. Batch mode forces saving on and suppresses most
    interactive displays.

Saved outputs
-------------

When **Save Traces** is enabled, Jimbob writes outputs into a per-dataset
analysis folder under the selected output directory. Outputs can include:

* ``Detected_Filtered_Measurements.csv``
* ``Channel_N_Fluorescent_Intensities.csv``
* ``Channel_N_Fluorescent_Backgrounds.csv``
* ``Mean_Trace_...png``
* ``Mean_Background_Trace.png``
* ``Example_Traces_Page_N.png``
* ``Example_Single Steps_Page_N.png``
* ``Example_No Step_Page_N.png``
* ``Example_Other_Page_N.png``
* ``Stepfit_Survival_...png``
* ``Stepfit_StepHeight.png``
* ``Stepfit_Single_Step_Fits.csv``
* ``Channel_N_<fit type>.png``
* ``Channel_N_<fit type>.csv``

Notes
-----

Jimbob expects image data to be available through an open Micro-Manager
``DataViewer``. If a button appears to do nothing, first confirm that a display
has been selected in **Select File**, that the selected position contains image
data, and that detection/traces have been generated before running trace
inspection or fitting.
