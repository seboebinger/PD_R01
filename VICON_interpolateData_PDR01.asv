function saveFileName = VICON_interpolateData_PDR01(src, srcFolder, varargin)

p = inputParser;
addOptional(p,'srcDir',src);
addOptional(p,'staticTrialFormat','Stat*\d\d');
addOptional(p,'retroTrialFormat','Retro *\d\d');
addOptional(p,'trialNameFormat','Gait'); % trial name format - change as needed
addOptional(p,'trialNumbers',[]);
addOptional(p,'participantCodeFormat','RVS\d\d\d'); % Study Code
addOptional(p,'stepForceThresholdN',10);
addOptional(p,'timerange',[-0.5 7]); % time range - change as needed
addOptional(p,'interpFrameRate',[]);
addOptional(p,'additionalMarkers',[]);
addOptional(p,'pertDirDataSource',"LVDT");
addOptional(p,'forceCOM',0);
p.KeepUnmatched = true;
parse(p,varargin{:});

FORCECOM = p.Results.forceCOM;

if isempty(p.Results.srcDir)
    srcDir = uigetdir(pwd, 'Select Trial Directory');
else
    srcDir = p.Results.srcDir;
end

timerange = p.Results.timerange;
interpFrameRate = p.Results.interpFrameRate;

% generate file names from source directory
filenames = generatefilenames(srcDir);

% delete files that do not match the trial string specification
filenames(cellfun(@isempty,regexp(filenames.trialname,p.Results.trialNameFormat)),:) = [];

if ~isempty(p.Results.trialNumbers)
    % erase non-numeric characters
    trialNumbers = str2double(regexprep(filenames.trialname,'\D',""));
    filenames(~ismember(trialNumbers,p.Results.trialNumbers),:) = [];
end

% loop through, load, and interpolate the data
varNames = getVarNames2022;

% add additional markers if necessary
if ~isempty(p.Results.additionalMarkers)
    additionalMarkerNames = expandNames3D(p.Results.additionalMarkers);
    dataTable = names2table([varNames cellstr(additionalMarkerNames)]);
else
    dataTable = names2table(varNames);
end

% create an interpolated database
temp = filenames.filename';
% datasheet = load([srcDir '\DataSheet.mat']); % load perturbation file\
datasheet = [];
% Load single trial data
for f = temp %f = temp(1) % for troubleshooting single trial data
    try
        loadTrialSub(f,datasheet);
    catch
        % if something goes horribly wrong, skip this record and delete the filename
        disp("BAD TRIAL: Trial  " + extractBetween(f,"Trial",".mat"))
        filenames(filenames.filename==f,:)=[];
    end
end

% append the file information to the interpolated data
dataTable = [filenames dataTable];
% dataTable = [filenames(1,:) dataTable]; %for single trial troubleshooting

% save the interpolated data
subj_ID = string(extractBetween(srcDir,string(srcFolder) + "\","\New Session"));
saveFileName = srcFolder + "\" + subj_ID + "_Gait.mat";
save(saveFileName,'dataTable');

    function loadTrialSub(f,datasheet)
        disp(join(["loading" f]))
        
        % load data
        d = load(char(f));
        
        % (re)calculate perturbation onset from accelerometer signals
        if strcmp(p.Results.trialNameFormat, "Backward") | strcmp(p.Results.trialNameFormat, "Gait")
            platonset = 0;
        else
            platonset = recalculatePlatOnset(d.Accels,d.atime);
        end
        %         if contains(f,'PDAon01')
        %             x = 0:7.65/500:7.65;
        %             r = 0;
        %             for i = 1:999
        %                 temp2 = corrcoef(x,abs(d.LVDT(platonset*1000-500+i:platonset*1000+i,2)));
        %                 if temp2(1,2)>r
        %                     r = temp2(1,2);
        %                     delay = i;
        %                 end
        %             end
        %             platonset = d.atime(platonset*1000+delay-500-40);
        %         end
        
        % if this didn't work, calculate from LVDT
        if isnan(platonset)
            LVDTmag = (d.LVDT(:,1).^2+d.LVDT(:,2).^2).^0.5;
            LVDTmag = LVDTmag - nanmean(LVDTmag(d.atime<0.1));
            platonset = d.atime(findchangepts(LVDTmag,'Statistic','rms'));%d.atime(find(LVDTmag>6*nanstd(LVDTmag(d.atime<0.1)),1,'first'));
        end
        
        % calculate perturbation parameters and unpack table into workspace
        % variables
        [pertdir_calc_deg,pertdir_calc_round_deg,pertdisp_calc_cm,pertvel_calc_cm_s,pertacc_calc_g] = deal(nan);
        try
            pertparams = calculatePertParams(d.LVDT,d.Accels,d.atime,platonset,d.Velocity);
            table2workspace(pertparams);
        catch
        end
        
        % force calculation of perturbation direction from heel markers if required
        if ~isempty(p.Results.pertDirDataSource)
            pertparams = calculatePertParams(d.LVDT,d.Accels,d.atime,platonset,d.Velocity,'pertDirDataSource',p.Results.pertDirDataSource);
            pertdir_calc_round_deg = pertparams.pertdir_calc_round_deg;
            pertdir_calc_deg = pertparams.pertdir_calc_deg;
        end
        % Condition identifier - used for grouping when averaging the data -- should reflect your independent variable
        condition = pertdir_calc_round_deg; 
        % time variables
        AnalogFrameRate = d.AnalogFrameRate;
        VideoFrameRate = d.VideoFrameRate;
        if exist('d.DigitalFrameRate')
            DigitalFrameRate = d.DigitalFrameRate;
        else
            DigitalFrameRate = d.VideoFrameRate;
        end
        
        atime = d.atime;
        mtime = d.mtime;
        mass = d.mass;
        
        % zero time to perturbation onset
        atime = atime - platonset;
        mtime = mtime - platonset;
        
        % create anonymous functions to interpolate
        if ~isempty(interpFrameRate)
            newtime = timerange(1):(1/interpFrameRate):(timerange(2)-(1/interpFrameRate));
        else
            newtime = timerange(1):(1/AnalogFrameRate):(timerange(2)-(1/AnalogFrameRate));
        end
        maresamp = @(in) resample(in(:),AnalogFrameRate,VideoFrameRate);
        ainterp = @(in) interp1(atime,in(:),newtime);
        
        mnewtime = timerange(1):(1/DigitalFrameRate):(timerange(2)-(1/DigitalFrameRate));
        minterp = @(in) interp1(mtime,in(:),mnewtime);
        
        
        % EMG
        EMG_MGAS_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_MGAS-R" "Voltage.MG-R" "EMG_MG-R" "EMG_MG_R"])));
        EMG_SOL_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_SOL-R" "Voltage.SOL-R" "EMG_SOL_R"])));
        EMG_TA_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_TA-R" "Voltage.TA-R" "EMG_TA_R"])));
        EMG_MGAS_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_MGAS-L" "Voltage.MG-L" "EMG_MG-L" "EMG_MG_L"])));
        EMG_SOL_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_SOL-L" "Voltage.SOL-L" "EMG_SOL_L"])));
        EMG_TA_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_TA-L" "Voltage.TA-L" "EMG_TA_L"])));
        
        EMG_BFLH_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_BFLH_R" "Voltage.BFLH-R" "EMG_BFLH-R" "EMG_BFLH_R"])));
        EMG_VMED_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_VMED-R" "Voltage.SOL-R" "EMG_SOL_R"])));
        EMG_RF_R = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_RF-R" "Voltage.RF-R" "EMG_RF_R"])));
        EMG_BFLH_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_BFLH-L" "Voltage.BFLH-L" "EMG_BFLH-L" "EMG_BFLH_L"])));
        EMG_VMED_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_VMED-L" "Voltage.VMED-L" "EMG_VMED_L"])));
        EMG_RF_L = ainterp(d.EMG(:,contains(strtrim(string(d.EMGID)),["EMG_RF-L" "Voltage.RF-L" "EMG_RF_L"])));
        
        % EMG_raw
        [EMG_MGAS_R_raw,EMG_SOL_R_raw,EMG_TA_R_raw,EMG_MGAS_L_raw,EMG_SOL_L_raw,EMG_TA_L_raw,...
            EMG_BFLH_R_raw,EMG_VMED_R_raw,EMG_RF_R_raw,EMG_BFLH_L_raw,EMG_VMED_L_raw,EMG_RF_L_raw] = deal(nan(size(newtime)));
        try
            EMG_MGAS_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_MGAS-R" "Voltage.MG-R" "EMG_MG-R" "EMG_MG_R"])));
            EMG_SOL_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_SOL-R" "Voltage.SOL-R" "EMG_SOL_R"])));
            EMG_TA_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_TA-R" "Voltage.TA-R" "EMG_TA_R"])));
            EMG_MGAS_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_MGAS-L" "Voltage.MG-L" "EMG_MG-L" "EMG_MG_L"])));
            EMG_SOL_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_SOL-L" "Voltage.SOL-L" "EMG_SOL_L"])));
            EMG_TA_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_TA-L" "Voltage.TA-L" "EMG_TA_L"])));
            
            EMG_BFLH_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_BFLH-R" "Voltage.BFLH-R" "EMG_BFLH-R" "EMG_BFLH_R"])));
            EMG_VMED_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_VMED-R" "Voltage.VMED-R" "EMG_VMED_R"])));
            EMG_RF_R_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_RF-R" "Voltage.RF-R" "EMG_RF_R"])));
            EMG_BFLH_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_BFLH-L" "Voltage.BFLH-L" "EMG_BFLH-L" "EMG_BFLH_L"])));
            EMG_VMED_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_VMED-L" "Voltage.VMED-L" "EMG_VMED_L"])));
            EMG_RF_L_raw = ainterp(d.rawData.analog.emg(:,contains(strtrim(string(d.EMGID)),["EMG_RF-L" "Voltage.RF-L" "EMG_RF_L"])));
        catch
            disp(f+": raw EMG data not found")
        end
        
        % ground reaction forces
        try
            Left_Fx = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left Fx'));
            Left_Fy = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left Fy'));
            Left_Fz = abs(ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left Fz')));
            Left_Mx = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left Mx'));
            Left_My = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left My'));
            Left_Mz = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Left Mz'));
            Right_Fx = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right Fx'));
            Right_Fy = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right Fy'));
            Right_Fz = abs(ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right Fz')));
            Right_Mx = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right Mx'));
            Right_My = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right My'));
            Right_Mz = ainterp(d.data.digital.plateforces(:,string(d.data.digital.plateforcesID)=='Right Mz'));
        catch
            try
                plateforcesID = deblank(string(d.ForcesID));
                Left_Fx = ainterp(d.GRF(:,plateforcesID=="LF Fx"));
                Left_Fy = ainterp(d.GRF(:,plateforcesID=="LF Fy"));
                Left_Fz = abs(ainterp(d.GRF(:,plateforcesID=="LF Fz")));
                Left_Mx = ainterp(d.GRF(:,plateforcesID=="LF Mx"));
                Left_My = ainterp(d.GRF(:,plateforcesID=="LF My"));
                Left_Mz = ainterp(d.GRF(:,plateforcesID=="LF Mz"));
                
                Right_Fx = ainterp(d.GRF(:,plateforcesID=="RT Fx"));
                Right_Fy = ainterp(d.GRF(:,plateforcesID=="RT Fy"));
                Right_Fz = abs(ainterp(d.GRF(:,plateforcesID=="RT Fz")));
                Right_Mx = ainterp(d.GRF(:,plateforcesID=="RT Mx"));
                Right_My = ainterp(d.GRF(:,plateforcesID=="RT My"));
                Right_Mz = ainterp(d.GRF(:,plateforcesID=="RT Mz"));
            catch
                [Left_Fx,Left_Fy,Left_Fz,Left_Mx,Left_My,Left_Mz,Right_Fx,Right_Fy,Right_Fz,Right_Mx,Right_My,Right_Mz] = deal(nan(size(newtime)));
                disp(f+": force data not found")
            end
        end
        
        % platform kinematics
        LVDT_X = ainterp(d.LVDT(:,1));
        LVDT_Y = ainterp(d.LVDT(:,2));
        Velocity_X = ainterp(d.Velocity(:,1));
        Velocity_Y = ainterp(d.Velocity(:,2));
        Accels_X = ainterp(d.Accels(:,1));
        Accels_Y = ainterp(d.Accels(:,2));
        
        % interpolate CoM variables; in some cases the estimates of position and velocity from markers are
        % unavailable. if so use estimates from forces.
        COMAccel_X = ainterp(d.COMAccel(:,1));
        COMAccel_Y = ainterp(d.COMAccel(:,2));
        
        COP_X = ainterp(d.COP(:,1));
        COP_Y = ainterp(d.COP(:,2));
        
        COMPos_X = ainterp(maresamp(d.COMPos(:,1)));
        COMPos_Y = ainterp(maresamp(d.COMPos(:,2)));
        
        COMPosminusLVDT_X = ainterp(maresamp(d.COMPosminusLVDT(:,1)));
        COMPosminusLVDT_Y = ainterp(maresamp(d.COMPosminusLVDT(:,2)));
        
        COMVelo_X = ainterp(maresamp(d.COMVelo(:,1)));
        COMVelo_Y = ainterp(maresamp(d.COMVelo(:,2)));
        
        % joint kinematics 1000
        %         Hip_m_R = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'hip_flexion_r_moment'))));
        %         Hip_m_L = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'hip_flexion_l_moment'))));
        %
        %         Knee_m_R = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'knee_angle_r_moment'))));
        %         Knee_m_L = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'knee_angle_l_moment'))));
        %
        %         Ankle_m_R = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'ankle_angle_r_moment'))));
        %         Ankle_m_L = ainterp(maresamp(d.ID.data(:,contains(d.ID.colheaders,'ankle_angle_l_moment'))));
        %
        %         Hip_a_R = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'RHipAngles'),1)));
        %         Hip_a_L = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'LHipAngles'),1)));
        %
        %         Knee_a_R = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'RKneeAngles'),1)));
        %         Knee_a_L = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'LKneeAngles'),1)));
        %
        %         Ankle_a_R = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'RAnkleAngles'),1)));
        %         Ankle_a_L = ainterp(maresamp(d.Markers(:,contains(string(d.MarkerID),'LAnkleAngles'),1)));
        %
        %         Hip_a2_R = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'hip_flexion_r'))));
        %         Hip_a2_L = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'hip_flexion_l'))));
        %
        %         Knee_a2_R = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'knee_angle_r'))));
        %         Knee_a2_L = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'knee_angle_l'))));
        %
        %         Ankle_a2_R = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'ankle_angle_r'))));
        %         Ankle_a2_L = ainterp(maresamp(d.IK.data(:,contains(d.IK.colheaders,'ankle_angle_l'))));
        
        % joint kinematics and moments 100
        try
            Hip_m_R = minterp(d.ID.data(:,contains(d.ID.colheaders,'hip_flexion_r_moment')));
            Hip_m_L = minterp(d.ID.data(:,contains(d.ID.colheaders,'hip_flexion_l_moment')));
            
            Knee_m_R = minterp(d.ID.data(:,contains(d.ID.colheaders,'knee_angle_r_moment')));
            Knee_m_L = minterp(d.ID.data(:,contains(d.ID.colheaders,'knee_angle_l_moment')));
            
            Ankle_m_R = minterp(d.ID.data(:,contains(d.ID.colheaders,'ankle_angle_r_moment')));
            Ankle_m_L = minterp(d.ID.data(:,contains(d.ID.colheaders,'ankle_angle_l_moment')));
        catch
            Hip_m_R = nan(size(mnewtime));
            Hip_m_L = nan(size(mnewtime));
            
            Knee_m_R = nan(size(mnewtime));
            Knee_m_L = nan(size(mnewtime));
            
            Ankle_m_R = nan(size(mnewtime));
            Ankle_m_L = nan(size(mnewtime));
        end
        
        try
            Hip_a_R = minterp(d.Markers(:,contains(string(d.MarkerID),'RHipAngles'),1));
            Hip_a_L = minterp(d.Markers(:,contains(string(d.MarkerID),'LHipAngles'),1));
            
            Knee_a_R = minterp(d.Markers(:,contains(string(d.MarkerID),'RKneeAngles'),1));
            Knee_a_L = minterp(d.Markers(:,contains(string(d.MarkerID),'LKneeAngles'),1));
            
            Ankle_a_R = minterp(d.Markers(:,contains(string(d.MarkerID),'RAnkleAngles'),1));
            Ankle_a_L = minterp(d.Markers(:,contains(string(d.MarkerID),'LAnkleAngles'),1));
        catch
            Hip_a_R = nan(size(mnewtime));
            Hip_a_L = nan(size(mnewtime));
            
            Knee_a_R = nan(size(mnewtime));
            Knee_a_L = nan(size(mnewtime));
            
            Ankle_a_R = nan(size(mnewtime));
            Ankle_a_L = nan(size(mnewtime));
        end
        
        try
            Hip_a2_R = minterp(d.IK.data(:,contains(d.IK.colheaders,'hip_flexion_r')));
            Hip_a2_L = minterp(d.IK.data(:,contains(d.IK.colheaders,'hip_flexion_l')));
            
            Knee_a2_R = minterp(d.IK.data(:,contains(d.IK.colheaders,'knee_angle_r')));
            Knee_a2_L = minterp(d.IK.data(:,contains(d.IK.colheaders,'knee_angle_l')));
            
            Ankle_a2_R = minterp(d.IK.data(:,contains(d.IK.colheaders,'ankle_angle_r')));
            Ankle_a2_L = minterp(d.IK.data(:,contains(d.IK.colheaders,'ankle_angle_l')));
        catch
            Hip_a2_R = nan(size(mnewtime));
            Hip_a2_L = nan(size(mnewtime));
            
            Knee_a2_R = nan(size(mnewtime));
            Knee_a2_L = nan(size(mnewtime));
            
            Ankle_a2_R = nan(size(mnewtime));
            Ankle_a2_L = nan(size(mnewtime));
        end
        
        try
            LHEE_Y = minterp(d.Markers(:,find(strcmp(d.MarkerID, "LHEE")),2));
            RHEE_Y = minterp(d.Markers(:,find(strcmp(d.MarkerID, "RHEE")),2));
            LHEE_Z = minterp(d.Markers(:,find(strcmp(d.MarkerID, "LHEE")),3));
            RHEE_Z = minterp(d.Markers(:,find(strcmp(d.MarkerID, "RHEE")),3));
            
        catch
            LHEE_Y = nan(size(mnewtime));
            RHEE_Y = nan(size(mnewtime));
            LHEE_Z = nan(size(mnewtime));
            RHEE_Z = nan(size(mnewtime));
        end
        
        % FT = ainterp(d.Other(:,contains(strtrim(string(d.OtherID)),["Electric Potential.Fz"])));
        FT=nan(size(mnewtime));
        
        if all(isnan([COMPosminusLVDT_X COMPosminusLVDT_Y]))||FORCECOM
            try
                COMPosminusLVDT_X = ainterp(d.data.calculated.com.plate.relative.pos(:,1));
                COMPosminusLVDT_Y = ainterp(d.data.calculated.com.plate.relative.pos(:,2));
                disp(f+": CoM position wrt ankle estimated from force data")
            catch
                [COMPosminusLVDT_X,COMPosminusLVDT_Y] = deal(nan(size(newtime)));
                disp(f+": CoM position wrt ankle not found")
            end
        end
        
        if all(isnan([COMVelo_X COMVelo_Y]))||FORCECOM
            try
                COMVelo_X = ainterp(d.data.calculated.com.plate.relative.vel(:,1));
                COMVelo_Y = ainterp(d.data.calculated.com.plate.relative.vel(:,2));
                disp(f+": CoM velocity estimated from force data")
            catch
                [COMVelo_X,COMVelo_Y] = deal(nan(size(newtime)));
                disp(f+": CoM velocity not found")
            end
        end
        
        if ~isempty(p.Results.additionalMarkers)
            MarkerID = deblank(string(d.MarkerID));
            MarkerInd = [];
            % create variables
            additionalMarkers = cell2table(repmat({nan(size(newtime))},1,3*length(p.Results.additionalMarkers)));
            additionalMarkers.Properties.VariableNames = additionalMarkerNames;
            for am_i = 1:length(p.Results.additionalMarkers)
                tempkin = maresamp(d.Markers(:,MarkerID==p.Results.additionalMarkers(am_i),1));
                additionalMarkers{1,3*(am_i-1)+1} = ainterp(tempkin);
                tempkin = maresamp(d.Markers(:,MarkerID==p.Results.additionalMarkers(am_i),2));
                additionalMarkers{1,3*(am_i-1)+2} = ainterp(tempkin);
                tempkin = maresamp(d.Markers(:,MarkerID==p.Results.additionalMarkers(am_i),3));
                additionalMarkers{1,3*(am_i-1)+3} = ainterp(tempkin);
            end
        end
        
        % save the interpolated time
        atime = newtime;
        mtime = mnewtime;
        
        % create an output table out of workspace variables
        out = workspace2table(varNames);
        if ~isempty(p.Results.additionalMarkers)
            out = [out additionalMarkers];
        end
        
        % append the table
        dataTable = [dataTable; out];
    end

end