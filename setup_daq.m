function s = setup_daq(params)
    fprintf('Setting up DAQ session...\n');
    s = daq("ni");
    s.Rate = params.fs;
    
    try
        ch1 = addinput(s, params.daq_id, params.eeg_id, 'Voltage');
        ch1.TerminalConfig = 'SingleEnded';
        ch2 = addinput(s, params.daq_id, params.emg_id, 'Voltage');
        ch2.TerminalConfig = 'SingleEnded';
        fprintf('Added EEG and EMG input channels.\n');
    
        addoutput(s, params.daq_id, params.ttl_id, 'Voltage');
        fprintf('Added TTL output channel.\n');
    catch ME
        error('DAQ setup failed: %s', ME.message);
    end
end