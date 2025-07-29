function main_loop(src, ~)
    try
        shared_all = src.UserData;

        % start counting the elapsed time if we're detecting NREM
        elapsed_time = seconds(datetime('now') - shared_all(1).start_time);

        % read in data from NIDAQ
        data = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        
        % add a column index to make sure we're in the correct box
        col_idx = 1;

        % iterate through boxes
        for i = 1:4
            % skip if we don't want to record this box
            if ~shared_all(i).params.boxes(i).record
                continue;
            end
            
            % read in current box data
            shared = shared_all(i);
            params = shared.params;
            
            % read eeg/emg and update column index
            eeg  = data(:, col_idx);
            emg  = data(:, col_idx + 1);
            col_idx = col_idx + 2;
            
            % filter eeg and emg
            filt_eeg = filtfilt(params.b_eeg,  params.a_eeg,  eeg);
            filt_emg = filtfilt(params.b_comb, params.a_comb, emg);
            
            % save the raw data
            shared.eeg_data = [shared.eeg_data; eeg];
            shared.emg_data = [shared.emg_data; emg];

            % Select detection mode
            if strcmpi(params.detection_mode, 'NREM')
                shared = detect_nrem(shared, filt_eeg, filt_emg, elapsed_time);
            elseif strcmpi(params.detection_mode, 'REM')
                shared = detect_rem(shared, filt_eeg, filt_emg);
            end
            
            % pass updated data back into shared object
            shared_all(i) = shared;
        end
        
        % update user data for the NIDAQ session
        src.UserData = shared_all;
        
    catch ME
        disp('Error in main_loop:')
        disp(ME.message)
    end
end