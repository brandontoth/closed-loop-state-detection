function params = calibrate_session(params)
    % Prompt user to select the folder containing baseline data
    calibration_path = params.calibration_folder;
    if isempty(calibration_path)
        fprintf('No calibration file selected, skipping. \n');
        return;
    end

    for i = 1:4
        if ~params.boxes(i).detect
            continue;
        end

        fprintf('Calibrating for Box %d...', i);

        % Construct file path
        box_id    = sprintf('box%d', i);
        data_file = fullfile(calibration_path, [box_id '_baseline.mat']);

        if ~exist(data_file, 'file')
            warning('Baseline file not found for %s. Skipping...', box_id);
            continue;
        end

        % Load delta and EMG RMS from saved baseline session
        data = load(data_file);
        if ~isfield(data, 'delta') || ~isfield(data, 'emg_rms')
            warning('delta or emg_rms missing in file %s. Skipping...', data_file);
            continue;
        end

        delta   = data.delta;
        emg_rms = data.emg_rms;

        % Run k-means on EMG RMS to classify high vs low EMG
        idx   = kmeans(emg_rms, 2);
        mean1 = mean(emg_rms(idx == 1));
        mean2 = mean(emg_rms(idx == 2));

        % Identify which cluster is high EMG
        if mean1 > mean2
            high_emg_idx = (idx == 1);
        else
            high_emg_idx = (idx == 2);
        end

        % Calculate calibration thresholds based on high EMG periods
        emg_thresh   = mean(emg_rms(high_emg_idx)) - std(emg_rms);
        delta_thresh = mean(delta  (high_emg_idx)) + std(delta);

        % Store in params
        params.boxes(i).emg_thresh   = emg_thresh;
        params.boxes(i).delta_thresh = delta_thresh;

        fprintf('Box %d thresholds: EMG = %.3f, Delta = %.3f\n', i, emg_thresh, delta_thresh);
    end

    fprintf('Calibration complete.\n');
end
