function [time_synced, data_1_synced, data_2_synced, FG_1_synced, FG_2_synced] = ...
    Synchronize_Data(FG_1, FG_2, time_1, time_2, data_1, data_2, varargin)

% --- Parse inputs ---
p = inputParser;
addOptional(p,'FunctionGenFreq', 0.5)
addOptional(p,'Debug',false)
parse(p, varargin{:});

% --- Preprocess: Smooth and binarize ---
FG_1_bin = smoothdata(FG_1, 'gaussian', 11) > 0.5;
FG_2_bin = smoothdata(FG_2, 'gaussian', 11) > 0.5;

% --- Define helper function to compute mean lag ---
compute_lag = @(type) deal_edges(type, FG_1_bin, FG_2_bin, time_1, time_2);

% --- Try rising and falling edge ---
[mean_lag_rising, lead_r, lag_r, lag_times_r, lead_times_r] = compute_lag('rising');
[mean_lag_falling, lead_f, lag_f, lag_times_f, lead_times_f] = compute_lag('falling');

% --- Choose edge type with acceptable lag less than 1/2 of the FG period ---
if abs(mean_lag_rising) <= 1 / (2 * p.Results.FunctionGenFreq)
    edge_type = 'rising';
    mean_lag = mean_lag_rising;
    lead_device = lead_r;
    lag_device = lag_r;
    lag_times = lag_times_r;
    lead_times = lead_times_r;
else
    edge_type = 'falling';
    mean_lag = mean_lag_falling;
    lead_device = lead_f;
    lag_device = lag_f;
    lag_times = lag_times_f;
    lead_times = lead_times_f;
end

% --- Adjust lagging device's time vector ---
if lag_device == 1
    lag_time_vector = time_1;
    lag_data = data_1;
    lag_FG = FG_1;
else
    lag_time_vector = time_2;
    lag_data = data_2;
    lag_FG = FG_2;
end
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

% --- Debugging ---
if p.Results.FunctionGenFreq
    % display identified parameters
    disp(['Edge type used: ', edge_type]);
    disp(['Lead device: Device ', num2str(lead_device)]);
    disp(['Estimated mean lag: ', num2str(mean_lag), ' s']);
    disp(['Time range: ', num2str(t_start), ' to ', num2str(t_end)]);
    % plot inputs
    figure; set(gcf,'WindowStyle','docked')
    subplot(3,1,1);
    plot(time_1, FG_1, 'b'); hold on;
    plot(time_2, FG_2, 'r--');
    title('Function Generator Signals');
    legend('FG\_1','FG\_2');
    subplot(3,1,2);
    plot(time_1, data_1);
    title('Device 1 Data');
    subplot(3,1,3);
    plot(time_2, data_2);
    title('Device 2 Data');
    
    % plot interpolated data
    figure; set(gcf,'WindowStyle','docked')
    % function generator signals
    subplot(2,2,1)
    plot(time_1, FG_1, 'b'); hold on;
    plot(time_2, FG_2, 'r--');
    legend('FG\_1','FG\_2');
    title('Original Function Generator Signals');
    subplot(2,2,3)
    plot(time_synced, FG_1_synced, 'b'); hold on;
    plot(time_synced, FG_2_synced, 'r--');
    title('Shifted Function Generator Signals');
    % shifted data signals
    subplot(2,2,2)
    plot(time_1, data_1, 'b'); hold on;
    plot(time_synced, data_1_synced, 'r--');
    legend('data\_1','data\_1\_synced');
    title('Data 1');
    subplot(2,2,4)
    plot(time_2, data_2, 'b'); hold on;
    plot(time_synced, data_2_synced, 'r--');
    legend('data\_2','data\_2\_synced');
    title('Data 2');
end

end

%% Supporting Functions
function [mean_lag, lead_device, lag_device, lag_times, lead_times] = ...
    deal_edges(edgeType, FG_1_bin, FG_2_bin, time_1, time_2)

if strcmpi(edgeType,'rising')
    edges_1 = find(diff(FG_1_bin) == 1);
    edges_2 = find(diff(FG_2_bin) == 1);
else
    edges_1 = find(diff(FG_1_bin) == -1);
    edges_2 = find(diff(FG_2_bin) == -1);
end

times_1 = time_1(edges_1);
times_2 = time_2(edges_2);

num_to_match = min(500, min(length(times_1), length(times_2)));
if num_to_match < 1
    error(['Not enough ', edgeType, ' edges detected.']);
end

if times_1(1) < times_2(1)
    lead_device = 1;
    lag_device = 2;
    lag_times = times_2(1:num_to_match);
    lead_times = times_1(1:num_to_match);
else
    lead_device = 2;
    lag_device = 1;
    lag_times = times_1(1:num_to_match);
    lead_times = times_2(1:num_to_match);
end

mean_lag = mean(lag_times - lead_times);
end
