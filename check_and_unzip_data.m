function check_and_unzip_data(root_directory, subjects)
%==========================================================================
% check_and_unzip_data(root_directory, subjects)
%==========================================================================
% Checks whether .nii files exist for each subject in /func and /anat
% directories. If only .nii.gz files exist, they are automatically unzipped.
%
% INPUTS:
%   root_directory  - path to main directory containing subject folders
%   subjects        - cell array of subject IDs, e.g.:
%                     {'sub-01', 'sub-02', 'sub-03'}
%
% OUTPUT:
%   Unzips .nii.gz files if corresponding .nii files are missing.
%
% Example:
%   subs = {'sub-01','sub-02','sub-03'};
%   check_and_unzip_data('D:...\Face_Object', subs)
%
% Armin Toghi Nov 14 2025
%==========================================================================

% Define which directories to check for each subject
dirs_to_check = {'anat', 'func'};

for s = 1:length(subjects)
    subjectID = subjects{s};
    fprintf('\n==============================\n');
    fprintf('Checking subject: %s\n', subjectID);
    fprintf('==============================\n');

    for d = 1:length(dirs_to_check)
        currentDir = dirs_to_check{d};
        subjPath = fullfile(root_directory, subjectID, currentDir);

        if ~isfolder(subjPath)
            warning('Skipping %s: %s directory not found.', subjectID, currentDir);
            continue;
        end

        fprintf('\n→ Checking %s directory...\n', currentDir);

        % List all .nii.gz files
        gzFiles = dir(fullfile(subjPath, '*.nii.gz'));

        if isempty(gzFiles)
            disp('   No compressed (.nii.gz) files found.');
            continue;
        end

        % Loop through .gz files
        for g = 1:length(gzFiles)
            gzFilePath = fullfile(subjPath, gzFiles(g).name);
            niiFilePath = erase(gzFilePath, '.gz'); % expected unzipped name

            if exist(niiFilePath, 'file') == 2
                fprintf('   ✓ %s already unzipped.\n', gzFiles(g).name);
            else
                fprintf('   ↻ Unzipping %s ...\n', gzFiles(g).name);
                try
                    gunzip(gzFilePath, subjPath);
                    fprintf('     → Unzipped successfully.\n');
                catch ME
                    warning('   Failed to unzip %s: %s', gzFiles(g).name, ME.message);
                end
            end
        end
    end
end

fprintf('\nAll subjects checked.\n');
end
