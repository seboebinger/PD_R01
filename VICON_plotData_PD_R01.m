function VICON_plotData_PD_R01(varargin)
p = inputParser;
addOptional(p,'srcDir',[]);
addOptional(p,'srcFile',[]);
% addOptional(p,'dataTable',[]);
addOptional(p,'figFontSize',6);
addOptional(p,'textFontSize',6);
addOptional(p,'labelFontSize',12);
addOptional(p,'labelFontWeight','bold');
addOptional(p,'XLim',[-1 10]);
addOptional(p,'EMGYLim',[0 3]);
addOptional(p,'COMPosminusLVDTYLim',[-10 10]);
addOptional(p,'COMVeloYLim',[-15 15]);
addOptional(p,'COMAccelYLim',[-0.4 0.4]);
addOptional(p,'FzYLim',[-10 800]);
addOptional(p,'LVDTYLim',[-10 10]);

parse(p,varargin{:});

%% If function called w/ no file specified, have user specify file
if ~isempty(p.Results.srcFile)
	srcFile = p.Results.srcFile;
	loadedData = load(srcFile);
else
	[srcFile,srcPath] = uigetfile('*.mat', 'Select Interpolated Data File');
	loadedData = load(srcPath+string(srcFile));
end

if isfield(loadedData, "dataTable")
    dataTable = loadedData.dataTable; clear loadedData
else
    error("The file %s does not contain a variable named 'dataTable'.", srcFile);
end

%% Set  axis limits 
YL_EMG = p.Results.EMGYLim;
YL_COM_d = p.Results.COMPosminusLVDTYLim;
YL_CoM_v = p.Results.COMVeloYLim;
YL_Accel = p.Results.COMAccelYLim;
YL_Fz = p.Results.FzYLim;
YL_LVDT = p.Results.LVDTYLim;
XL = p.Results.XLim;

%% Create time vectors and trial indexes
ind_psi = find(contains(dataTable.trialname,"psi")); % two perturbation trials index
ind_trial = find(contains(dataTable.trialname,"trial")); % single perturbation trials index

atime = dataTable.atime(1,:); 
mtime = dataTable.mtime(1,:);

%% plot double perturbation trials (psi)
% Pert Kinematics
[ax_pertKin,ind_selected_pertKin] = plot_vars(atime, ...
    {'Accels_X','Accels_Y','Velocity_X','Velocity_Y','LVDT_X','LVDT_Y'}, ...
    ind_psi, dataTable, 3, 2);

% EMG
% insert figure code here - need to make modular based off of variable names in dataTable (other sections are hard-coded

% CoM Kinematics
% insert figure code here
% variables to be plotted - COMPosminusLVDT_X COMPosminusLVDT_Y COMVelo_X COMVelo_Y COMAccel_X COMAccel_Y

% Ground Reaction Forces
% insert figure code here
% variables to be plotted - Left_Fz Right_Fz 

%% plot single perturbation trials (ind_trial)
% Pert Kinematics


% EMG
% insert figure code here - need to make modular based off of variable names in dataTable (other sections are hard-coded

% CoM Kinematics
% insert figure code here
% variables to be plotted - COMPosminusLVDT_X COMPosminusLVDT_Y COMVelo_X COMVelo_Y COMAccel_X COMAccel_Y

% Ground Reaction Forces
% insert figure code here
% variables to be plotted - Left_Fz Right_Fz 
%% Save all figures in single PDF file 
% ****!!!! need to build
saveDir = string(srcPath) + string(extractBefore(srcFile,'.mat')); % Save path and name

% exportgraphics(ax,'myplots.pdf','Append',true) % function used to export to single pdf (copied from matlab helper)

%% supporting functions
function [ax,ind_selected] = plot_vars(time, plotVars, ind, dataTable, m, n)
% plot_vars: Utility to modularly plot specified variables from a data table
%
% Inputs:
%   - time: time vector (same length as data row)
%   - plotVars: cell array of variable names to plot (strings)
%   - ind: index vector of rows (trials) to plot
%   - dataTable: the table containing time-series data
%   - m, n: number of rows (m) and columns (n) of subplot grid
%
% Output:
%   - ax: array of axes handles for linked axis control
%
% Example usage:
%   ax = plot_vars(atime,{'Accels_X','Accels_Y','Velocity_X','Velocity_Y',...
%           'LVDT_X','LVDT_Y'}, ind_trial, dataTable, 3, 2)
figure; set(gcf,'WindowStyle','docked')
ax = gobjects(1, length(plotVars)); % preallocate axes handles
ind_selected = [];
for k = 1:length(plotVars)
    [i_row, j_col] = ind2sub([m, n], k); % convert linear index to subplot grid
    ax(k) = plotij(m, n, i_row, j_col); % use custom subplot
    hold on
    varName = plotVars{k};
    for i = 1:length(ind)
        plot_tag(time, dataTable.(varName)(ind(i), :), dataTable.trialname(ind(i)), 'LineWidth', 1.5);
    end
    
    % Auto-label title based on suffix (X or Y)
    if endsWith(varName, '_X')
        title(ax(k), 'X');
    elseif endsWith(varName, '_Y')
        title(ax(k), 'Y');
    else
        title(ax(k), varName);
    end
end

end

end

