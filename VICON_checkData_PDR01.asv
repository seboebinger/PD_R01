function VICON_checkData_PDR01(varargin)
% This function calls interpolateRecordedData.m and plotRecordedData.m 
% for each subject 
set(0,'DefaultAxesNextPlot','add')
set(0,'DefaultFigureColor',[1 1 1])
set(0,'DefaultFigureClipping','off')
set(0,'defaulttextinterpreter','none')

%Parser Arguments - change these (or specify as an input to the function)
p = inputParser;
addOptional(p,'EMGYLim',[0 3]);
addOptional(p,'LVDTPROBLEM',0);
addOptional(p,'reintegrateCoM',0);
addOptional(p,'StudyCode',"PD");

p.KeepUnmatched = true;
parse(p,varargin{:});

% use src to specify the folder path that contains processed matlab data output from VICON  
src = uigetdir('X:\ting\ting-data\neuromechanics-lab\ProcessedMatlabData\'); 
src = dir(src);

% remove all nonfolders (i.e. .mat, .fig, etc.)
ind_rmv = []; %index to remove rows 
for i = 1:size(src,1)
    if ~contains(src(i).name, p.Results.StudyCode) % remove rows not containing correct participant code (i.e. DS_Store)
        ind_rmv = [ind_rmv; i]; 
    elseif contains(src(i).name, "mat") | contains(src(i).name, "eps") |... %remove rows that are not participant folders
            contains(src(i).name, "fig") | contains(src(i).name, "zip") % this can probably be done more efficiently....
        ind_rmv = [ind_rmv; i]; 
    end
end
% remove rows
src(ind_rmv,:) = [];
src;
for i = 1:length(src)    
    srcDir = [src(i).folder '\' src(i).name '\off'];
    saveFileName = interpolateRecordedData_Tutorial(srcDir, src(i).folder, varargin{:}); % Make sure these match the desired cohort **
%     plotRecordedData_Tutorial('srcFile',saveFileName,'EMGYLim',p.Results.EMGYLim); % Make sure these match the desired cohort **
    close all
end

end