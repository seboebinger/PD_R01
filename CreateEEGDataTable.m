function DataTable = CreateEEGDataTable(varargin)
%% Function to create EEG output measures table compatible with vicon data tables
% inputs: - None needed, see Parser Arguments for optional inputs
% Sequence of events: 1) run code (make sure eeglab path is added)
% 2) select folder that contains the data you want to create a table from. These need to be .set files.
% 3) hope that the code runs on your device
% 4) check that output data table contains all variables of interest that match what is in the EEG structure
%% Parser Arguments - change these (or change the input to the function)
p = inputParser;
% what channels in EEG data are used to update triggers
addOptional(p,'AnalysisType','Both')% Analysis type - i.e. source-based, electrode-based, or both
addOptional(p,'Num_Perts',2) % number of perturbations within each vicon trial (2 for perception)
addOptional(p,'Electrode',{'Cz','C1','C2','CPz'}) % electrode ID
addOptional(p,'Source',[1 2 3]) % source ID - !!!! Need to make sure it can handle multiple sources
addOptional(p,'target_codes',{'first','second','single'}) % trigger codes of interest for epoching
addOptional(p,'epoch_window', [-3  12]) % time window to epoch around (in s) [start_time, end_time]

% ERSP parameters - Build Later?
% addOptional(p,'ersp_winsize',256) % ersp sliding window size
% addOptional(p,'ersp_baseline',[-500 -100])% ERSP baseline window. NaN = no baseline removal
% addOptional(p,'ersp_waveletparams', [3 0.8]) % ERSP wavelet parameters

p.KeepUnmatched = true;
parse(p,varargin{:});
%% create file list to be loaded
try
    fdir = uigetdir('X:\ting\ting-data\neuromechanics-lab\EEG','Select folder that contains data');
catch
    fdir = uigetdir('C:\','Select folder that contains data');
end
files = dir(fullfile(fdir, '*.set')); % filter to ionly contain .set files

%% initialize eeglab
addpath('D:\Users\SBOEBIN\Documents\EEGLAB\eeglab2024.2.1\eeglab2024.2.1')
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% iterate across all files
DataTable = table();  % Master table for all datasets
for i = 1:size(files,1)
    %% load data
    filename = files(i).name;
    folder = files(i).folder;
    EEG = pop_loadset('filename',filename,'filepath',folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, i );
    EEG = eeg_checkset( EEG );
    
    %% Epoch dataset
    EEG = pop_epoch(EEG,...
        p.Results.target_codes,...
        p.Results.epoch_window,...
        'newname', [extractBefore(filename,'.set') '_Epoched'],...
        'epochinfo', 'yes');
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, i,'overwrite','on','gui','off');
    %% create data table
    % Initialize empty table
    DataTable_tmp = table; % participant-specific data table
    
    % Electrode-based outputs
    if strcmpi(p.Results.AnalysisType, 'Electrode') || strcmpi(p.Results.AnalysisType, 'Both')
        % Get indices of user-defined electrodes
        ind_chan = find(ismember({EEG.chanlocs.labels}, p.Results.Electrode));
        ERP = EEG.data(ind_chan, :, :);  % size: M x N x P
        [M, N, P] = size(ERP);
        ERP_perm = permute(ERP, [3, 1, 2]);  % size: P x M x N
        ERP_cell = cell(P, M);
        for p_idx = 1:P
            for m_idx = 1:M
                ERP_cell{p_idx, m_idx} = double(squeeze(ERP_perm(p_idx, m_idx, :)))';
            end
        end
        elec_labels = strcat(p.Results.Electrode, '_ERP');
        ElectrodeTable = cell2table(ERP_cell, 'VariableNames', elec_labels);
        % Append to main DataTable
        DataTable_tmp = [DataTable_tmp ElectrodeTable];
    end
    
    % Source-based outputs
    if strcmpi(p.Results.AnalysisType, 'Source') || strcmpi(p.Results.AnalysisType, 'Both')
        ICact = EEG.icaact(p.Results.Source, :, :);  % size: M x N x P
        [M, N, P] = size(ICact);
        ICact_perm = permute(ICact, [3, 1, 2]);  % size: P x M x N
        IC_cell = cell(P, M);
        for p_idx = 1:P
            for m_idx = 1:M
                IC_cell{p_idx, m_idx} = double(squeeze(ICact_perm(p_idx, m_idx, :)))';
            end
        end
        IC_labels = cellstr("IC" + string(p.Results.Source) + "_act");
        SourceTable = cell2table(IC_cell, 'VariableNames', IC_labels);
        % Append to main DataTable
        DataTable_tmp = [DataTable_tmp SourceTable];
    end
    % Add time vector (EEG.times) as a new column to the table
    time_vec = EEG.times;
    DataTable_tmp.time = repmat(time_vec, P, 1);  % replicate for each epoch
    %% Add participant and trial ID to DataTable
    % Repeat folder and filename for each epoch (P rows)
    DataTable_tmp.folder = repmat({folder}, P, 1);
    DataTable_tmp.filename = repmat({filename}, P, 1);
    % Define DA status based on filename content
    if contains(filename, 'ON', 'IgnoreCase', true)
        DA_status = repmat({'ON'}, P, 1);
    elseif contains(filename, 'OFF', 'IgnoreCase', true)
        DA_status = repmat({'OFF'}, P, 1);
    else
        DA_status = repmat({'Unknown'}, P, 1); % Optional fallback
    end
    DataTable_tmp.DA = DA_status;
    
    % Extract subject ID using regex from filename (e.g., PD001_ON.set → PD001)
    tokens = regexp(filename, '^(OA|PD)\d{3}', 'match');
    if ~isempty(tokens)
        subj_ID_val = tokens{1};
    else
        subj_ID_val = 'Unknown'; % Optional fallback
    end
    DataTable_tmp.subj_ID = repmat({subj_ID_val}, P, 1);  % Add to DataTable
    
    % Extract trial type from EEG.epoch.eventtype
    if isfield(EEG.epoch, 'eventtype')
        trial_type_raw = {EEG.epoch.eventtype};  % cell array, 1×P
        trial_type = cell(P,1);
        for ep = 1:P
            if iscell(trial_type_raw{ep})
                trial_type{ep} = trial_type_raw{ep}{1};  % extract string from nested cell
            else
                trial_type{ep} = trial_type_raw{ep};
            end
        end
        DataTable_tmp.trial_type = trial_type;
    else
        warning('EEG.epoch.eventtype not found. Filling trial_type with NaNs');
        DataTable_tmp.trial_type = repmat({NaN}, P, 1);
    end
    %% perform time-frequency analysis - Build Later?
    %     figure;
    %     [ersp, itc, powbase, times_ersp, frequencies] = pop_newtimef(EEG, 1, electrode, [-1000  1998], ersp_waveletparams,...
    %         'topovec', electrode, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', [filename ' Cz'],...
    %         'baseline', ersp_baseline,'winsize', ersp_winsize, 'plotphase', 'off', 'padratio', 1);
    %     % break into frequency bands
    %     ind_theta = frequencies >= 4 & frequencies < 8;
    %     ind_alpha = frequencies >= 8 & frequencies < 13;
    %     ind_beta =  frequencies >= 13 & frequencies < 30;
    %     ind_gamma = frequencies > 30;
    %
    %     theta_ersp = [theta_ersp; mean(ersp(ind_theta,:),1)]; % change so they don't increase size every loop
    %     alpha_ersp = [alpha_ersp; mean(ersp(ind_alpha,:),1)];
    %     beta_ersp = [beta_ersp; mean(ersp(ind_beta,:),1)];
    %     gamma_ersp = [gamma_ersp; mean(ersp(ind_gamma,:),1)];
    %     time_ersp = [time_ersp; times_ersp];
    %% append data tables
    DataTable = [DataTable; DataTable_tmp];
end
%% save eeg table
% Reorder DataTable so that filename, trial_type, and folder are first
varNames = DataTable.Properties.VariableNames;
priorityVars = {'subj_ID', 'trial_type', 'DA'};
remainingVars = setdiff(varNames, priorityVars, 'stable');
DataTable = DataTable(:, [priorityVars, remainingVars]);

try
    savedir = uigetdir('X:\ting\ting-data\neuromechanics-lab\EEG','Select where to save data table');
catch
    savedir = uigetdir('C:\','Select where to save data table');
end
if savedir ~= 0 % save only if savedir is specified by uigetdir()
    save([savedir '\' folder '_' date '.mat'],'DataTable')
end