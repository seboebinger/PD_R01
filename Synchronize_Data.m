%% only match the rising OR falling edge of the square wave
function [time_synced, data_1_synced, data_2_synced, FG_1_synced, FG_2_synced] = ...
    Synchronize_Data(FG_1, FG_2, time_1, time_2, data_1, data_2, edgeType)

% --- Preprocessing: Denoise and binarize square waves ---
FG_1_bin = smoothdata(FG_1, 'gaussian', 11) > 0.5;
FG_2_bin = smoothdata(FG_2, 'gaussian', 11) > 0.5;

% --- Edge detection: rising edges == 1, falling edged == 0 ---
if strcmpi(edgeType,'rising')
    edges_1 = find(diff(FG_1_bin) == 1);
    edges_2 = find(diff(FG_2_bin) == 1);
elseif strcmpi(edgeType,'falling')
    edges_1 = find(diff(FG_1_bin) == -1);
    edges_2 = find(diff(FG_2_bin) == -1);
else % default to falling cuz why not
    edges_1 = find(diff(FG_1_bin) == -1);
    edges_2 = find(diff(FG_2_bin) == -1);
end

% --- Convert indices to time values ---
times_1 = time_1(edges_1);
times_2 = time_2(edges_2);

% --- Match first N rising edges to estimate lag ---
num_to_match = min(500, min(length(times_1), length(times_2)));
if num_to_match < 1
    error('Not enough rising edges detected to perform synchronization.');
end

lags = times_2(1:num_to_match) - times_1(1:num_to_match);
mean_lag = mean(lags);  % estimate average lag

% --- Time shift to align FG_2 to FG_1 ---
adjusted_time_2 = time_2 - mean_lag;

% --- Define overlapping time range ---
t_start = max(min(time_1), min(adjusted_time_2));
t_end   = min(max(time_1), max(adjusted_time_2));
num_points = min(length(time_1), length(time_2));
time_synced = linspace(t_start, t_end, num_points);

% --- Resample/interpolate signals onto common time base ---
data_1_synced = interp1(time_1, data_1, time_synced, 'linear', 'extrap');
data_2_synced = interp1(adjusted_time_2, data_2, time_synced, 'linear', 'extrap');
FG_1_synced   = interp1(time_1, FG_1, time_synced, 'nearest', 0);
FG_2_synced   = interp1(adjusted_time_2, FG_2, time_synced, 'nearest', 0);

% --- Optional: Re-binarize function generator outputs if needed ---
% FG_1_synced = FG_1_synced > 0.5;
% FG_2_synced = FG_2_synced > 0.5;

% --- Debug readout ---
disp(['FG_1 first rising edge at: ', num2str(times_1(1))]);
disp(['FG_2 first rising edge at: ', num2str(times_2(1))]);
disp(['Estimated mean lag: ', num2str(mean_lag)]);
disp(['Adjusted time_2 starts at: ', num2str(min(adjusted_time_2))]);

end


% %% Check which produces the least lag
% function [time_synced, data_1_synced, data_2_synced, FG_1_synced, FG_2_synced] = ...
%     Synchronize_Data(FG_1, FG_2, time_1, time_2, data_1, data_2)
%
% % --- Preprocess: denoise and binarize ---
% FG_1_bin = smoothdata(FG_1, 'gaussian', 11) > 0.5;
% FG_2_bin = smoothdata(FG_2, 'gaussian', 11) > 0.5;
%
% % --- Detect edges ---
% rising_1 = find(diff(FG_1_bin) == 1);
% rising_2 = find(diff(FG_2_bin) == 1);
% falling_1 = find(diff(FG_1_bin) == -1);
% falling_2 = find(diff(FG_2_bin) == -1);
%
% % --- Convert to times ---
% rising_times_1 = time_1(rising_1);
% rising_times_2 = time_2(rising_2);
% falling_times_1 = time_1(falling_1);
% falling_times_2 = time_2(falling_2);
%
% % --- Match N edges ---
% N = 5;
% num_rising = min(N, min(length(rising_times_1), length(rising_times_2)));
% num_falling = min(N, min(length(falling_times_1), length(falling_times_2)));
%
% if num_rising < 1 && num_falling < 1
%     error('Not enough rising or falling edges detected.');
% end
%
% % --- Compute mean lag and adjusted time for both options ---
% lag_rise = inf;
% start_rise = inf;
% if num_rising >= 1
%     lags_rise = rising_times_2(1:num_rising) - rising_times_1(1:num_rising);
%     lag_rise = mean(lags_rise);
%     adjusted_rise_time_2 = time_2 - lag_rise;
%     start_rise = min(adjusted_rise_time_2);
% end
%
% lag_fall = inf;
% start_fall = inf;
% if num_falling >= 1
%     lags_fall = falling_times_2(1:num_falling) - falling_times_1(1:num_falling);
%     lag_fall = mean(lags_fall);
%     adjusted_fall_time_2 = time_2 - lag_fall;
%     start_fall = min(adjusted_fall_time_2);
% end
%
% % --- Choose better alignment method ---
% if start_rise <= start_fall
%     mean_lag = lag_rise;
%     adjusted_time_2 = time_2 - lag_rise;
%     edge_type = 'rising';
% else
%     mean_lag = lag_fall;
%     adjusted_time_2 = time_2 - lag_fall;
%     edge_type = 'falling';
% end
%
% % --- Define overlapping time base ---
% t_start = max(min(time_1), min(adjusted_time_2));
% t_end   = min(max(time_1), max(adjusted_time_2));
% num_points = min(length(time_1), length(time_2));
% time_synced = linspace(t_start, t_end, num_points);
%
% % --- Resample onto shared time base ---
% data_1_synced = interp1(time_1, data_1, time_synced, 'linear', 'extrap');
% data_2_synced = interp1(adjusted_time_2, data_2, time_synced, 'linear', 'extrap');
% FG_1_synced   = interp1(time_1, FG_1, time_synced, 'nearest', 0);
% FG_2_synced   = interp1(adjusted_time_2, FG_2, time_synced, 'nearest', 0);
%
% % --- Report ---
% disp(['Used edge type: ', edge_type]);
% disp(['Estimated mean lag: ', num2str(mean_lag)]);
% disp(['Adjusted time_2 starts at: ', num2str(min(adjusted_time_2))]);
%
% end