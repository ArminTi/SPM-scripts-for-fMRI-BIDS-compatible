function qc_preview_subjects(root, subjects, runs)
% qc_preview_subjects
% -------------------------------------------------------------------------
% Purpose: Quick manual QC of BIDS-like data per subject.
%   - Finds T1w anatomical and functional runs in <root>/sub-XX/{anat,func}
%   - Displays T1w + mean functional in SPM OrthViews (check alignment)
%   - Plots motion parameters if rp_*.txt is present
%
% Inputs:
%   root     : char path to study root containing sub-XX folders
%   subjects : cellstr of subject IDs, e.g. {'sub-01','sub-02'}
%   runs     : numeric vector of run indices, e.g. [1 2]
%
% Requirements:
%   - SPM12 on path (spm, spm_select, spm_vol available)
%   - Functional files named like:
%       *anyprefix*_ses-mri_task-facerecognition_run-01_bold.nii (or run-1)
%   - Anatomy named like:
%       *T1w.nii (with or without ses-mri segment in name)
%
% Usage:
%   qc_preview_subjects('D:\Project', {'sub-01','sub-02'}, [1 2])
%
% Notes:
%   - Mean functional is auto-detected if a file named 'mean*.nii' exists
%     in the func folder; otherwise it is computed (subsampling by 5 for speed).
%   - Close SPM graphics between subjects to keep things tidy.
%
% Armin Toghi 12 Nov 2025
% -------------------------------------------------------------------------

if nargin < 3 || isempty(runs), runs = 1; end
spm('Defaults','fMRI'); spm_jobman('initcfg');

for s = 1:numel(subjects)
    subj     = subjects{s};
    anat_dir = fullfile(root, subj, 'anat');
    func_dir = fullfile(root, subj, 'func');

    fprintf('\n===== QC: %s =====\n', subj);

    if ~exist(func_dir,'dir')
        warning('Missing func dir for %s: %s', subj, func_dir);
        continue
    end
    if ~exist(anat_dir,'dir')
        warning('Missing anat dir for %s: %s', subj, anat_dir);
        continue
    end

    % --- Find anatomical T1w (robust to prefixes / ses tag) --------------
    anat = spm_select('FPList', anat_dir, '^msub-.*_T1w\.nii$');
    if isempty(anat)
        warning('T1w not found for %s in %s', subj, anat_dir);
        continue
    end
    anat = deblank(anat(1,:)); % first match

    % --- For each run: find functional series, mean image, motion --------
    for r = runs
        % Accept run-01 or run-1 with any preprocessing prefixes
        patt1 = sprintf('^.*_ses-mri_task-facerecognition_run-0?%d_bold\\.nii$', r);
        vols  = spm_select('ExtFPList', func_dir, patt1, Inf);
        if isempty(vols)
            warning('Func not found: %s run %d in %s', subj, r, func_dir);
            continue
        end
        fprintf('Found functional (%d vols): run %d\n', size(vols,1), r);

        % Try to find an existing mean functional
        meanFunc = spm_select('FPList', func_dir, '^mean.*\.nii$');
        if ~isempty(meanFunc)
            meanFunc = deblank(meanFunc(1,:));
        else
            % Compute a quick mean functional (time subsample = every 5th vol)
            meanFunc = fullfile(func_dir, sprintf('qc_mean_run%02d.nii', r));
            try
                make_quick_mean(vols, meanFunc, 5);
                fprintf('Created %s\n', meanFunc);
            catch ME
                warning('Could not compute mean functional: %s', ME.message);
                meanFunc = deblank(vols(1,:)); % fallback: first volume
            end
        end

        % --- Show SPM orthviews: Anat + MeanFunc -------------------------
        spm_figure('GetWin','Graphics'); clf; drawnow;
        try
            spm_check_registration(char(anat, meanFunc));
            spm_orthviews('Reposition', spm_affine_transform([0 0 0], spm_vol(anat)));
        catch
            % If spm_check_registration not available for any reason:
            spm_image('Display', anat); spm_orthviews('AddColouredImage',1,meanFunc,[1 0 0]);
        end
        annotation('textbox',[0.01 0.94 0.6 0.05], 'String', ...
            sprintf('%s  |  run %02d', subj, r), 'EdgeColor','none','FontWeight','bold');

        % --- Plot motion if present --------------------------------------
        rp = spm_select('FPList', func_dir, sprintf('^rp_.*run-0?%d.*\\.txt$', r));
        if isempty(rp)
            % try generic rp_*.txt
            rp = spm_select('FPList', func_dir, '^rp_.*\.txt$');
        end
        if ~isempty(rp)
            try
                R = load(deblank(rp(1,:)));
                figure('Name',sprintf('%s run %02d | motion',subj,r), 'Color','w');
                t = (1:size(R,1))';
                subplot(2,1,1);
                plot(t, R(:,1:3)); xlabel('Frame'); ylabel('Trans (mm)');
                legend({'X','Y','Z'}, 'Location','best'); title('Translations');
                subplot(2,1,2);
                plot(t, R(:,4:6)); xlabel('Frame'); ylabel('Rot (rad)');
                legend({'Pitch','Roll','Yaw'}, 'Location','best'); title('Rotations');
            catch ME
                warning('Could not plot motion for %s run %d: %s', subj, r, ME.message);
            end
        else
            fprintf('No motion file (rp_*.txt) found for run %d.\n', r);
        end

        % Pause so you can inspect; press any key to continue to next run
        fprintf('Inspect the SPM window; press any key to continue...\n');
        pause;
        close(findobj('Type','figure','-not','Name','Graphics')); % keep SPM Graphics
    end

    % Clean up SPM Graphics for next subject
    spm_figure('GetWin','Graphics'); clf; drawnow;
end

end

% ----- helper: quick temporal mean (subsampled) --------------------------
function make_quick_mean(volList, outFile, step)
    if nargin < 3 || isempty(step), step = 5; end
    V = spm_vol(volList);
    idx = 1:step:numel(V);
    [Y, ~] = spm_read_vols(V(idx(1)));
    acc = zeros(size(Y), 'like', Y);
    n   = 0;
    for ii = idx
        [Y, ~] = spm_read_vols(V(ii));
        acc = acc + Y;
        n   = n + 1;
    end
    acc = acc / max(n,1);

    Vo        = V(1);
    Vo.fname  = outFile;
    Vo.dt     = [16 0];  % float32
    spm_write_vol(Vo, acc);
end
