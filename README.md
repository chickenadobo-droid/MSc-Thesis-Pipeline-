### Electrophysiological and Behavioural Annalysis Pipeline 

OVERVIEW

This repository contains the complete MATLAB analysis pipeline developed for my MSc thesis. Te scripts are designed to process, align, and analyse simultaneous electrophysiological recordings (Multi-Unit Activity, Local Field Potential) and behavioural tracking data to investigate the effects of chemogenetic manipulations.

The core of the analysis involves

i) Behavioural Data Processing; Batch processing of video tracking data to extract animal position, clean artifacts, calculate speed, and define behavioural states based on stringent, data-driven criteria.

ii) Neural Data Extraction; Extraction of neural features like sharp-wave ripple events/power, theta power/frequency and multi-unit activity.

iii) Integrated Statistical Modelling; Implementation of linear mixed-effects models to assess the impact of experimental conditions (CNO vs. Vehicle) on neural activity, while accounting for behavioural state and time as covariates.

iv) Data Visualisation: Generation of figures to display the results, including time-course plots faceted by behavioural state and diagnostic plots for data quality control.

This code is provided so that the analysis can be fully reproduced and understood.

REPOSITORY STRUCTURE

The pipeline is organised into distinct sections:

PositionExtraction/

Contains a suite of scripts for the initial processing of raw video tracking files. Key functions include initial xy coordinate extraction for one session where I refined and validated my code (ExtractOneSession), creation of arena masks and organising/cleaning of structures for later streamlining of analysis (BuildMasksandRenameStructFields), comprehensive artifact removal (PostHocTrackingArtifactManualRemoval), and behavioural classification (SleepDetection).

PositionCleaning/

This directory contains the primary batch processing script that integrates and applies the tools from PositionExtraction. It handles data smoothing, artifact removal, speed calculation, and the final classification of behavioural states ('Still' vs. 'Moving') for each recording session.

glmResults/

This is the final stage of my analysis pipeline. It contains the main statistical analysis scripts that fit the linear mixed-effects models and generate the final figures and post-hoc tables for the thesis.

Recommended Workflow
The analysis is designed to be run in a sequential manner:

Initial Extraction: Begin by using the scripts within the /PositionExtraction directory to process raw video files, extract XY coordinates, and define the spatial parameters of the arenas for each session.

Cleaning and Classification: Run the master script within the /PositionCleaning directory. This will apply smoothing, remove artifacts, calculate speed, and classify the data into distinct behavioural states, creating the final processed data files.

Statistical Analysis: Finally, use the scripts in the /glmResults directoryati load the fully processed data andstics an linear mixed-effects Toolbo to test the experimental hypotheses!
