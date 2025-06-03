%% Script to fix when function generator trigger codes are relabeled by vicon triggers
% Make sure eeglab is open and you have loaded the file of interest
% This SHOULD BE DONE BEFORE EPOCHING THE EEG DATA
%% Known Parameters
noAUXchans = true; %Were the auxillary channels working on the EEG emplifier? Yes == true, no == false.
fs = EEG.srate; % sample rate of EEG system
FG_min = 498; % search window min for function generator (FG)
FG_max = 502; % search window max for function generator (FG)
rec_min = fs * 6;   % search window min for vicon recording pulses
rec_max = fs * 8;   % search window max for vicon recording pulses

% Target trigger codes of interest
target_codes = {'S 15', 'S 11', 'S  3', 'S  7'};

%% initialize vars
n_events = length(EEG.event);
event_types = {EEG.event.type};
event_latencies = [EEG.event.latency];

%% Relabel function generator triggers based on known sample spacing
i = 1;
FG_flag = true;  % toggle between FG_up and FG_down
trialstart_flag = true;  % toggle between trial start and trial stop
while i < n_events
    curr_type = event_types{i};
    next_type = event_types{i+1};
    curr_lat = event_latencies(i);
    next_lat = event_latencies(i+1);
    delta = next_lat - curr_lat;
    
    % Check if current and next event are in the target list
    if ismember(curr_type, target_codes) && ismember(next_type, target_codes)
        if delta >= FG_min && delta <= FG_max % if delta is ~equal to FG pulse width
            % Label current event
            if FG_flag
                EEG.event(i).type = 'FG_up';
            elseif ~FG_flag
                EEG.event(i).type = 'FG_down';
            end
            FG_flag = ~FG_flag;  % toggle
        elseif delta < FG_min % if delta is under FG pulse width, then it must be a trial trig
            % Label current event
            if FG_flag && (~strcmp(EEG.event(i).type,'trial_start') || ~strcmp(EEG.event(i).type,'trial_end'))
                EEG.event(i).type = 'FG_up';
                if trialstart_flag
                    EEG.event(i+1).type = 'trial_start';
                    i = i + 1; % skip iteration b/c trial code as been labeled
                    trialstart_flag = ~trialstart_flag; % toggle trial start/end
                elseif ~trialstart_flag
                    EEG.event(i+1).type = 'trial_end';
                    i = i + 1; % skip iteration b/c trial code as been labeled
                    trialstart_flag = ~trialstart_flag; % toggle trial start/end
                end
            elseif ~FG_flag && (~strcmp(EEG.event(i).type,'trial_start') || ~strcmp(EEG.event(i).type,'trial_end'))
                EEG.event(i).type = 'FG_down';
                if trialstart_flag
                    EEG.event(i+1).type = 'trial_start';
                    trialstart_flag = ~trialstart_flag; % toggle trial start/end
                    i = i + 1; % skip iteration b/c trial code as been labeled
                elseif ~trialstart_flag
                    EEG.event(i+1).type = 'trial_end';
                    trialstart_flag = ~trialstart_flag; % toggle trial start/end
                    i = i + 1; % skip iteration b/c trial code as been labeled
                end
            end
            FG_flag = ~FG_flag;  % toggle function generator
        end
    end
    i = i + 1; %iterate
end

%% Create square wave and insert into EEG.data structure for interpolation
if noAUXchans
    % Initialize FG_timeseries
    FG_timeseries = zeros(1, length(EEG.times));
    
    % Get latencies and types of FG_up and FG_down events
    FG_event_inds = find(strcmp({EEG.event.type}, 'FG_up') | strcmp({EEG.event.type}, 'FG_down'));
    FG_event_types = {EEG.event(FG_event_inds).type};
    FG_event_latencies = round([EEG.event(FG_event_inds).latency]);
    
    % Sort events by latency to ensure correct temporal order
    [sorted_latencies, sort_order] = sort(FG_event_latencies);
    sorted_types = FG_event_types(sort_order);
    
    % Initialize state: 0 (neutral), +1 (FG_up), -1 (FG_down)
    current_state = -1;
    FG_timeseries(1:sorted_latencies(1)) = current_state;
    % Loop through events and assign values to FG_timeseries
    for i = 1:length(sorted_latencies)
        event_type = sorted_types{i};
        latency = sorted_latencies(i);
        
        if strcmp(event_type, 'FG_up')
            current_state = 1;
        elseif strcmp(event_type, 'FG_down')
            current_state = -1;
        end
        
        % Fill from current latency to end (or next event) with current_state
        if i < length(sorted_latencies)
            next_latency = sorted_latencies(i + 1) - 1;
        else
            next_latency = length(EEG.times); % fill to the end of the signal
        end
        
        FG_timeseries(latency:next_latency) = current_state;
    end
    % specify EOG channel
    EOG_chan = find(strcmp({EEG.chanlocs.labels},'VEOG'));
    % set EOG channel to function generator time series
    EEG.data(EOG_chan,:) = single(FG_timeseries);
    % I don't relabel the channel name in EEG structure b/c this is not
    % done in the workspace and therefore would make this different than
    % other datasets. 
end