function [s_in, s_out] = setup_daq(params)
    fprintf('Setting up DAQ sessions...\n');

    %% --- Preallocate shared struct array for 4 boxes ---
    shared = repmat(struct(), 1, 4);

    % Create input session for EEG and EMG
    s_in = daq("ni");
    s_in.Rate = params.fs;
    s_in.ScansAvailableFcnCount = params.fs;
    s_in.ScansAvailableFcn      = @main_loop;

    % Loop over each box and configure if recording enabled
    for i = 1:4
        % thresholds
        shared(i).delta_thresh = params.boxes(i).delta_thresh;
        shared(i).td_thresh    = params.boxes(i).td_thresh;
        shared(i).emg_thresh   = params.boxes(i).emg_thresh;
        shared(i).delta_soft   = params.boxes(i).delta_thresh;
        shared(i).td_soft      = params.boxes(i).td_soft;
        shared(i).emg_soft     = params.boxes(i).emg_thresh;
        
        % bools for state detection
        shared(i).in_nrem      = false;
        shared(i).in_rem       = false;
        
        % moving window
        shared(i).win          = false(1, 8);
        
        % initialize actual session related data variables
        shared(i).eeg_data     = [];
        shared(i).emg_data     = [];
        shared(i).delta        = [];
        shared(i).td_ratio     = [];
        shared(i).emg_rms      = [];
        shared(i).ttl          = [];
        
        % housekeeping
        shared(i).params       = params;
        shared(i).box_id       = i;
        shared(i).start_time   = datetime('now');
        
        % prepare for ttl session
        shared(i).ttl_session  = [];  % will assign after s_out creation

        % Only add input channels if this box is set to record
        if params.boxes(i).record
            % Add EEG channel for box i
            eeg_ch = addinput(s_in, params.daq_id, params.boxes(i).eeg, 'Voltage');
            eeg_ch.TerminalConfig = 'SingleEnded';

            % Add EMG channel for box i
            emg_ch = addinput(s_in, params.daq_id, params.boxes(i).emg, 'Voltage');
            emg_ch.TerminalConfig = 'SingleEnded';
        end
    end

    fprintf('-- Added EEG and EMG input channels for all boxes set to record. --\n');

    %% --- Create output session for TTL pulses ---
    s_out = daq("ni");

    % Add two TTL output channels (for 2 outputs)
    addoutput(s_out, params.daq_id, 0:1, 'Voltage');
    fprintf('-- Added TTL output channels %s and %s. --\n', s_out.Channels(1, 1).ID, s_out.Channels(1, 2).ID);

    % Assign the TTL output session handle to all shared structs
    % This allows detect_nrem and detect_rem to send TTL pulses
    for i = 1:4
        % if we're not recording, no need to set up a session
        if params.boxes(i).record
            shared(i).ttl_session = s_out;
        end
    end

    % Save the shared struct array in the input session's UserData for use in callbacks
    s_in.UserData = shared;
end