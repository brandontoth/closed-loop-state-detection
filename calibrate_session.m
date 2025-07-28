function params = calibrate_session(params)
    % check that we have a calibration folder selected
    calibration_path = params.calibration_folder;
    if isempty(calibration_path)
        fprintf('-- No calibration file selected, skipping. --\n');
        return;
    end
    
    % get the file from the calibration folder
    f = dir(calibration_path);
    for i = 1:numel(f)
        if contains(f(i).name, 'mat')
            load([f(i).folder, '\', f(i).name], 'shared');
        end
    end
    
    % for each box, check if we need to do a calibration
    for i = 1:4
        if ~params.boxes(i).detect
            continue;
        end

        fprintf('-- Calibrating for Box %d --\n', i);

        delta   = shared(i).delta;
        emg_rms = shared(i).emg_rms;

        % Run k-means on EMG RMS to classify high vs low EMG
        idx   = kmeans(emg_rms, 2);
        mean1 = mean  (emg_rms(idx == 1));
        mean2 = mean  (emg_rms(idx == 2));

        % Identify which cluster is low EMG as a proxy for NREM sleep
        if mean1 < mean2
            low_emg_idx = (idx == 1);
        else
            low_emg_idx = (idx == 2);
        end

        % Calculate calibration thresholds based on low EMG periods
        emg_thresh   = mean(emg_rms(low_emg_idx)) + std(emg_rms(low_emg_idx)) * 2;
        delta_thresh = mean(delta  (low_emg_idx));

        % Store in params
        params.boxes(i).emg_thresh   = emg_thresh;
        params.boxes(i).delta_thresh = delta_thresh;

        fprintf('-- Box %d thresholds: EMG = %.3f, Delta = %.3f --\n', i, emg_thresh, delta_thresh);
    end

    fprintf('-- Calibration complete. --\n');
end
