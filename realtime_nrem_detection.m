function realtime_nrem_detection()
% REALTIME_NREM_DETECTION
% Real-time EEG + EMG analysis and TTL pulse output for NREM detection
% Uses two DAQ sessions: input & output
clear, clc, close all

%% --- Configuration Parameters ---
params = get_params();

%% --- Setup DAQ Sessions ---
[s_in, ~] = setup_daq(params);

%% --- Main Loop Start ---
fprintf('-- Starting acquisition. -- \n')

start(s_in, "continuous");
disp("Running: " + s_in.Running);
pause(params.dur);
keyboard
stop(s_in);

%% -- Save data
shared = s_in.UserData;
save_session(params, shared);

end