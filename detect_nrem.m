function shared = detect_nrem(shared, filt_eeg, filt_emg, elapsed_time)
    params = shared.params;
    fs     = params.fs;

    % power estimation
    [pxx, f]  = pwelch(filt_eeg, hanning(params.buffer), params.buffer / 2, params.buffer, fs);
    delta_idx = f >= params.delta_frq(1) & f <= params.delta_frq(2);

    % get delta power and EMG root mean square
    delta = trapz(f(delta_idx), pxx(delta_idx));
    emg_r = rms(filt_emg);

    % save data
    shared.delta   = [shared.delta; delta];
    shared.emg_rms = [shared.emg_rms; emg_r];

    % Skip detection if not enabled
    if ~shared.params.boxes(shared.index).detect
        shared.ttl = [shared.ttl; zeros(fs, 1)];
        return;
    end

    % Check if we are within detection window
    if elapsed_time < params.detect_start_time || elapsed_time > params.detect_end_time
        shared.ttl = [shared.ttl; zeros(fs, 1)];
        shared.in_nrem = false;
        return;
    end

    % check if we're in NREM sleep yet
    if ~shared.in_nrem
        % hard threshold until we enter
        is_nrem = (delta > shared.delta_thresh) && (emg_r < shared.emg_thresh);
    else
        % soft threshold once we're there
        is_nrem = (delta > shared.delta_soft)   && (emg_r < shared.emg_soft);
    end

    % update window
    shared.win = [shared.win(2:end), is_nrem];

    % ttl logic
    dur = round(fs * params.ttl_dur);
    if sum(shared.win) >= 3
        % in NREM, update flag
        shared.in_nrem = true;

        % ttls initially 0
        ttl_val = zeros(1, 2);

        % check which box we're recording to send to appropriate output
        % channel
        ttl_val(ceil(shared.index / 2)) = 5;
        write(shared.ttl_session, ttl_val);
        pause(params.ttl_dur);
        write(shared.ttl_session, [0, 0]);

        % update variable for visualization later
        shared.ttl = [shared.ttl; ones(dur, 1); zeros(fs - dur, 1)];
    else
        % not enough to qualify, reset flag
        shared.in_nrem = false;
        shared.ttl = [shared.ttl; zeros(fs, 1)];
    end
end
