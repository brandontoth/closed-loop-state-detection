function shared = detect_rem(shared)
    params = shared.params;
    fs     = params.fs;

    % Skip detection if not enabled
    if ~params.boxes(shared.index).detect
        shared.ttl = [shared.ttl; zeros(fs, 1)];
        return;
    end
    
    % check if we're in REM sleep yet
    if ~shared.in_rem
        % hard threshold until we enter
        is_rem = (td_ratio > params.td_thresh) && (emg_r < params.emg_thresh);
    else
        % soft threshold once we're there
        is_rem = (td_ratio > params.td_soft);
    end

    % update window
    shared.win = [shared.win(2:end), is_rem];

    % ttl logic
    dur = round(fs * params.ttl_dur);
    if sum(shared.win) >= 3
        % in REM, update flag
        shared.in_rem = true;

        if rand() < 0.5  % 50% chance to stimulate
            ttl_val = zeros(1, 2);
            ttl_val(ceil(shared.index / 2)) = 5;
            write(shared.ttl_session, ttl_val);
            pause(params.ttl_dur);
            write(shared.ttl_session, [0, 0]);
            shared.ttl = [shared.ttl; ones(dur, 1); zeros(fs - dur, 1)];
        else
            shared.ttl = [shared.ttl; zeros(fs, 1)];
        end
    else
        shared.in_rem = false;
        shared.ttl = [shared.ttl; zeros(fs, 1)];
    end
end
