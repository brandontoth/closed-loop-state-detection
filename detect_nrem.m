function shared = detect_nrem(shared, elapsed_time)
    params = shared.params;
    fs     = params.fs;

    % Skip detection if not enabled for this box
    if ~params.boxes(shared.box_id).detect
        shared.ttl = [shared.ttl; zeros(fs, 1)];
        return;
    end

    % Skip detection outside of time window
    if elapsed_time < params.detect_start || elapsed_time > params.detect_stop
        shared.ttl = [shared.ttl; zeros(fs, 1)];
        shared.in_nrem = false;
        return;
    end

    % Get most recent values
    delta  = shared.delta  (end);
    emg_r  = shared.emg_rms(end);

    % Apply hard vs. soft thresholds depending on current NREM state
    if ~shared.in_nrem
        is_nrem = (delta > shared.delta_thresh) && (emg_r < shared.emg_thresh);
    else
        is_nrem = (delta > shared.delta_soft)   && (emg_r < shared.emg_soft);
    end

    % Update sliding detection window
    shared.win = [shared.win(2:end), is_nrem];

    % Check if we've met NREM criteria
    dur = round(fs * params.ttl_dur);
    if sum(shared.win) >= 3
        % In NREM
        shared.in_nrem = true;

        % TTL signal: high on assigned output channel
        ttl_val = zeros(1, 2);
        ttl_val(ceil(shared.box_id / 2)) = 5;

        write(shared.ttl_session, ttl_val);
        pause(params.ttl_dur);  % hold TTL pulse
        write(shared.ttl_session, [0, 0]);

        % Record TTL output for visualization
        shared.ttl = [shared.ttl; ones(dur, 1); zeros(fs - dur, 1)];
    else
        % Not in NREM
        shared.in_nrem = false;
        shared.ttl = [shared.ttl; zeros(fs, 1)];
    end
end
