function realtime_nrem_detection()
% REALTIME_NREM_DETECTION
% Real-time EEG + EMG analysis and TTL pulse output for NREM detection
% Requires: MATLAB Data Acquisition Toolbox, NI device
clear, clc, close all

%% --- Configuration Parameters ---
params = get_params();

%% --- Setup DAQ ---
s = setup_daq(params);

%% --- Design Filters ---
[params.b_eeg,  params.a_eeg] = butter(params.ord, [params.eeg_low, params.eeg_high] / params.nyq, 'bandpass');
[params.b_emg,  params.a_emg] = butter(params.ord, [params.emg_low, params.emg_high] / params.nyq, 'bandpass');
[params.b_comb, params.a_comb] = iircomb(params.ord_comb, params.bw, 'notch');

%% --- Visualization Setup ---
if params.vis
    [params.fig_handle, params.eeg_line, params.psd_line, params.emg_line] = setup_vis(params);
end

%% --- Calibration Period ---
% fprintf('Calibrating thresholds using 60 seconds of baseline data...\n');
% [delta_thresh, emg_thresh] = calibrate_session(s, params);
params.delta_thresh = 0.007;
params.emg_thresh = 0.08;

%% --- Main Loop ---
main_loop(s, params);

end




    



