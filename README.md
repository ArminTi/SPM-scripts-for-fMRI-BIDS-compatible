# SPM-Scripts-for-fMRI-BIDS-Compatible
BIDS Compatible fMRI Processing Pipeline Using SPM12


![SPM](https://img.shields.io/badge/SPM12-Neuroimaging-blue)

---
## 📌 Overview

This repository provides a **BIDS-compatible workflow** for preprocessing and analyzing **task-based fMRI data** using **SPM12**.  

The pipeline is organized around a **master script** that lets you run **one analysis step at a time**, avoiding accidental overwriting and simplifying debugging.

---
### ✔ Processing Steps  
Each analysis stage is a separate function:

- Extract behavior timing (onset/duration)
- Check/unzip NIfTI files
- Preprocessing (realign, coregister, normalize, smooth)
- Quality Control previews (motion + images)
- First-level GLM specification & estimation
- Second-level group analyses
- ROI-based parameter extraction (SPM.mat → ROI betas)
---

## 📁 Usage

To run the full pipeline, open MATLAB and run the master script:
    master_pipeline
Choose the number corresponding to the step you want to run.
The master script will load paths, verify directories, and run only the selected stage.


