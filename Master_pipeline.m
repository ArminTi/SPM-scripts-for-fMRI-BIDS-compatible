%% ========================================================================
% MASTER ANALYSIS PIPELINE for fMRI Processing (SPM12)
% ========================================================================
%
%   Armin Toghi
%   Project: fMRI Task-Based Analysis Pipeline
%   Toolbox: SPM12 (https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)
%
% ------------------------------------------------------------------------
% DESCRIPTION
% This master script organizes all major steps for preprocessing and 
% analyzing fMRI task-based data using SPM12 with BIDS compatible format, including:
%
%   1. Onset/duration extraction
%   2. Data integrity checks + unzip
%   3. Preprocessing
%   4. QC preview
%   5. First-level GLM
%   6. Second-level exploratory analysis
%   7. Second-level ROI-based extraction
%
% ------------------------------------------------------------------------
% REQUIREMENTS:
%   - MATLAB R2019a or newer
%   - SPM12 added to MATLAB path
%   - NIfTI data organized in BIDS-like format 
%
% ------------------------------------------------------------------------
% NOTE:
%   This script does NOT run all steps automatically. 
%   It executes ONE step at a time to prevent accidental overwriting.
%
% ========================================================================

clear
clc

%% ========================== USER CONFIGURATION ==========================

% ------------------------------ Data paths -------------------------------
Datadir = 'D:\1.Course\fMRI_Course\Material\3. SPM_task_based\2_Project_1\Face_Object\Task';
subjects = {'sub-01'};
runs = [1 2];

% ----------------------------- Contrasts --------------------------------
contrast = {'con_0006', 'con_0007', 'con_0008'};

% ----------------------------- ROI Mask ---------------------------------
mask = fullfile(Datadir, 'mask', 'parahippocamp_sphere.nii');

% -------------------------- Second Level SPM -----------------------------
spm_files = {
    fullfile(Datadir, 'second_level', 'con_0001', 'SPM.mat')
    fullfile(Datadir, 'second_level', 'con_0003', 'SPM.mat')
    fullfile(Datadir, 'second_level', 'con_0005', 'SPM.mat')
};

% --------------------------- SPM Location --------------------------------
SPM_dir = 'C:\Users\ASUS\Desktop\Apps\spm12';


%% ============================== MENU ====================================

fprintf('\nSelect a pipeline step to implement:\n')
fprintf('   1 - Extract events (onset + duration)\n')
fprintf('   2 - Check & unzip functional data\n')
fprintf('   3 - Preprocessing\n')
fprintf('   4 - QC preview\n')
fprintf('   5 - First-level GLM\n')
fprintf('   6 - Second-level analysis (exploratory)\n')
fprintf('   7 - ROI-based second-level extraction\n\n')

job = input('Enter the step number: ');

%% ============================ PIPELINE CALL =============================

switch job
    case 1
        fprintf('\nRunning: Extracting onset/duration...\n')
        extract_onset_duration(Datadir, subjects)

    case 2
        fprintf('\nRunning: Checking/unzipping data...\n')
        check_and_unzip_data(Datadir, subjects)

    case 3
        fprintf('\nRunning: Preprocessing...\n')
        fMRI_Preprocessing(Datadir, subjects, SPM_dir)

    case 4
        fprintf('\nRunning: QC preview...\n')
        qc_preview_subjects(Datadir, subjects, runs)

    case 5
        fprintf('\nRunning: First-level GLM...\n')
        fMRI_first_level(Datadir, subjects)

    case 6
        fprintf('\nRunning: Second-level exploratory analysis...\n')
        Second_level_analysis_exploratory(Datadir, subjects, contrast)

    case 7
        fprintf('\nRunning: ROI-based second-level extraction...\n')
        Second_level_analysis_ROI_based(mask, spm_files)
end

fprintf('\n✓ Pipeline step completed successfully.\n')
fprintf('------------------------------------------------------------------\n');
