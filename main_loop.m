function main_loop(src, ~)
    try
        params = src.UserData.params;
        shared = src.UserData;
    
        % Read available data from input session
        data = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        eeg  = data(:, 1);
        emg  = data(:, 2);
    
        % Filter signals
        filt_eeg = filtfilt(params.b_eeg,  params.a_eeg,  eeg);
        filt_emg = filtfilt(params.b_comb, params.a_comb, emg);
    
        % Power spectral density for delta band
        [pxx, f] = pwelch(filt_eeg, hanning(params.buffer), params.buffer / 2, params.buffer, params.fs);
        delta_idx = f >= params.delta_frq(1) & f <= params.delta_frq(2);
        delta = trapz(f(delta_idx), pxx(delta_idx));
        emg_r = rms(filt_emg);
    
        % Update detection window
        is_nrem = (delta > shared.delta_thresh) && (emg_r < shared.emg_thresh);
        shared.win = [shared.win(2:end), is_nrem];
        % disp(sum(shared.win))
        
        dur = params.fs * params.ttl_dur;
        % Trigger TTL if criteria met
        if sum(shared.win) >= 3
            % Write TTL pulse via output session
            write(shared.ttl_session, 5);  
            pause(params.ttl_dur);
            write(shared.ttl_session, 0);
            shared.ttl = [shared.ttl; ones(dur, 1); zeros(params.fs - dur, 1)]; 
        else
            shared.ttl = [shared.ttl; zeros(params.fs, 1)];
        end
    
        % Update counters and store data
        shared.epoch_counter = shared.epoch_counter + 1;

        shared.eeg_data = [shared.eeg_data; eeg];
        shared.emg_data = [shared.emg_data; emg];
        shared.delta    = [shared.delta;    delta];
        shared.emg_rms  = [shared.emg_rms;  emg_r];
    
        % Update UserData
        src.UserData = shared;
    catch ME
        disp('Error in main_loop:')
        disp(ME.message)
    end
end