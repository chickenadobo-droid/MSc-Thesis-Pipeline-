%% ========================================================================
% SCRIPT FOR RECALCULATING MUA Z-SCORES BY ARENATYPE AND SESSION
% =========================================================================
% PURPOSE:
% This script recalculates z-scores for MUA_mean_Hz_replicated and stores
% them in the MUA_Z_New column. Z-scores are calculated separately for each
% unique combination of SessionName and ArenaType.
%
% RATIONALE:
% - Each session represents a new day
% - Some sessions are "mixed" with exposure to multiple arena types
% - Z-scores should be calculated within each session-arena combination
% - Timepoints where the animal is not in any arena (empty ArenaType)
%   should be excluded from z-score calculations
%
% =========================================================================

%% PHASE 1: SETUP AND LOAD DATA
clc;
clear all;
close all;

disp('PHASE 1: Loading data...');

% --- Define the path to your data file ---
% Modify this path to match your actual file location
data_path = 'Final_Table_for_GLM_cleanMUA_NewZ.mat';

% --- Load the table ---
load(data_path);
disp(['Loaded table with ', num2str(height(Final_GLM_Table)), ' rows']);

%% PHASE 2: IDENTIFY VALID DATA AND GROUPING STRUCTURE
disp('PHASE 2: Analyzing data structure...');

% --- Identify rows where ArenaType is not empty (animal is in an arena) ---
valid_arena_mask = ~cellfun(@isempty, Final_GLM_Table.ArenaType);
disp(['Found ', num2str(sum(valid_arena_mask)), ' rows with valid ArenaType']);
disp(['Excluding ', num2str(sum(~valid_arena_mask)), ' rows where animal is not in any arena']);

% --- Create a combined grouping variable for SessionName and ArenaType ---
% Only for valid arena rows
session_arena_groups = cell(height(Final_GLM_Table), 1);
session_arena_groups(valid_arena_mask) = strcat(...
    Final_GLM_Table.SessionName(valid_arena_mask), ...
    '_', ...
    Final_GLM_Table.ArenaType(valid_arena_mask));

% --- Find unique session-arena combinations ---
unique_groups = unique(session_arena_groups(valid_arena_mask));
disp(['Found ', num2str(length(unique_groups)), ' unique SessionName-ArenaType combinations']);

% Display first few groups as examples
disp('Example groups:');
disp(unique_groups(1:min(5, length(unique_groups))));

%% PHASE 3: CALCULATE Z-SCORES WITHIN EACH GROUP
disp('PHASE 3: Calculating z-scores for each SessionName-ArenaType group...');

% --- Initialize the MUA_Z_New column with NaN ---
Final_GLM_Table.MUA_Z_New = NaN(height(Final_GLM_Table), 1);

% --- Loop through each unique group and calculate z-scores ---
for i = 1:length(unique_groups)
    current_group = unique_groups{i};

    % Find all rows belonging to this group
    group_mask = strcmp(session_arena_groups, current_group);
    group_size = sum(group_mask);

    % Get the MUA data for this group
    mua_data = Final_GLM_Table.MUA_mean_Hz_replicated(group_mask);

    % Calculate z-scores (only if we have valid data and more than 1 point)
    if group_size > 1 && sum(~isnan(mua_data)) > 1
        % Calculate mean and std, ignoring NaN values
        group_mean = mean(mua_data, 'omitnan');
        group_std = std(mua_data, 'omitnan');

        % Calculate z-scores
        if group_std > 0  % Avoid division by zero
            z_scores = (mua_data - group_mean) / group_std;
        else
            % If std is 0, all values are the same, set z-scores to 0
            z_scores = zeros(size(mua_data));
        end

        % Assign z-scores back to the table
        Final_GLM_Table.MUA_Z_New(group_mask) = z_scores;

        if mod(i, 50) == 0  % Print progress every 50 groups
            disp(['Processed ', num2str(i), ' of ', num2str(length(unique_groups)), ' groups']);
        end
    else
        warning(['Group ', current_group, ' has insufficient data (n=', num2str(group_size), ')']);
    end
end

disp('Z-score calculation complete!');

%% PHASE 4: VALIDATION AND SUMMARY STATISTICS
disp('PHASE 4: Validating results...');

% --- Count how many z-scores were calculated ---
n_calculated = sum(~isnan(Final_GLM_Table.MUA_Z_New));
n_valid_arena = sum(valid_arena_mask);
disp(['Calculated z-scores for ', num2str(n_calculated), ' out of ', num2str(n_valid_arena), ' valid arena rows']);

% --- Display summary statistics for the new z-scores ---
disp('Summary statistics for MUA_Z_New:');
disp(['  Mean: ', num2str(mean(Final_GLM_Table.MUA_Z_New, 'omitnan'))]);
disp(['  Std: ', num2str(std(Final_GLM_Table.MUA_Z_New, 'omitnan'))]);
disp(['  Min: ', num2str(min(Final_GLM_Table.MUA_Z_New))]);
disp(['  Max: ', num2str(max(Final_GLM_Table.MUA_Z_New))]);
disp(['  Median: ', num2str(median(Final_GLM_Table.MUA_Z_New, 'omitnan'))]);

% --- Compare with original MUA_mean_Hz_replicated ---
disp(' ');
disp('Original MUA_mean_Hz_replicated statistics (for valid arena rows):');
valid_mua = Final_GLM_Table.MUA_mean_Hz_replicated(valid_arena_mask);
disp(['  Mean: ', num2str(mean(valid_mua, 'omitnan'))]);
disp(['  Std: ', num2str(std(valid_mua, 'omitnan'))]);
disp(['  Min: ', num2str(min(valid_mua))]);
disp(['  Max: ', num2str(max(valid_mua))]);

%% PHASE 5: OPTIONAL VISUALIZATION
disp('PHASE 5: Creating validation plots...');

% --- Plot 1: Distribution comparison ---
figure('Name', 'MUA Z-Score Distributions');
subplot(2, 1, 1);
histogram(Final_GLM_Table.MUA_mean_Hz_replicated(valid_arena_mask), 50);
title('Original MUA mean Hz (valid arena rows only)');
xlabel('MUA mean Hz');
ylabel('Frequency');
grid on;

subplot(2, 1, 2);
histogram(Final_GLM_Table.MUA_Z_New(valid_arena_mask), 50);
title('New Z-Scores (by Session and ArenaType)');
xlabel('Z-Score');
ylabel('Frequency');
grid on;

% --- Plot 2: Example session comparison ---
% Pick a session to visualize
example_sessions = unique(Final_GLM_Table.SessionName);
if ~isempty(example_sessions)
    example_session = example_sessions{1};
    session_mask = strcmp(Final_GLM_Table.SessionName, example_session);

    figure('Name', ['Example Session: ', example_session]);

    % Get unique arena types for this session
    session_arenas = unique(Final_GLM_Table.ArenaType(session_mask & valid_arena_mask));

    subplot(2, 1, 1);
    hold on;
    for j = 1:length(session_arenas)
        arena = session_arenas{j};
        mask = session_mask & strcmp(Final_GLM_Table.ArenaType, arena);
        plot(Final_GLM_Table.time_min(mask), Final_GLM_Table.MUA_mean_Hz_replicated(mask), '-o', 'DisplayName', arena);
    end
    xlabel('Time (min)');
    ylabel('MUA mean Hz');
    title('Original MUA by ArenaType');
    legend('Location', 'best');
    grid on;

    subplot(2, 1, 2);
    hold on;
    for j = 1:length(session_arenas)
        arena = session_arenas{j};
        mask = session_mask & strcmp(Final_GLM_Table.ArenaType, arena);
        plot(Final_GLM_Table.time_min(mask), Final_GLM_Table.MUA_Z_New(mask), '-o', 'DisplayName', arena);
    end
    xlabel('Time (min)');
    ylabel('Z-Score');
    title('New Z-Scores by ArenaType');
    legend('Location', 'best');
    grid on;
end

%% PHASE 6: SAVE THE UPDATED TABLE
disp('PHASE 6: Saving updated table...');

% --- Create a backup of the original file ---
[filepath, name, ext] = fileparts(data_path);
backup_path = fullfile(filepath, [name, '_backup_', datestr(now, 'yyyymmdd_HHMMSS'), ext]);
if isempty(filepath)
    backup_path = [name, '_backup_', datestr(now, 'yyyymmdd_HHMMSS'), ext];
end

try
    copyfile(data_path, backup_path);
    disp(['Backup created: ', backup_path]);
catch
    warning('Could not create backup file');
end

% --- Save the updated table ---
save(data_path, 'Final_GLM_Table');
disp(['Updated table saved to: ', data_path]);

%% PHASE 7: GENERATE DETAILED SUMMARY REPORT
disp(' ');
disp('========================================================================');
disp('SUMMARY REPORT');
disp('========================================================================');
disp(['Total rows in table: ', num2str(height(Final_GLM_Table))]);
disp(['Rows with valid ArenaType: ', num2str(sum(valid_arena_mask))]);
disp(['Rows with calculated z-scores: ', num2str(sum(~isnan(Final_GLM_Table.MUA_Z_New)))]);
disp(['Number of unique SessionName-ArenaType groups: ', num2str(length(unique_groups))]);
disp(' ');
disp('Group size statistics:');
group_sizes = zeros(length(unique_groups), 1);
for i = 1:length(unique_groups)
    group_sizes(i) = sum(strcmp(session_arena_groups, unique_groups{i}));
end
disp(['  Mean group size: ', num2str(mean(group_sizes))]);
disp(['  Median group size: ', num2str(median(group_sizes))]);
disp(['  Min group size: ', num2str(min(group_sizes))]);
disp(['  Max group size: ', num2str(max(group_sizes))]);
disp(' ');
disp('VALIDATION: Z-score properties (should be ~0 mean, ~1 std within each group)');
disp(['  Overall mean of MUA_Z_New: ', num2str(mean(Final_GLM_Table.MUA_Z_New, 'omitnan'))]);
disp(['  Overall std of MUA_Z_New: ', num2str(std(Final_GLM_Table.MUA_Z_New, 'omitnan'))]);
disp('========================================================================');
disp('Script completed successfully!');
