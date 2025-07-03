function VICON_checkData_PDR01(varargin)
% This function calls interpolateRecordedData.m and plotRecordedData.m
% for each participant/session folder within a study folder.
%
% Folder structure assumed:
% StudyFolder > Participant_ID### > ON or OFF > Trials.mat

% set plotting configuration to be consistent between users
set(0,'DefaultAxesNextPlot','add')
set(0,'DefaultFigureColor',[1 1 1])
set(0,'DefaultFigureClipping','off')
set(0,'defaulttextinterpreter','none')

% Parser Argument Pairs - specify as an input to the function as needed
% i.e. VICON_checkData_PDR01('EMGYLim',[0 5])
p = inputParser;
addOptional(p,'EMGYLim',[0 3]);
addOptional(p,'LVDTPROBLEM',0);
addOptional(p,'reintegrateCoM',0);
addOptional(p,'StudyCode',"PD");

p.KeepUnmatched = true;
parse(p,varargin{:});

% Add utility folder to path
addpath('X:\ting\shared_ting\Scott\PD_R01\PD_R01\Utility Functions')

% Prompt user to select the study folder
studyFolder = 'X:\ting\ting-data\neuromechanics-lab\ProcessedMatlabData\EEGStudies\PD_R01_perception';%uigetdir('X:\ting\ting-data\neuromechanics-lab\ProcessedMatlabData\EEGStudies\');
ID_folders = dir(studyFolder);

% Filter to keep only participant folders
ind_rmv = [];
for i = 1:numel(ID_folders)
    if ~ID_folders(i).isdir
        ind_rmv = [ind_rmv; i];
    elseif ~contains(ID_folders(i).name, p.Results.StudyCode) || ismember(ID_folders(i).name, {'.', '..'})
        ind_rmv = [ind_rmv; i];
    end
end
ID_folders(ind_rmv) = [];

% Loop over each participant (ID folder)
for i = 1:length(ID_folders)
    ID_folder_path = fullfile(ID_folders(i).folder, ID_folders(i).name);
    
    % Check for both all sessions
    sessionOptions = ["on", "off"];
    sessionFolders = dir(ID_folder_path);
    
    for s = 1:length(sessionOptions)
        % Try to match session folder ignoring case
        match = find(strcmpi({sessionFolders.name}, sessionOptions(s)), 1);
        
        if ~isempty(match)
            sessionPath = fullfile(ID_folder_path, sessionFolders(match).name);
            saveFileName = VICON_interpolateData_PDR01(sessionPath, studyFolder, varargin{:});
            VICON_plotData_PD_R01('srcFile', saveFileName, 'EMGYLim', p.Results.EMGYLim);
            close all
        end
    end
    
end
% remove utility folder to path
rmpath('X:\ting\shared_ting\Scott\PD_R01\PD_R01\Utility Functions')
end
