function [delta_thresh, emg_thresh] = calibrate_session(params, state)
    % go to folder with the scored baseline data
    selpath = uigetdir();
    filedir = selpath;
    cd(filedir)
    
    % load EEG, EMG, and labels files
    files = dir('*.mat');
    for i = 1:length(files)
        if contains(files(i).name, ['EEG', 'EMG', 'labels'], 'IgnoreCase', true)
            load(files(i).name)
        end
    end
    
    % upsample labels file to match EEG length
    extend = extendLabels(labels, EEG, params.epoch, params.fs);

    % filter EEG and EMG to detect power
    filt_eeg = filtfilt(params.b_eeg, params.a_eeg, EEG);
    filt_emg = filtfilt(params.b_eeg, params.a_eeg, EMG);

    delta = abs(hilbert(filt_eeg));


end


% function [delta_thresh, emg_thresh] = calibrate_session(~, params)
%     calib_secs = 60;
%     n_chunks   = calib_secs / params.aq_dur;
%     delta_vals = zeros(1, n_chunks);
%     emg_vals   = zeros(1, n_chunks);
% 
%     % Create a temporary session with only the input channels
%     s_calib = daq("ni");
%     s_calib.Rate = params.fs;
% 
%     ch1 = addinput(s_calib, params.daq_id, params.eeg_id, 'Voltage');
%     ch1.TerminalConfig = 'SingleEnded';
%     ch2 = addinput(s_calib, params.daq_id, params.emg_id, 'Voltage');
%     ch2.TerminalConfig = 'SingleEnded';
% 
%     for i = 1:n_chunks
%         data = read(s_calib, params.buffer);
%         eeg_chunk = data{:,1};
%         emg_chunk = data{:,2};
%         filt_eeg = filtfilt(params.b_eeg,  params.a_eeg,  eeg_chunk);
%         filt_emg = filtfilt(params.b_comb, params.a_comb, emg_chunk);
% 
%         [pxx, f] = pwelch(filt_eeg, hanning(params.buffer), params.buffer/2, params.buffer, params.fs);
%         delta_idx = f >= params.delta_frq(1) & f <= params.delta_frq(2);
%         delta_vals(i) = trapz(f(delta_idx), pxx(delta_idx));
%         emg_vals(i)   = rms(filt_emg);
%     end
% 
%     delta_thresh = mean(delta_vals) + std(delta_vals);
%     emg_thresh   = mean(emg_vals)   - std(emg_vals);
% 
%     fprintf('Calibrated Delta Threshold: %.3f\n', delta_thresh);
%     fprintf('Calibrated EMG Threshold: %.3f\n',   emg_thresh);
% 
%     % Clean up calibration session
%     clear s_calib;
% end