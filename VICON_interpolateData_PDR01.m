function saveFileName = VICON_interpolateData_PDR01(src, studyFolder, varargin)
% Any additional variables
p = inputParser;
addOptional(p,'srcDir',src);
addOptional(p,'staticTrialFormat','Stat*\d\d');
addOptional(p,'retroTrialFormat','Retro *\d\d');
addOptional(p,'trialNameFormat',{'psi','trial'}); % trial name format
addOptional(p,'trialNumbers',[]);
addOptional(p,'participantCodeFormat','PD\d\d\d'); % Study Code
addOptional(p,'stepForceThresholdN',10); %Force threshold for step identification
addOptional(p,'timerange',[-0.5 7]); % time range - change as needed
addOptional(p,'interpFrameRate',[]);
addOptional(p,'additionalMarkers',[]);
addOptional(p,'pertDirDataSource',"LVDT");
addOptional(p,'forceCOM',0);
p.KeepUnmatched = true;
parse(p,varargin{:});

srcDir = p.Results.srcDir;

% Used in loadTrialSub() - need to confirm that these are used correctly
timerange = p.Results.timerange; 
interpFrameRate = p.Results.interpFrameRate;
FORCECOM = p.Results.forceCOM; 

% generate file names from source directory
filenames = generatefilenames(srcDir);

% delete files that do not match the trial string specification
trialNameFormats = p.Results.trialNameFormat;
if ischar(trialNameFormats) || isstring(trialNameFormats)
    trialNameFormats = {char(trialNameFormats)}; % ensure it's a cell array
end

% Create a logical index of trials to keep
keepIdx = false(height(filenames), 1);
for k = 1:length(trialNameFormats)
    matches = ~cellfun(@isempty, regexp(filenames.trialname, trialNameFormats{k}, 'once'));
    keepIdx = keepIdx | matches;
end

filenames = filenames(keepIdx, :);

if ~isempty(p.Results.trialNumbers)
    % erase non-numeric characters
    trialNumbers = str2double(regexprep(filenames.trialname,'\D',""));
    filenames(~ismember(trialNumbers,p.Results.trialNumbers),:) = [];
end

% Load variables of interest
varNames = getVarNames_PD_R01_2025;

% add additional markers if necessary
additionalMarkerNames = expandNames3D(p.Results.additionalMarkers);
if ~isempty(p.Results.additionalMarkers)
    dataTable = names2table([varNames cellstr(additionalMarkerNames)]);
else
    dataTable = names2table(varNames);
end

% create an interpolated database
f_names = filenames.filename';
% Load single trial data
for f = f_names %f = temp(1) % for troubleshooting single trial data
    try
        singleTrialData = loadTrialSub(f, varNames, timerange, interpFrameRate, FORCECOM, ...
            p.Results.additionalMarkers, additionalMarkerNames, p.Results.pertDirDataSource);
        dataTable = [dataTable; singleTrialData];
    catch
        % if something goes horribly wrong, skip this record and delete the filename
        disp("BAD TRIAL: " + extractAfter(f,studyFolder + "\"))
        filenames(filenames.filename==f,:)=[];
    end
end

% append the file information to the interpolated data
dataTable = [filenames dataTable];

% save the interpolated data
subj_ID = dataTable.viconid(1) + "_" + dataTable.sessionname(1);
saveFileName = studyFolder + "\" + subj_ID + ".mat";
save(saveFileName,'dataTable');
end