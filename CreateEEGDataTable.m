%% Script to create EEG output measures table compatible with vicon data tables
clear; close all 
%% User input
electrode = 13; % need to make generic
ersp_winsize = 256; % ersp sliding window size
ersp_baseline = [-500 -100]; % NaN for no baseline removal (i.e. can calculate prestim beta); % baseline = [-500 -100];
ersp_waveletparams = [3 0.8];
ersp_max = 7; % <- not currently used

%% initialize output variables
beta_ersp = []; gamma_ersp = []; theta_ersp = []; alpha_ersp = [];
time_erp = []; time_ersp = []; mag = []; direc = []; ID = [];

%% create file list to be loaded
fdir = uigetdir('X:\ting\ting-data\neuromechanics-lab\EEG'); 
% figdir = 'X:\ting\shared_ting\Scott\HOA_PD EEG Data\Condition Epoched\ERSPs\'; % folder path where figures will be saved
savefigopt = false;
files = dir(fullfile(fdir, '*.set'));

%% initialize eeglab
addpath('D:\Users\SBOEBIN\Documents\MATLAB\eeglab2021.0\')
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% iterate across all files
for i = 1:size(files,1)
    %% load data
    filename = files(i).name;
    folder = files(i).folder;
    EEG = pop_loadset('filename',filename,'filepath',folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, i );
    EEG = eeg_checkset( EEG );
    
    %% perform time-frequency analysis
    figure;
    [ersp, itc, powbase, times_ersp, frequencies] = pop_newtimef(EEG, 1, electrode, [-1000  1998], ersp_waveletparams,...
        'topovec', electrode, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', [filename ' Cz'],...
        'baseline', ersp_baseline,'winsize', ersp_winsize, 'plotphase', 'off', 'padratio', 1);
    if savefigopt
        saveas(gcf,[figdir filename(1:end-4) '_ERSP.fig'])
        saveas(gcf,[figdir filename(1:end-4) '_ERSP.jpg'])
    end
    
    %% store output measures
    %ERP: needs to trial average (don't for ERSP)
    temp_Cz = EEG.data(13,:,:); temp_Cz = squeeze(temp_Cz);
    Cz = [Cz; mean(temp_Cz,2)'];
    time_erp = [time_erp; EEG.times];
    % ERSP
    % create frequency indexes
    ind_theta = find(frequencies >= 4 & frequencies < 8);
    ind_alpha = find(frequencies >= 8 & frequencies < 13);
    ind_beta =  find(frequencies >= 13 & frequencies < 30);
    ind_gamma = find(frequencies > 30);
    
    theta_ersp = [theta_ersp; mean(ersp(ind_theta,:),1)];
    alpha_ersp = [alpha_ersp; mean(ersp(ind_alpha,:),1)];
    beta_ersp = [beta_ersp; mean(ersp(ind_beta,:),1)];
    gamma_ersp = [gamma_ersp; mean(ersp(ind_gamma,:),1)];
    time_ersp = [time_ersp; times_ersp];
    
    % create condition index from file name to ensure proper concatination w/ createfitsData.m output
    temp = extractAfter(filename,'UpdatedEvents_');
    mag = [mag; str2double(extractBetween(temp, '0_', '.set'))]; clear temp
    direc = [direc; str2double(extractBetween(filename, 'UpdatedEvents_', '_'))];
    ID = [ID; string(extractBefore(filename,'_brain'))];
    disp(filename)
    close all
    
end
%% Concatinate data tables
% create data table of EEG output measures
T = table(ID, mag, direc, Cz,  beta_ersp,  gamma_ersp,  theta_ersp,  alpha_ersp, time_erp,  time_ersp);
% save eeg table 
save(['D:\Users\SBOEBIN\Documents\MATLAB\Post creatfitsData Output\HOA_PD_DataTable_EEG_' date '.mat'],'T')