function [s_in, s_out] = setup_daq(params)
    fprintf('Setting up DAQ sessions...\n');

    % Create input session for EEG and EMG
    s_in = daq("ni");
    s_in.Rate = params.fs;
    s_in.ScansAvailableFcnCount = params.fs;
    s_in.ScansAvailableFcn = @main_loop;

    % Shared data struct for state storage per box
    for i = 1:4
        if ~params.boxes(i).record
            continue;
        end
        
        shared(i) = struct( ...
            'delta_thresh', params.boxes(i).delta_thresh, ...
            'emg_thresh',   params.boxes(i).emg_thresh, ...
            'win', false(1, 5), ...
            'nrem_log', [], ...
            'eeg_data', [], ...
            'emg_data', [], ...
            'delta',    [], ...
            'emg_rms',  [], ...
            'ttl', [], ...
            'epoch_counter', 0, ...
            'params', params, ...
            'box_id', i ...
        ); %#ok<*AGROW>

        % Add EEG and EMG input channels per box
        eeg_ch = addinput(s_in, params.daq_id, params.boxes(i).eeg, 'Voltage');
        eeg_ch.TerminalConfig = 'SingleEnded';

        emg_ch = addinput(s_in, params.daq_id, params.boxes(i).emg, 'Voltage');
        emg_ch.TerminalConfig = 'SingleEnded';
    end
    fprintf('-- Added EEG and EMG input channels for all boxes. -- \n');

    % Create output session for TTL pulses
    s_out = daq("ni");
    s_out.Rate = params.fs; % Not strictly needed, but harmless

    % Add TTL output channels
    addoutput(s_out, params.daq_id, 0:1, 'Voltage');
    fprintf('-- Added TTL output channels %s and %s. --\n', s_out.Channels(1,1).ID, s_out.Channels(1,2).ID);

    % Save output session in each shared slot for callback use
    for i = 1:4
        shared(i).ttl_session = s_out;
    end

    % Assign shared struct array to input session UserData
    s_in.UserData = shared;
end
