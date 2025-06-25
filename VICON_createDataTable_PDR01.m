function [dataAv, dataSD, participants, data] = VICON_createDataTable_PDR01()
% Specify file path where vicon second pass is saved using fdir
% (X:\ting\ting-data\neuromechanics-lab\ProcessedMatlabData\)
% fdir = '\\cosmic.bme.emory.edu\labs\ting\ting-data\neuromechanics-lab\ProcessedMatlabData\EEGStudies\PD_EEG\'; % where data is saved
fdir = uigetdir("X:\ting\ting-data\neuromechanics-lab\ProcessedMatlabData"); % select folder where participant data is saved
rmv_step = false; % option to remove steps
% specify subject code using names
names = ls([string(fdir) + "\" + "RVS*.mat"]);
names = cellstr(names);
debug = false;
addpath('X:\ting\shared_ting\Scott\matlabUtilities-master')

for i = 1:size(names,1)
    names(i) = strtok(names(i),'.');
end

participants = table();
participants.patient = string(names);

data = loadTrialData(participants.patient,fdir); % Load singla trial data

% average across like trials of each patient, ignoring trials with steps
dataVars = ["atime" "mtime" "EMG_MGAS_L" "EMG_TA_L" "EMG_MGAS_R" "EMG_TA_R" "EMG_SOL_L"...
    "EMG_SOL_R" "EMG_BFLH_R" "EMG_VMED_R" "EMG_RF_R" "EMG_BFLH_L" "EMG_VMED_L" "EMG_RF_L"...
    "LVDT_X" "LVDT_Y" "COMPosminusLVDT_X" "COMPosminusLVDT_Y" "COMVelo_X"...
    "COMVelo_Y" "COMAccel_X" "COMAccel_Y" "Left_Fz" "Right_Fz"...
    "Hip_a_R" "Hip_a_L" "Knee_a_R" "Knee_a_L" "Ankle_a_R" "Ankle_a_L"...
    "Hip_a2_R" "Hip_a2_L" "Knee_a2_R" "Knee_a2_L" "Ankle_a2_R" "Ankle_a2_L"...
    "Hip_m_R" "Hip_m_L" "Knee_m_R" "Knee_m_L" "Ankle_m_R" "Ankle_m_L" "LHEE_Y" "LHEE_Z" "RHEE_Y" "RHEE_Z" "FT"];

% dataVars = ["atime" "mtime" "EMG_MGAS_L" "EMG_TA_L" "EMG_MGAS_R" "EMG_TA_R" "EMG_SOL_L"...
%     "EMG_SOL_R" "EMG_BFLH_R" "EMG_VMED_R" "EMG_RF_R" "EMG_BFLH_L" "EMG_VMED_L" "EMG_RF_L"...
%     "LVDT_X" "LVDT_Y" "COMPosminusLVDT_X" "COMPosminusLVDT_Y" "COMVelo_X"...
%     "COMVelo_Y" "COMAccel_X" "COMAccel_Y" "Left_Fz" "Right_Fz"...
%     "Hip_a_R" "Hip_a_L" "Knee_a_R" "Knee_a_L" "Ankle_a_R" "Ankle_a_L"...
%     "Hip_a2_R" "Hip_a2_L" "Knee_a2_R" "Knee_a2_L" "Ankle_a2_R" "Ankle_a2_L"...
%     "Hip_m_R" "Hip_m_L" "Knee_m_R" "Knee_m_L" "Ankle_m_R" "Ankle_m_L" "FT"...
%     "theta_ersp" "alpha_ersp" "beta_ersp" "gamma_ersp" "time_ersp" "Cz" "time_eeg"];


% flag and remove steps that interfere with the perturbation response.
atime = data.atime(1,:);
data.step = min(min(data.Left_Fz,[],2),min(data.Right_Fz,[],2)) < 50;

%uncrossing arms or catched (manually checked)
% data.step(data.viconid=="PDAon01" & data.trialname=="Trial10")=true;

for i = 1:size(participants,1)
    participants.step(i) = sum(ismember(data.viconid,participants.patient(i))&data.step);
end
if rmv_step
    data(data.step,:) = [];
end
% dataAv = varfun(@(in) nanmean(in,1),data(ismember(data.pertdir_calc_round_deg,[60 90 120 240 270 300]),:),'GroupingVariables',{'patient' 'pertdir_calc_round_deg' 'condition'},'InputVariables',cellstr(dataVars));
% dataAv.Properties.VariableNames(5:end) = dataVars;
% dataSD = varfun(@(in) nanstd(in,0,1),data(ismember(data.pertdir_calc_round_deg,[60 90 120 240 270 300]),:),'GroupingVariables',{'patient' 'pertdir_calc_round_deg' 'condition'},'InputVariables',cellstr(dataVars));
% dataSD.Properties.VariableNames(5:end) = dataVars;

dataAv = varfun(@(in) nanmean(in,1),data(ismember(data.pertdir_calc_round_deg,[0  60  90  120  150  210  240  270  300  330]),:),...
    'GroupingVariables',{'patient'  'condition'},'InputVariables',cellstr(dataVars));
dataAv.Properties.VariableNames(4:end) = dataVars;
dataSD = varfun(@(in) nanstd(in,0,1),data(ismember(data.pertdir_calc_round_deg,[0  60  90  120  150  210  240  270  300  330]),:),...
    'GroupingVariables',{'patient' 'condition'},'InputVariables',cellstr(dataVars));
dataSD.Properties.VariableNames(4:end) = dataVars;

if debug
    for temppertdir = unique(data.pertdir_calc_round_deg)'
        for condition = unique(data.condition)'
            figure
            for ii = 1:size(participants,1)
                rec = ismember(data.patient,participants.patient(ii))&...
                    ismember(data.pertdir_calc_round_deg,temppertdir)&ismember(data.condition,condition);
                recAv = ismember(dataAv.patient,participants.patient(ii))&...
                    ismember(dataAv.pertdir_calc_round_deg,temppertdir)&ismember(dataAv.condition,condition);
                
                var = {'EMG_TA_R' 'EMG_MGAS_R' 'EMG_TA_L' 'EMG_MGAS_L' 'COMPosminusLVDT_Y' 'COMVelo_Y' 'COMAccel_Y' 'LVDT_Y'};
                
                for iii = 1:size(var,2)
                    subplot(size(var,2),size(participants,1),ii+(size(participants,1)*(iii-1)))
                    plot(data.atime(rec,:)',data.(var{iii})(rec,:)','Color',[0.7 0.7 0.7])
                    plot(dataAv.atime(recAv,:)',dataAv.(var{iii})(recAv,:)','b','linewidth',1)
                    ylabel(var{iii})
                    if iii==1
                        title(participants.patient(ii))
                    end
                end
            end
        end
    end
end

% copy in some grouping variables
% GroupingVariables = ["avGroup" "compHoaPD" "lowMoca" "tooTall" "faller" "sex"];
% dataAv = [dataAv inheritVars(dataAv,patients,'patient',["age" GroupingVariables])];
% dataSD = [dataSD inheritVars(dataSD,patients,'patient',["age" GroupingVariables])];


% NOTE 2019 03 13: need to describe this at length in methods
% normalize the EMG within each patient
normwindow = atime>0.08&atime<0.425;
% normwindow = atime>0.08&atime<0.350;
for m = dataVars(contains(dataVars,"EMG_"))
    dataAv{:,m+"_normcoef"} = nan(size(dataAv,1),1);
    % loop over patients and calculate the maximum emg observed in the
    % normwindow described above.
    for p = unique(dataAv.patient)'
        dataAv{dataAv.patient==p,m+"_normcoef"} = nanmax(nanmax(dataAv{dataAv.patient==p,m}(:,normwindow),[],2));
    end
    dataAv{:,m+"_norm"} = dataAv{:,m}./repmat(dataAv{:,m+"_normcoef"},1,size(dataAv{:,m},2));
end

% create a plat variable
% nRows = size(dataAv,1);
% nSamp = size(dataAv.atime,2);
% dataAv.plat = (dataAv.LVDT_Y.^2 + dataAv.LVDT_X.^2).^0.5;
% dataAv.plat(ismember(dataAv.pertdir_calc_round_deg,[240 270 300]),:) = - dataAv.plat(ismember(dataAv.pertdir_calc_round_deg,[240 270 300]),:);
% 
% % include in the averages; consider only normed EMG data from now on
% dataVars{end+1} = 'plat';
dataVars = strrep(strrep(dataVars,'_L','_L_norm'),'_R','_R_norm');

% code average kinematics traces with missing values (usually prior to platform onset) as 0.
varsTozero = {'COMPosminusLVDT_X' 'COMPosminusLVDT_Y' 'COMVelo_X' 'COMVelo_Y' 'COMAccel_X' 'COMAccel_Y'};
for i = 1:length(varsTozero)
    temp = dataAv{:,varsTozero{i}}(:,atime<0);
    temp(isnan(temp)) = 0;
    dataAv{:,varsTozero{i}}(:,atime<0) = temp;
end

% calculate peak EMG activity in a window 100-600 ms after onset of
% platform motion
% [dataAv.peak_MGAS_L dataAv.peak_MGAS_R dataAv.peak_TA_L dataAv.peak_TA_R dataAv.peak_SOL_L dataAv.peak_SOL_R] = deal(addcol(dataAv,NaN));
% searchWindow = atime>=0.1&atime<0.6;
% % searchWindow = atime>0&atime<0.350; % edit 2019 03 13; previous analyses
% % used a 0-350 ms window; we will use 100-600 ms for paper.
% dataAv.peak_MGAS_L = nanmax(dataAv.EMG_MGAS_L_norm(:,searchWindow),[],2);
% dataAv.peak_MGAS_R = nanmax(dataAv.EMG_MGAS_R_norm(:,searchWindow),[],2);
% dataAv.peak_TA_L = nanmax(dataAv.EMG_TA_L_norm(:,searchWindow),[],2);
% dataAv.peak_TA_R = nanmax(dataAv.EMG_TA_R_norm(:,searchWindow),[],2);
% dataAv.mean_MGAS_L = nanmean(dataAv.EMG_MGAS_L_norm(:,searchWindow),2);
% dataAv.mean_MGAS_R = nanmean(dataAv.EMG_MGAS_R_norm(:,searchWindow),2);
% dataAv.mean_TA_L = nanmean(dataAv.EMG_TA_L_norm(:,searchWindow),2);
% dataAv.mean_TA_R = nanmean(dataAv.EMG_TA_R_norm(:,searchWindow),2);

% calculate peak CoM motion. the following search windows were determined
% from inspection of recorded traces. (CoM accel, <200 ms, CoM velocity, <400 ms, CoM displacement, <675 ms.)
[dataAv.peak_COMPosminusLVDT_Y dataAv.peak_COMVelo_Y dataAv.peak_COMAccel_Y] = deal(addcol(dataAv,NaN));
dataAv.peak_COMPosminusLVDT_Y = nanmax(abs(dataAv.COMPosminusLVDT_Y(:,atime<0.675)),[],2);
dataAv.peak_COMVelo_Y = nanmax(abs(dataAv.COMVelo_Y(:,atime<0.400)),[],2);
dataAv.peak_COMAccel_Y = nanmax(abs(dataAv.COMAccel_Y(:,atime<0.200)),[],2);

% % transform data from wide to tall.
% dataTall = [];
% statList = ["peak_TA_L" "peak_TA_R" "peak_MGAS_L" "peak_MGAS_R" "mean_TA_L" "mean_TA_R" "mean_MGAS_L" "mean_MGAS_R"];
% for m = statList
%     temp = dataAv(:,{'patient' 'pertdir_calc_round_deg' char(m)});
%     temp.Properties.VariableNames{end} = 'val';
%     temp.stat = addcol(temp,m);
%     dataTall = [dataTall; temp];
% end
% head(dataTall)
% 
% % create new codes for perturbation direction
% [dataTall.dir dataTall.mus] = deal(addcol(dataTall,"X"));
% dataTall.dir(ismember(dataTall.pertdir_calc_round_deg,[60 90 120])) = "F";
% dataTall.dir(ismember(dataTall.pertdir_calc_round_deg,[240 270 300])) = "B";
% dataTall.mus(contains(dataTall.stat,"_MGAS_")) = "MGAS";
% dataTall.mus(contains(dataTall.stat,"_TA_")) = "TA";
% dataTall.mus(contains(dataTall.stat,"_SOL_")) = "SOL";
% 
% % inherit patient-level variables
% % dataTall = [dataTall inheritVars(dataTall,patients,'patient',["moca_total" "pd_duration" "mds_updrs_iii" "avGroup" "compHoaPD" "lowMoca" "tooTall" "faller" "sex" "age" "goodKin"])];
% 
% % Adjust peak EMG values for linear effects of age
% dataTall.valPred = addcol(dataTall,nan);
% dataTall.valAdj = addcol(dataTall,nan);
% 
% for mus = ["TA" "MGAS" "SOL"]
%     for dir = ["F" "B"]
%         filter = dataTall.age>50 & dataTall.lowMoca=="no" & dataTall.mus==mus & dataTall.dir==dir;
%         
%         tempTable = dataTall(filter,:);
%         tempAv = varfun(@(in) nanmean(in,1),tempTable,'GroupingVariables','patient','InputVariables',{'age' 'val'});
%         tempAv.Properties.VariableNames(3:end) = {'age' 'val'};
%         
%         % calculate regressions after averaging across replicates of each
%         % participant to ensure that no participant is over-represented in
%         % the average.
%         [p,s,mu] = polyfit(tempAv.age,tempAv.val,1);
%         tempTable.valPred = polyval(p,tempTable.age,[],mu);
%         tempTable.valAdj = (tempTable.val - tempTable.valPred) + nanmean(tempTable.val);
%         
%         dataTall(filter,:) = tempTable;
%     end
% end

end

function data = loadTrialData(patientList, fdir)

nPatients = length(patientList);

% interpolate all of the data to a common timebase
% deleteVars = ["mtime" expandNames3D(["LHEE" "RHEE"]) ...
%     'EMG_VMED_L' 'EMG_BFLH_L' 'EMG_VMED_L_raw' 'EMG_BFLH_L_raw' ...
%     'EMG_VMED_R' 'EMG_BFLH_R' 'EMG_VMED_R_raw' 'EMG_BFLH_R_raw' ...
%     'EMG_RFEM_R' 'EMG_RFEM_L' 'EMG_RFEM_R_raw' 'EMG_RFEM_L_raw'];
deleteVars = [''];

for i = 1:nPatients
    disp("loading "+"./data/"+patientList(i)+".mat")
    addpath('X:\ting\shared_ting\Scott\matlabUtilities-master')
    load(string(fdir) + "\" + patientList(i)+ ".mat")
    %     load("C:\Users\seboe\OneDrive - Emory University\Documents\Grad School\Neuromechanics Lab\Funding Applications\EEG R01 2023\Data\"+patientList(i)+".mat");
    
    % add the patient id
    dataTable.patient = addcol(dataTable,patientList(i));
    
    % get rid of spurious columns
    dataTable(:,ismember(string(dataTable.Properties.VariableNames),deleteVars)) = [];
    
    if i == 1
        data = dataTable;
    else
        data = [data; dataTable];
    end
end
clear dataTable

end


