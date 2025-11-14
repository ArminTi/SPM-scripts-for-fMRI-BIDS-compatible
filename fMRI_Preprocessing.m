function fMRI_Preprocessing(root, subjects, SPM_dir)
%====================================================================
% fMRI_Preprocessing(root, subjects, SPM_dir)
%
% This function runs preprocessing 
% for multiple subjects using SPM12.
%
% INPUTS:
%   root      : path to the main data directory containing subject folders
%   subjects  : cell array of subject IDs (e.g., {'sub-01','sub-02'})
%   SPM_dir   : path to your SPM installation directory (with TPM.nii inside /tpm/)
%
% Each subject folder should contain:
%   anat/sub-XX_T1w.nii             -> anatomical image
%   func/sub-XX__ses-mri_task-facerecognition_run-01_bold.nii
%   func/sub-XX__ses-mri_task-facerecognition_run-02_bold.nii
%   func/run-01_Famous.txt, etc.    -> onset files for each condition
%
%--------------------------------------------------------------------
% Processing steps:
%   1. Realignment (motion correction)
%   2. Slice Timing correction
%   3. Coregistration (mean functional to anatomical)
%   4. Segmentation (to estimate deformation fields)
%   5. Normalization (apply deformation to functional data)
%   6. Smoothing
%
% Armin Toghi Nov 14 2025
%====================================================================


startDir = pwd;

for i = 1:numel(subjects)

    disp(['Starting preprocessing for ', subjects{i}]) 

    %------------------------------------------------------------------
    % Define directories for this subject
    %------------------------------------------------------------------

    anat_dir = fullfile(root, subjects{i}, 'anat'); % this combines the root with a specific subject directory to create the full path to the folder containing anatomical data
    func_dir = fullfile(root, subjects{i}, 'func'); % this combines the root with a specific subject directory to create the full path to the folder containing functional data
    

    %------------------------------------------------------------------
    % Locate structural and functional files
    %------------------------------------------------------------------
    % find the structural and functional file
    anat = spm_select('FPList', anat_dir, '^sub-*.*_T1w.nii$'); % this will return the full path (FP) to the T1 file from the anat directory
    func_run1 = spm_select('ExtFPList', func_dir, '^sub-.*_ses-mri_task-facerecognition_run-01_bold\.nii$', Inf);
    func_run2 = spm_select('ExtFPList', func_dir, '^sub-.*_ses-mri_task-facerecognition_run-02_bold\.nii$', Inf);
    
    %------------------------------------------------------------------
    % Create first-level directory
    %------------------------------------------------------------------
    cd(func_dir) % move into the subject specific folder containing the functional data
    

    %==================================================================
    % STEP 1: REALIGNMENT (motion correction)
    %==================================================================

    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'run1run2files';
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {
                                                                         cellstr(func_run1)
                                                                         cellstr(func_run2)
                                                                         }';
    matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep('Named File Selector: run1run2files(1) - Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{2}.spm.spatial.realign.estwrite.data{2}(1) = cfg_dep('Named File Selector: run1run2files(2) - Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{2}));
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 2;
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = '';
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [2 1];
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 4;
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask = 1;
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

    %==================================================================
    % STEP 2: SLICE TIMING CORRECTION
    %==================================================================
    matlabbatch{3}.spm.temporal.st.scans{1}(1) = cfg_dep('Realign: Estimate & Reslice: Resliced Images (Sess 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','rfiles'));
    matlabbatch{3}.spm.temporal.st.scans{2}(1) = cfg_dep('Realign: Estimate & Reslice: Resliced Images (Sess 2)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{2}, '.','rfiles'));
    matlabbatch{3}.spm.temporal.st.nslices = 33;
    matlabbatch{3}.spm.temporal.st.tr = 2;
    matlabbatch{3}.spm.temporal.st.ta = 1.93939393939394;
    matlabbatch{3}.spm.temporal.st.so = [1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32];
    matlabbatch{3}.spm.temporal.st.refslice = 17;
    matlabbatch{3}.spm.temporal.st.prefix = 'a';

    %==================================================================
    % STEP 3: COREGISTRATION (align mean functional to anatomical)
    %==================================================================
    matlabbatch{4}.spm.spatial.coreg.estwrite.ref(1) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
    matlabbatch{4}.spm.spatial.coreg.estwrite.source = cellstr(anat);
    matlabbatch{4}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{4}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{4}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{4}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{4}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{4}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{4}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{4}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{4}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';

    %==================================================================
    % STEP 4: SEGMENTATION (creates deformation fields)
    %==================================================================
    matlabbatch{5}.spm.spatial.preproc.channel.vols(1) = cfg_dep('Coregister: Estimate & Reslice: Coregistered Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
    matlabbatch{5}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{5}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{5}.spm.spatial.preproc.channel.write = [0 1];
    
    matlabbatch{5}.spm.spatial.preproc.tissue(1).tpm = {[SPM_dir '/tpm/TPM.nii,1']};
    matlabbatch{5}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{5}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(2).tpm = {[SPM_dir '/tpm/TPM.nii,2']};
    matlabbatch{5}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{5}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(3).tpm = {[SPM_dir '/tpm/TPM.nii,3']};
    matlabbatch{5}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{5}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(4).tpm = {[SPM_dir '/tpm/TPM.nii,4']};
    matlabbatch{5}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{5}.spm.spatial.preproc.tissue(4).native = [1 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(5).tpm = {[SPM_dir '/tpm/TPM.nii,5']};
    matlabbatch{5}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{5}.spm.spatial.preproc.tissue(5).native = [1 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(6).tpm = {[SPM_dir '/tpm/TPM.nii,6']};
    matlabbatch{5}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{5}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{5}.spm.spatial.preproc.tissue(6).warped = [0 0];
    matlabbatch{5}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{5}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{5}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{5}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{5}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{5}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{5}.spm.spatial.preproc.warp.write = [0 1];
    matlabbatch{5}.spm.spatial.preproc.warp.vox = NaN;
    matlabbatch{5}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                  NaN NaN NaN];

    %==================================================================
    % STEP 5: NORMALIZATION, Smoothing
    %==================================================================
    matlabbatch{6}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
    matlabbatch{6}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{6}.spm.spatial.normalise.write.subj.resample(2) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 2)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{2}, '.','files'));
    matlabbatch{6}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                              78 76 85];
    matlabbatch{6}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
    matlabbatch{6}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{6}.spm.spatial.normalise.write.woptions.prefix = 'w';
    matlabbatch{7}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{7}.spm.spatial.smooth.fwhm = [8 8 8];
    matlabbatch{7}.spm.spatial.smooth.dtype = 0;
    matlabbatch{7}.spm.spatial.smooth.im = 0;
    matlabbatch{7}.spm.spatial.smooth.prefix = 's';

    %==================================================================
    % STEP 6: split
    %==================================================================
    matlabbatch{8}.cfg_basicio.file_dir.file_ops.cfg_file_split.name = 'run1run2FileSplit';
    matlabbatch{8}.cfg_basicio.file_dir.file_ops.cfg_file_split.files(1) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{8}.cfg_basicio.file_dir.file_ops.cfg_file_split.index = {
                                                                         1
                                                                         2
                                                                         }';

    %==================================================================
    % RUN THE BATCH
    %==================================================================
    spm_jobman('run',matlabbatch) % execute the batch
    disp(['Completed preprocessing for ', subjects{i}]) % add a print statement telling you which subject has been processed
    
    clear matlabbatch % clear matlabbatch
    cd(startDir);
end