function [time_synced, data_1_synced, data_2_synced, FG_1_synced, FG_2_synced] = ...
    Synchronize_Data(FG_1, FG_2, time_1, time_2, data_1, data_2, edgeType)

% --- Preprocessing: Denoise and binarize square waves ---
FG_1_bin = smoothdata(FG_1, 'gaussian', 11) > 0.5;
FG_2_bin = smoothdata(FG_2, 'gaussian', 11) > 0.5;

% --- Edge detection ---
if strcmpi(edgeType,'rising')
    edges_1 = find(diff(FG_1_bin) == 1);
    edges_2 = find(diff(FG_2_bin) == 1);
elseif strcmpi(edgeType,'falling')
    edges_1 = find(diff(FG_1_bin) == -1);
    edges_2 = find(diff(FG_2_bin) == -1);
else
    edges_1 = find(diff(FG_1_bin) == -1); % default to falling
    edges_2 = find(diff(FG_2_bin) == -1);
end

% --- Convert edge indices to time values ---
times_1 = time_1(edges_1);
times_2 = time_2(edges_2);

% --- Ensure there are enough detected edges ---
num_to_match = min(500, min(length(times_1), length(times_2)));
if num_to_match < 1
    error('Not enough edges detected to perform synchronization.');
end

% --- Identify which device leads ---
if times_1(1) < times_2(1)
    lead_device = 1;
    lag_device = 2;
    lag_times = times_2(1:num_to_match);
    lead_times = times_1(1:num_to_match);
    lag_time_vector = time_2;
    lag_data = data_2;
    lag_FG = FG_2;
else
    lead_device = 2;
    lag_device = 1;
    lag_times = times_1(1:num_to_match);
    lead_times = times_2(1:num_to_match);
    lag_time_vector = time_1;
    lag_data = data_1;
    lag_FG = FG_1;
end

% --- Compute mean lag and adjust lagging device's time vector ---
mean_lag = mean(lag_times - lead_times);
adjusted_lag_time = lag_time_vector - mean_lag;

% --- Define common time range ---
t_start = max(min(time_1), min(adjusted_lag_time));
t_end   = min(max(time_1), max(adjusted_lag_time));
num_points = min(length(time_1), length(time_2));
time_synced = linspace(t_start, t_end, num_points);

% --- Interpolate both datasets onto common time base ---
if lead_device == 1
    data_1_synced = interp1(time_1, data_1, time_synced, 'linear', 'extrap');
    data_2_synced = interp1(adjusted_lag_time, lag_data, time_synced, 'linear', 'extrap');
    FG_1_synced   = interp1(time_1, FG_1, time_synced, 'nearest', 0);
    FG_2_synced   = interp1(adjusted_lag_time, lag_FG, time_synced, 'nearest', 0);
else
    data_1_synced = interp1(adjusted_lag_time, lag_data, time_synced, 'linear', 'extrap');
    data_2_synced = interp1(time_2, data_2, time_synced, 'linear', 'extrap');
    FG_1_synced   = interp1(adjusted_lag_time, lag_FG, time_synced, 'nearest', 0);
    FG_2_synced   = interp1(time_2, FG_2, time_synced, 'nearest', 0);
end

% --- Optional rebinarization if needed ---
% FG_1_synced = FG_1_synced > 0.5;
% FG_2_synced = FG_2_synced > 0.5;

% --- Debugging information ---
disp(['Lead device: Device ', num2str(lead_device)]);
disp(['Estimated mean lag: ', num2str(mean_lag), ' s']);
disp(['Time range: ', num2str(t_start), ' to ', num2str(t_end)]);

end
