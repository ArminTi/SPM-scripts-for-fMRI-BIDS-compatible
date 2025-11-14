function ROI_data = Second_level_analysis_ROI_based(ROI, spm_files)
% Second_level_analysis_ROI_based: Computes mean ROI data for each SPM file and creates a bar plot for comparison.
% The function takes two arguments: ROI (mask), and spm_files (cell array of SPM.mat file paths).
% Example use: ROI_data = Second_level_analysis_ROI_based('dACC_mask.nii', {'/path/to/SPM1.mat', '/path/to/SPM2.mat'})
%
% Created by Andrew Jahn, modified by Armin Toghi for multiple SPM files and comparison plotting.

num_files = length(spm_files); % Number of SPM files
ROI_data = [];  % Initialize an empty matrix to store ROI data for all SPM files

% Loop over each SPM file
for i = 1:num_files
    % Load the current SPM file
    load(spm_files{i});
    Contrast = SPM.xY.P;  % Extract the contrast data
    num_subjects = size(Contrast, 1); 
    % Read the ROI mask and extract coordinates
    Y = spm_read_vols(spm_vol(ROI),1);
    indx = find(Y > 0);
    [x, y, z] = ind2sub(size(Y), indx);
    XYZ = [x, y, z]';
    
    % Get data for the contrast and calculate the ROI data for each subject
    current_ROI_data = nanmean(spm_get_data(Contrast, XYZ),2);
    
    % Store the data for this SPM file in the ROI_data matrix
    ROI_data(:,i) = current_ROI_data;
end

% Calculate the mean and standard deviation across subjects for each contrast
mean_ROI_data = mean(ROI_data, 1); % Mean for each contrast (SPM file)
std_ROI_data = std(ROI_data, 0, 1); % Standard deviation for each contrast (SPM file)

%Create a bar plot with error bars
figure;
bar(mean_ROI_data); % Bar plot for the mean ROI data
hold on;
errorbar(1:num_files, mean_ROI_data, std_ROI_data, 'k', 'LineStyle', 'none'); % Add error bars

% Scatter plot for individual data points
x_pos = repmat(1:num_files, num_subjects, 1); 
x_pos = x_pos(:);  % Flatten the matrix to a vector
scatter(x_pos, ROI_data(:), 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
xlabel('Contrasts');
ylabel('BOLD signal');
title('ROI Data Across Contrasts');
x_labels = cell(1, num_files);
for i = 1:num_files
    x_labels{i} = sprintf('Contrast_%d', i);  
end
set(gca, 'xtick', 1:num_files, 'xticklabel', x_labels);
xtickangle(45); 
hold off;

end
