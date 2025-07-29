function realtime_nrem_detection()
% REALTIME_NREM_DETECTION
% Real-time EEG + EMG analysis and TTL pulse output for NREM detection
% Uses two DAQ sessions: input & output
clear, clc, close all

%% --- Configuration Parameters ---
params = get_params();

%% --- Setup DAQ Sessions ---
[s_in, ~] = setup_daq(params);

%% --- Calibration Period ---
params = calibrate_session(params);

% pass calibrated params data back into the acquisition object
for i = 1:numel(params.boxes)
    s_in.UserData(i).delta_thresh = params.boxes(i).delta_thresh;
    s_in.UserData(i).emg_thresh   = params.boxes(i).emg_thresh;
    s_in.UserData(i).params.boxes = params.boxes;
    s_in.UserData(i).index        = i;
end

%% --- Main Loop Start ---
fprintf('-- Starting acquisition. -- \n')

% start continuous background acquisition
start(s_in, "continuous");
disp("Running: " + s_in.Running);

% use small pause steps to see if that fixes the 10 s issue (it didn't)
t0 = tic;
while toc(t0) < params.dur
    pause(0.5);
end

% check the actual recording time
fprintf('Elapsed time: %.2f sec\n', toc(t0));

% stop session
stop(s_in);

%% -- Save data
shared = s_in.UserData;
save_session(params, shared);

end