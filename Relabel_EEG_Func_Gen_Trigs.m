%% Relabel triggers based on sample spacing
% Parameters
fs = EEG.srate; % sample rate of EEG system
FG_min = 498; % search window min for function generator (FG)
FG_max = 502; % search window max for function generator (FG)
rec_min = fs * 6;   % search window min for vicon recording pulses
rec_max = fs * 8;   % search window max for vicon recording pulses

% Target trigger codes of interest
target_codes = {'S 15', 'S 11', 'S  3', 'S  7'};

n_events = length(EEG.event);
event_types = {EEG.event.type};
event_latencies = [EEG.event.latency];

%% Relabel function generator triggers based on ~500 sample spacing
i = 1;
fg_flag = true;  % toggle between FG_up and FG_down
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
            if fg_flag
                EEG.event(i).type = 'FG_up';
            elseif ~fg_flag
                EEG.event(i).type = 'FG_down';
            end
            fg_flag = ~fg_flag;  % toggle
        elseif delta < FG_min % if delta is under FG pulse width, then it must be a trial trig
            % Label current event
            if fg_flag && (~strcmp(EEG.event(i).type,'trial_start') || ~strcmp(EEG.event(i).type,'trial_end'))
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
            elseif ~fg_flag && (~strcmp(EEG.event(i).type,'trial_start') || ~strcmp(EEG.event(i).type,'trial_end'))
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
            fg_flag = ~fg_flag;  % toggle function generator
        end
    end
    i = i + 1; %iterate
end