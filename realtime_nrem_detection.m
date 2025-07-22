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
stop(s_in);

%% -- Save data
shared = s_in.UserData;

filename = [params.session_name, '_', datestr(now,'yyyymmdd_HHMMSS'), '.mat'];
warning('off', 'MATLAB:save:UnableToWriteObject');
save(filename, 'shared', 'params')
warning('on', 'MATLAB:save:UnableToWriteObject');

fprintf('-- Finished. -- \n')
end