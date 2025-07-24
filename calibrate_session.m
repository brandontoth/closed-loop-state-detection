function params = calibrate_session(params)
    if ~isempty(params.calibration_folder)
    else
        % if we're doing baseline recording, just set to 1
        params.delta_thresh = 1;
        params.emg_thresh   = 1;
    end
end