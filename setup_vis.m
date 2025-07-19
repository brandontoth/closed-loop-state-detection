function [fig_handle, eeg_line, psd_line, emg_line] = setup_vis(params)
    fig_handle = figure('Name', 'Real-time EEG + EMG', 'NumberTitle', 'off');
    subplot(3,1,1);
    eeg_line = plot(nan(params.buffer, 1));
    title('Raw EEG'); xlabel('Samples'); ylabel('V'); grid on;
    
    subplot(3,1,2);
    psd_line = plot(nan(params.buffer / 2 + 1, 2)); hold on;
    xline(params.delta_frq(1), 'r--'); xline(params.delta_frq(2), 'r--');
    xline(params.theta_frq(1), 'b--'); xline(params.theta_frq(2), 'b--');
    title('PSD'); xlabel('Hz'); ylabel('V^2/Hz'); xlim([0 20]); grid on;
    
    subplot(3,1,3);
    emg_line = plot(nan(params.buffer, 1));
    title('Raw EMG'); xlabel('Samples'); ylabel('V'); grid on;
    drawnow;
end