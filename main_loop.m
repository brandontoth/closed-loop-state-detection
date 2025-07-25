function main_loop(src, ~)
    try
        shared_all = src.UserData;
        data = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        
        % iterate across all boxes
        for i = 1:4
            % pull the data for the current box
            shared = shared_all(i);
            params = shared.params;

            % Extract EEG and EMG data for this box
            eeg  = data(:, (i-1)*2 + 1);
            emg  = data(:, (i-1)*2 + 2);

            % Filter signals
            filt_eeg = filtfilt(params.b_eeg,  params.a_eeg,  eeg);
            filt_emg = filtfilt(params.b_comb, params.a_comb, emg);

            % pwelch power estimation
            [pxx, f]  = pwelch(filt_eeg, hanning(params.buffer), ...
                params.buffer / 2, params.buffer, params.fs);

            % extract AUC for the delta band
            delta_idx = f >= params.delta_frq(1) & f <= params.delta_frq(2);
            delta = trapz(f(delta_idx), pxx(delta_idx));

            % calculate root mean square of the EMG
            emg_r = rms(filt_emg);

            % Store raw data
            shared.eeg_data = [shared.eeg_data; eeg];
            shared.emg_data = [shared.emg_data; emg];
            shared.delta    = [shared.delta;    delta];
            shared.emg_rms  = [shared.emg_rms;  emg_r];
            shared.epoch_counter = shared.epoch_counter + 1;

            % Skip detection if not enabled
            if ~params.boxes(i).detect
                shared.ttl = [shared.ttl; zeros(params.fs, 1)];
                shared_all(i) = shared;
                continue
            end

            % Update detection window
            is_nrem = (delta > shared.delta_thresh) && (emg_r < shared.emg_thresh);
            shared.win = [shared.win(2:end), is_nrem];

            % TTL logic
            dur = round(params.fs * params.ttl_dur);
            if sum(shared.win) >= 3
                % check which output channel to send the ttl to
                ttl_val = zeros(1, 2);
                if i <= 2
                    ttl_val(1) = 5;  % Pulse on ao0
                else
                    ttl_val(2) = 5;  % Pulse on ao1
                end
                
                % write ttl pulse to output session
                write(shared.ttl_session, ttl_val);
                pause(params.ttl_dur);
                write(shared.ttl_session, [0, 0]);
                
                % also write to an array for visualization later
                shared.ttl = [shared.ttl; ones(dur, 1); zeros(params.fs - dur, 1)];
            else
                shared.ttl = [shared.ttl; zeros(params.fs, 1)];
            end
            
            % write all the data back to the shared file
            shared_all(i) = shared;
        end

        % Update UserData with all shared structs
        src.UserData = shared_all;
    catch ME
        disp('Error in main_loop:')
        disp(ME.message)
    end
end
