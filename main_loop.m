function main_loop(s, params)
    t_str    = tic;
    next_ttl = zeros(params.buffer, 1);

    % Storage
    save_eeg      = [];
    save_filt_eeg = [];
    save_emg      = [];
    save_filt_emg = [];
    save_delta    = [];
    save_rms_emg  = [];
    save_ttl      = [];
    nrem_log      = [];

    % Power histories
    delta_power_history = [];
    emg_rms_history     = [];

    % Rolling NREM window
    nrem_window = zeros(1, 5);  % Store last 5 NREM detections

    try
        while toc(t_str) < params.dur
            loop_t = tic;

            data = readwrite(s, next_ttl);
            eeg_chunk = data{:, 1};
            emg_chunk = data{:, 2};

            filt_eeg = filtfilt(params.b_eeg,  params.a_eeg,  eeg_chunk);
            filt_emg = filtfilt(params.b_comb, params.a_comb, emg_chunk);

            [pxx, f] = pwelch(filt_eeg, hanning(params.buffer), params.buffer/2, ...
                params.buffer, params.fs);

            delta_idx = f >= params.delta_frq(1) & f <= params.delta_frq(2);
            current_delta   = trapz(f(delta_idx), pxx(delta_idx));
            current_emg_rms = rms(filt_emg);

            delta_power_history = [delta_power_history, current_delta];
            emg_rms_history     = [emg_rms_history, current_emg_rms];

            if length(delta_power_history) > params.moving_average_window
                delta_power_history = delta_power_history(end - params.moving_average_window + 1:end);
                emg_rms_history     = emg_rms_history(end - params.moving_average_window + 1:end);
            end

            avg_delta = mean(delta_power_history);
            avg_emg   = mean(emg_rms_history);
            fprintf('Delta: %.3f, EMG RMS: %.3f\n', avg_delta, avg_emg);

            % Reset TTL vector
            next_ttl = zeros(params.buffer, 1);

            % --- Determine if current epoch is NREM ---
            is_nrem = avg_delta > params.delta_thresh && avg_emg < params.emg_thresh;

            % --- Update NREM detection window ---
            nrem_window = [nrem_window(2:end), is_nrem];

            % --- Trigger TTL if ≥3 out of last 5 epochs were NREM ---
            if sum(nrem_window) >= 3
                fprintf('Stable NREM detected: TTL sent.\n');
                ttl_samples = round(params.ttl_dur * params.fs);
                next_ttl(1:ttl_samples) = 1.0;
                nrem_log = [nrem_log; toc(t_str)];

                % Optional: prevent immediate re-triggering
                nrem_window(:) = 0;
            end

            % Save
            save_eeg      = [save_eeg;      eeg_chunk];
            save_filt_eeg = [save_filt_eeg; filt_eeg];
            save_emg      = [save_emg;      emg_chunk];
            save_filt_emg = [save_filt_emg; filt_emg];
            save_delta    = [save_delta;    avg_delta];
            save_rms_emg  = [save_rms_emg;  avg_emg];
            save_ttl      = [save_ttl;      next_ttl];

            % Visualization
            if params.vis && ishandle(params.fig_handle)
                set(params.eeg_line, 'YData', eeg_chunk);
                set(params.psd_line(1), 'XData', f, 'YData', pxx);
                set(params.emg_line, 'YData', emg_chunk);
                drawnow limitrate;
            end

            fprintf('Loop time: %.2f s\n', toc(loop_t));
        end
    catch ME
        fprintf(2, 'Error: %s\n', ME.message);
        if s.Running
            stop(s);
        end
    end

    % Save data
    filename = [params.session_name, '_', datestr(now,'yyyymmdd_HHMMSS'), '.mat'];
    save(filename, 'save_eeg', 'save_filt_eeg', 'save_emg', 'save_filt_emg', ...
        'save_delta', 'save_rms_emg', 'save_ttl', 'params', 'nrem_log');
    fprintf('Data saved to %s\n', filename);

    try
        stop(s);
    catch
        warning('DAQ could not be stopped.');
    end
    fprintf('DAQ session stopped. Done.\n');
end
