# SPM-scripts-for-fMRI-BIDS-compatible
BIDS Compatible fMRI Processing Pipeline Using SPM12


![SPM](https://img.shields.io/badge/SPM12-Neuroimaging-blue)

---
## 📌 Overview

This repository provides a **clean, BIDS-compatible workflow** for preprocessing and analyzing **task-based fMRI data** using **SPM12**.  
It is designed for researchers, students, and labs who want to:

- Automate SPM preprocessing
- Standardize analyses across participants
- Run first-level and second-level GLMs
- Extract ROI-based statistics
- Integrate SPM with BIDS-formatted datasets

The pipeline is organized around a **master script** that lets you run **one analysis step at a time**, avoiding accidental overwriting and simplifying debugging.

---

## 🚀 Key Features

### ✔ BIDS-Compatible Directory Usage  
Reads subject folders in a BIDS-like structure (e.g., `sub-01/func/`).

### ✔ Modular Processing Steps  
Each analysis stage is a separate function:

- Extract behavior timing (onset/duration)
- Check/unzip NIfTI files
- Preprocessing (realign, coregister, normalize, smooth)
- Quality Control previews (motion + images)
- First-level GLM specification & estimation
- Second-level group analyses
- ROI-based parameter extraction (SPM.mat → ROI betas)
---

## 📁 Repository Structure

SPM-fMRI-BIDS-Compatible-Scripts/
│
├── master_pipeline.m # Main controller script
│
├── functions/ # All pipeline modules
│ ├── extract_onset_duration.m
│ ├── check_and_unzip_data.m
│ ├── fMRI_Preprocessing.m
│ ├── qc_preview_subjects.m
│ ├── fMRI_first_level.m
│ ├── Second_level_analysis_exploratory.m
│ ├── Second_level_analysis_ROI_based.m
│ └── utils/ # Helper functions (optional)
│
├── mask/ # ROI masks (example)
│ └── parahippocamp_sphere.nii
│
├── second_level/ # Example SPM.mat outputs
│
├── README.md
└── LICENSE
