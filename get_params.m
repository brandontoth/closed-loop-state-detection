function params = get_params()
    %% default settings
    params.daq_id = 'Dev1'; % define DAQ
    params.ttl_id = 'ao0';  % output channel
    
    params.fs  = 1000;          % acquisition frequency
    params.nyq = params.fs / 2; % nyquist
    params.aq_dur = 1;          % data chunk duration
    params.epoch  = 5;          % epoch len
    params.buffer = round(params.fs * params.aq_dur); % number of points in a data chunk
    
    params.delta_frq = [0.5, 4]; % delta window
    params.theta_frq = [5, 10];  % theta window
    params.eeg_low   = 0.5;      % eeg low cutoff
    params.eeg_high  = 40;       % eeg high cutoff
    params.emg_low   = 30;       % emg low cutoff
    params.emg_high  = 100;      % emg high cutoff
    params.ord = 4;              % butter filter order
    
    params.ttl_dur = 0.1;   % ttl duration in s    
    params.vis     = false; % visualization bool
    
    params.ord_comb = 50;   % comb filter order
    params.fo = 60;         % comb frq
    params.q  = 35;         % comb quality factor
    params.bw = (params.fo / params.nyq) / params.q; % comb filter bandwidth
    
    params.moving_average_window = 5; % analysis window

    %% create filters
    [params.b_eeg,  params.a_eeg]  = butter(params.ord, [params.eeg_low, params.eeg_high] / params.nyq, 'bandpass');
    [params.b_emg,  params.a_emg]  = butter(params.ord, [params.emg_low, params.emg_high] / params.nyq, 'bandpass');
    [params.b_comb, params.a_comb] = iircomb(params.ord_comb, params.bw, 'notch');

    %% user defined settings
    % maybe incorporate this into a GUI at some point...
    name   = inputdlg('Input session name:', 'Input', [1 50]);
    time   = inputdlg('Input session length (h): ', 'Input', [1 50]);
    delay  = inputdlg('Input session start delay (h): ', 'Input', [1 50]);
    box_id = inputdlg('Input box ID (1-4): ', 'Input', [1 50]);
    box_id = str2double(box_id{1});

    params.session_name = char(name);
    params.dur   = str2double(time{1})  * 3600;
    params.delay = str2double(delay{1}) * 3600;

    if box_id == 1
        params.eeg_id = 'ai0';  % eeg channel
        params.emg_id = 'ai1';  % emg channel
    elseif box_id == 2
        params.eeg_id = 'ai2'; 
        params.emg_id = 'ai3';
    elseif box_id == 3
        params.eeg_id = 'ai8'; 
        params.emg_id = 'ai9';
    elseif box_id == 4
        params.eeg_id = 'ai10'; 
        params.emg_id = 'ai11';
    else
        error('Error. Not a valid box ID.')
    end

    if params.delay > 0
        fprintf('\n -- Delaying recording for %d hours. -- \n', params.delay / 3600)
        pause(params.delay)
    end 
end