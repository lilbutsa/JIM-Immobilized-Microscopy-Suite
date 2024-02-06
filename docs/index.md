
# JIMS’ Immobilized Microscopy Suite (JIM)

JIM is a collection of programs designed to simplify the quantitation of _in vitro_ TIRF microscopy experiments. In particular, it is designed to analyze experiments where a substrate is immobilized on the surface of a coverslip before fluorescent reagents are bound to the substrate.

Typical substrates will take the form of diffraction-limited particles like liposomes, viruses, DNA origami etc. or polymers like elongated structures such as actin filaments, fibrils etc. JIM contains specific programs to analyze the binding to arbitrarily shaped substrates.

The output of JIM for binding analysis is in the form of traces. If an image is taken over several frames, a trace is the fluorescent intensity for an analysed particle with the background intensity subtracted n each frame of the experiment.

JIM can be used to analyze straight filaments and is also capable of joining filaments if they are partially labeled. JIM generates kymographs of filaments that can then be used as the basis for kinetic analysis. JIM is modular and can be executed through command line arguments, making the implementation of common pipelines in any other programming language trivial. To date, standard analysis protocols have been implemented in Matlab and will soon be made available in Mathematica and ImageJ.

The key motivation of JIM is to enable users with minimal programming knowledge to analyze a wide range of standard _in vitro_ TIRF microscopy experiments while still maintaining the flexibility to adapt to specific experiments.

Additional Matlab scripts are included to determine binding affinity to substrate  (_K<sub>d</sub>_), single molecule bleaching, and binding kinetics to complement JIM’s usability to analyse binding experiments

