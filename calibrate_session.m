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

        if isfield(shared(i), 'emg_rms')
            emg_rms = shared(i).emg_rms;

            % Run k-means on EMG RMS to classify high vs low EMG
            idx   = kmeans(emg_rms, 2);
            mean1 = mean(emg_rms(idx == 1));
            mean2 = mean(emg_rms(idx == 2));

            % Identify which cluster is low EMG as a proxy for sleep
            if mean1 < mean2
                low_emg_idx = (idx == 1);
            else
                low_emg_idx = (idx == 2);
            end

            % Calculate calibration threshold based on low EMG periods
            emg_thresh = mean(emg_rms(low_emg_idx)) + std(emg_rms(low_emg_idx)) * 2;
            params.boxes(i).emg_thresh = emg_thresh;
        else
            warning('No EMG data found for Box %d. Skipping EMG threshold.', i);
            continue;
        end

        % Select detection mode
        if strcmpi(params.detection_mode, 'NREM') && isfield(shared(i), 'delta')
            % ---------- NREM Calibration ----------
            delta = shared(i).delta;

            % Use low EMG periods to estimate delta threshold
            delta_thresh = mean(delta(low_emg_idx));
            params.boxes(i).delta_thresh = delta_thresh;

            fprintf('-- Box %d NREM thresholds: EMG = %.3f, Delta = %.3f --\n', ...
                i, emg_thresh, delta_thresh);

        elseif strcmpi(params.detection_mode, 'REM') && isfield(shared(i), 'td_ratio')
            % ---------- REM Calibration ----------
            td = shared(i).td_ratio;

            td_thresh = mean(td) + 1.5 * std(td);
            td_soft   = mean(td);

            params.boxes(i).td_thresh = td_thresh;
            params.boxes(i).td_soft   = td_soft;

            fprintf('-- Box %d REM thresholds: EMG = %.3f, TD Hard = %.3f, TD Soft = %.3f --\n', ...
                i, emg_thresh, td_thresh, td_soft);
        else
            warning('Required fields not found for Box %d. Skipping REM/NREM threshold.', i);
        end
    end

    fprintf('-- Calibration complete. --\n');
end
