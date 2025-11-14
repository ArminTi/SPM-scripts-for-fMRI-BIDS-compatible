function fMRI_first_level(root, subjects)
% fMRI_first_level
% -------------------------------------------------------------------------
% Purpose: Build & run SPM12 first-level model
%          with two runs per subject (run-01 & run-02).
%
% Inputs:
%   root      - char path to the study folder that contains sub-XX
%   subjects  - cell array of subject IDs as strings, e.g. {'sub-01','sub-02'}
%
% Requirements:
%   - Preprocessed 4D NIfTI per run in: <root>/sub-XX/func/
%     Filenames start with SPM prefixes (e.g., s, wa, r, swar...) and end with:
%       *_ses-mri_task-facerecognition_run-01_bold.nii
%       *_ses-mri_task-facerecognition_run-02_bold.nii
%   - Timing text files in the same func folder:
%       run-01_Famous.txt,      run-02_Famous.txt
%       run-01_Unfamiliar.txt,  run-02_Unfamiliar.txt
%       run-01_Scrambled.txt,   run-02_Scrambled.txt
%       run-01_Rest.txt,        run-02_Rest.txt
%     (two columns: onset duration)
%
% Usage example:
%   first_level_analysis('D:\Project', {'sub-01','sub-02','sub-03'})
%
% Notes:
%   - Outputs are written to <root>/sub-XX/1stlevel
%   - Adjust TR, microtime (fmri_t, fmri_t0), and contrasts to your design.
% 
% Armin Toghi 12 Nov 2025
% -------------------------------------------------------------------------

for i = 1:numel(subjects)
    disp(['Starting processing for ', subjects{i}])
    func_dir = fullfile(root, subjects{i}, 'func');
    main_dir = fullfile(root, subjects{i});

    func_run1 = spm_select('ExtFPList', func_dir, '^swarsub-*.*_ses-mri_task-facerecognition_run-01_bold.nii$', NaN);
    func_run2 = spm_select('ExtFPList', func_dir, '^swarsub-*.*_ses-mri_task-facerecognition_run-02_bold.nii$', NaN);

    
    mkdir(fullfile(main_dir, '1stlevel'));
    cd(func_dir)


    %==================================================================
    %  FIRST LEVEL MODEL
    %==================================================================
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[main_dir '\1stLevel']};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans(1) = cellstr(func_run1);
    
    
    data_famous_run1 = load([func_dir '\run-01_Famous.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).name = 'Famous';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).onset = data_famous_run1(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).duration =  data_famous_run1(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).orth = 1;

    data_Unfamiliar_run1 = load([func_dir '\run-01_Unfamiliar.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).name = 'Unfamiliar';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).onset = data_Unfamiliar_run1(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).duration = data_Unfamiliar_run1(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).orth = 1;

    data_Scramble_run1 = load([func_dir '\run-01_Scrambled.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).name = 'Scramble';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).onset = data_Scramble_run1(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).duration = data_Scramble_run1(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).orth = 1;

    data_rest_run1 = load([func_dir '\run-01_Rest.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).name = 'Rest';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).onset = data_rest_run1(1:end-1,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).duration = data_rest_run1(1:end-1,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(4).orth = 1;

    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;

    % now repeat for run 2
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans(1) = cellstr(func_run2);
    
    data_famous_run2 = load([func_dir '\run-02_Famous.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).name = 'Famous';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).onset = data_famous_run2(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).duration = data_famous_run2(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).orth = 1;

    data_Unfamiliar_run2 = load([func_dir '\run-02_Unfamiliar.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).name = 'Unfamiliar';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).onset = data_Unfamiliar_run2(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).duration = data_Unfamiliar_run2(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).orth = 1;

    data_Scramble_run2 = load([func_dir '\run-02_Scrambled.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).name = 'Scramble';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).onset = data_Scramble_run2(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).duration = data_Scramble_run2(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).orth = 1;

    data_rest_run2 = load([func_dir '\run-02_Rest.txt']);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).name = 'Rest';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).onset = data_rest_run2(1:end-1,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).duration = data_rest_run2(1:end-1,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(4).orth = 1;

    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 1;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Famous > Unfamiliar';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 -1 0 0];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Faces > scramble';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [1 1 -1 0];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'Faces > rest';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [1  1 0 -1];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'Unfamiliar > scramble';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 1 -1 0];
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'scramble > rest';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [0 0 1 -1];
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'Famous';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [1 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'Unfamiliar';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 1 0 0];
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'scramble';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = [0 0 1 0];
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.delete = 0;

   

    % --- Run -------------------------------------------------------------
    spm_jobman('run',matlabbatch) 
    disp(['Completed preprocessing for ', subjects{i}]) 
    clear matlabbatch
end