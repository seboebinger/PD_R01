function EEG = Update_EEG_Trigs(EEG, varargin)
%% function to update latency of EEG triggers to correspond to the perturbation onset
% inputs: EEG - EEG structure that is made by eeglab
% outputs: EEG - same EEG structure, but with updated triggers
% NOTE: you will have to resave the updated EEG structure or else the
% changes made by this function will not be saved.
%% Parser Arguments - change these (or change the input to the function)
p = inputParser;
% what channels in EEG data are used to update triggers
addOptional(p,'chan_PlatY','PlatY')% can somtimes change if the experimenter set up the accelerometers incorrectly (i.e. put head acceleromter on platform or rotated accelerometer)
addOptional(p,'chan_PlatX','PlatX')
addOptional(p,'savefigopt',false) % option to save the output figure
addOptional(p,'Num_Perts',2) % number of perturbations within each vicon trial (2 for perception)
addOptional(p,'Bad_trials',[]) % user defined index trials that did not have onset correctly identified
p.KeepUnmatched = true;
parse(p,varargin{:});

%% Adjust trigger latency based on perturbation accelerometer
% ID accelerometer channel
accelY_chan = find(strcmp({EEG.chanlocs.labels}, p.Results.chan_PlatY));
accelX_chan = find(strcmp({EEG.chanlocs.labels}, p.Results.chan_PlatX));
latencies = cell2mat({EEG.event.latency});
type = {EEG.event.type};
start_code = type{2}; % hacky? yes. Does it work? only if the 2nd trigger is the recording start code
ind_recordstart = strcmp(type,start_code);
latencies_pert1 = latencies(ind_recordstart);

% Make figure
figure
% set(gcf,'WindowState','maximized')
set(gcf,'WindowStyle','docked')

% iterate across each trial
x = 0;
for i = 1:length(latencies)
    if ~strcmp(type{i},start_code) % if the EEG event code is not for trial start -- skip
        continue
    elseif strcmp(type{i},start_code)
        x = x+1; % iteration counter for perturbaton onset codes
        % create temp variables of platform Acceleration
        AccelX = EEG.data(accelX_chan,latencies(i):latencies(i)+7000);
        AccelY = EEG.data(accelY_chan,latencies(i):latencies(i)+7000);
        Accel = sqrt((AccelX-mean(AccelX(1:400))).^2 + (AccelY-mean(AccelY(1:300))).^2);
        % ID FIRST perturbation onset using EEG accelerometer
        if ismember(i,p.Results.Bad_trials) %These trials had some noise which caused an early onset - increase threshold
            onset_pert1 = find(Accel>8,2)-5;
            onset_pert1 = onset_pert1(2);
        else
            onset_pert1 = find(Accel>8,1)-5;
        end
        % ID SECOND perturbation onset using EEG accelerometer
        if p.Results.Num_Perts == 2
            Accel_trunc = Accel;
            Accel_trunc(1:onset_pert1 + 2500) = NaN; % remove first perturbation from Acceleration search (but keep same number of samples)
            if ismember(i,p.Results.Bad_trials) %These trials had some noise which caused an early onset - increase threshold
                onset_pert2 = find(Accel_trunc>8,2)-5;
                onset_pert2 = onset_pert2(2);
            else
                onset_pert2 = find(Accel_trunc>8,1)-5;
            end
        end
        % plot for visual confirmation
        subplot(ceil(length(latencies_pert1)/10),10,x)
        hold on
        plot(Accel,'b')
        plot([onset_pert1 onset_pert1],[0 250],'r--')
        if p.Results.Num_Perts == 2
            plot(Accel_trunc,'Color','#4DBEEE')
            plot([onset_pert2 onset_pert2],[0 250],'r--')
        end
        %     xlim([300,1000])
        axis off
        title(num2str(x))
        
        % update onset latencies in EEG strucure
        % pert 1
        EEG.event(i).latency = latencies_pert1(x) + onset_pert1;
        EEG.event(i).type = 'Pert';
        EEG.event(i).trialnum = x;
        % pert 2 -- need to add rows to EEG.event
        if p.Results.Num_Perts == 2
            EEG.event(x+size(type,2)).latency = latencies_pert1(x) + onset_pert2;
            EEG.event(x+size(type,2)).type = 'Pert2';
            EEG.event(x+size(type,2)).trialnum = x;
        end
    end
end
sgtitle('Onsets from EEG Accelerometer')
if p.Results.savefigopt
    saveas(gcf,[figdir '\' subj,'_eeg onsets.jpg'],'jpg')
end
end
