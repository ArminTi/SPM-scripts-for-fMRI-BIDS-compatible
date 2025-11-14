function extract_onset_duration(root, subjects)
%==========================================================================
% extract_onset_duration(func_directory, subjects)
%==========================================================================
% Converts BIDS event timing files (.tsv) into two-column onset-duration
% text files compatible with SPM.
%
% INPUTS:
%   root  - path to main directory containing subject folders
%   subjects        - cell array of subject IDs, e.g.:
%                     {'sub-01', 'sub-02', 'sub-03'}
%
% OUTPUT:
%   Saves text files (onset, duration) for each run and trial type
%   inside each subject's /func folder.
%
% Example:
%   sub = {'sub-01','sub-02','sub-03'};
%   extract_onset_duration('/Users/.../Face_Object', sub)
%
% Armin Toghi 12 Nov 2025
%
%==========================================================================

% Store current directory to return later
startDir = pwd;

for s = 1:length(subjects)
    subjectID = subjects{s};
    subjPath = fullfile(root, subjectID, 'func');

    if ~isfolder(subjPath)
        warning('Skipping %s: func directory not found.', subjectID);
        continue;
    end

    cd(subjPath);
    fprintf('Processing %s ...\n', subjectID);

    % ---------------------------------------------------------------
    % Process both runs (01, 02)
    % ---------------------------------------------------------------
    for run = 1:2
        runStr = sprintf('run-%02d', run);
        fileName = sprintf('%s_ses-mri_task-facerecognition_%s_events.tsv', subjectID, runStr);

        if ~isfile(fileName)
            warning('File not found: %s', fileName);
            continue;
        end

        % Read TSV file
        onsetData = tdfread(fileName, '\t');
        onsetData.trial_type = string(onsetData.stim_type);

        % Initialize condition arrays
        Famous = [];
        Unfamiliar = [];
        Scrambled = [];
        Rest = [];

        % Loop through each trial
        for i = 1:length(onsetData.onset)
            ttype = strtrim(onsetData.trial_type(i,:));
            switch ttype
                case 'FAMOUS'
                    Famous = [Famous; onsetData.onset(i,:) onsetData.duration(i,:)];
                case 'UNFAMILIAR'
                    Unfamiliar = [Unfamiliar; onsetData.onset(i,:) onsetData.duration(i,:)];
                case 'SCRAMBLED'
                    Scrambled = [Scrambled; onsetData.onset(i,:) onsetData.duration(i,:)];
                case 'n/a'
                    Rest = [Rest; onsetData.onset(i,:) onsetData.duration(i,:)];
            end
        end

        % Save outputs as .txt
        save(sprintf('%s_Famous.txt', runStr), 'Famous', '-ASCII');
        save(sprintf('%s_Unfamiliar.txt', runStr), 'Unfamiliar', '-ASCII');
        save(sprintf('%s_Scrambled.txt', runStr), 'Scrambled', '-ASCII');
        save(sprintf('%s_Rest.txt', runStr), 'Rest', '-ASCII');
    end

    cd(startDir); % return to original directory
end

fprintf('All subjects processed successfully.\n');
cd(startDir);
end
