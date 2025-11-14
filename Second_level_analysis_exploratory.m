function Second_level_analysis_exploratory(root, subjects, contrast)
% Second_level_analysis_exploratory
% -------------------------------------------------------------------------
% Build/run a one-sample second-level SPM model for one or more contrasts.
%
% INPUTS
%   root      : char, study root containing sub-XX folders
%   subjects  : cellstr, e.g. {'sub-01','sub-02',...}
%   contrast  : cellstr or numeric vector of contrast IDs, e.g. {'con_0001'} or {'con_0001', 'con_0002'}
%
% Assumptions:
%   - First-level results in <root>/sub-XX/1stlevel/
%   - Each contrast exists for every subject (warns and skips if missing)
%
% Example:
%   Second_level_analysis_exploratory('D:\Proj', {'sub-01','sub-02'}, {'con_0001'})
%   Second_level_analysis_exploratory('D:\Proj', {'sub-01','sub-02'}, {'con_0001', 'con_0002'})
% 
% Armin Toghi Nov 14 2025

spm('Defaults','fMRI'); spm_jobman('initcfg');

% Iterate through each contrast
for c = 1:numel(contrast)
    conID = contrast{c};   % e.g., 'con_0001'
    conLabel = sanitize(conID);  % Use contrast ID as label

    fprintf('\n=== Second level for contrast: %s (%s) ===\n', conLabel, conID);

    % Gather first-level images across subjects
    scans = {}; miss = {};
    for j = 1:numel(subjects)
        sdir = fullfile(root, subjects{j}, '1stLevel');
        patt = sprintf('^%s\\.nii$', conID);  % Match contrast file using the ID
        img  = spm_select('FPList', sdir, patt);  % Select the contrast file
        if isempty(img)
            warning('Missing %s for %s in %s', conID, subjects{j}, sdir);
            miss{end+1} = subjects{j};  %#ok<AGROW>
        else
            scans{end+1,1} = deblank(img(1,:));  %#ok<AGROW>
        end
    end
    if numel(scans) < 2
        warning('Not enough images for %s (found %d). Skipping.', conID, numel(scans));
        continue
    end

    % Output directory
    outdir = fullfile(root, 'second_level', sanitize(conLabel));
    if ~exist(outdir,'dir'), mkdir(outdir); end

    % Build batch: one-sample t-test
    clear matlabbatch
    matlabbatch{1}.spm.stats.factorial_design.dir = {outdir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = scans;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;  % implicit mask
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    % Estimate the model
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep( ...
        'Factorial design specification: SPM.mat File', ...
        substruct('.','val','{}',{1},'.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;

    % Contrast at 2nd level (one-sample t: [1])
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep( ...
        'Model estimation: SPM.mat File', ...
        substruct('.','val','{}',{2},'.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name    = conLabel;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    % Results (none 0.001 or FWE 0.05) – tweak as needed
    matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep( ...
        'Contrast Manager: SPM.mat File', ...
        substruct('.','val','{}',{3},'.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{4}.spm.stats.results.conspec(1).titlestr   = conLabel;
    matlabbatch{4}.spm.stats.results.conspec(1).contrasts  = 1;
    matlabbatch{4}.spm.stats.results.conspec(1).threshdesc = 'none';
    matlabbatch{4}.spm.stats.results.conspec(1).thresh     = 0.001;
    matlabbatch{4}.spm.stats.results.conspec(1).extent     = 0;
    matlabbatch{4}.spm.stats.results.conspec(1).conjunction= 1;
    matlabbatch{4}.spm.stats.results.conspec(1).mask.none  = 1;
    matlabbatch{4}.spm.stats.results.units = 1; % voxels
    % matlabbatch{4}.spm.stats.results.export{1}.ps = true; % enable if you want .ps

    try
        spm_jobman('run', matlabbatch);
        fprintf('✔ Done: %s\n', outdir);
        if ~isempty(miss)
            fprintf('   (Missing for: %s)\n', strjoin(miss, ', '));
        end
    catch ME
        warning('✖ Failed on %s: %s', conLabel, ME.message);
    end

end
end


% ---------- sanitize function -------------------------------------------
function s = sanitize(s)
% This function ensures the contrast label is safe for use in file names
s = strrep(s,'>','gt');                % Replace '>' with 'gt'
s = regexprep(s,'[^A-Za-z0-9_\-]+','_'); % Replace non-alphanumeric characters with '_'
end
