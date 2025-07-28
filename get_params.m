function params = get_params()
    % initialize structure
    params = struct();

    %% start user GUI
    fig = uifigure('Name', 'Session Parameters', 'Position', [100 100 450 620]);

    % Default values
    default_time  = '0';
    default_delay = '0';
    default_fs    = '1000';
    default_name  = 'session';
    params.calibration_folder = '';

    y = 570; spacing = 30; field_width = 220; label_width = 120;

    % Session name
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Session name:');
    name_field = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', default_name);

    % Sampling rate
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Sampling rate (Hz):');
    fs_field = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', default_fs);

    % Session duration
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Session length (h):');
    time_field = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', default_time);

    % Delay
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Start delay (h):');
    delay_field = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', default_delay);

    % Mouse IDs
    y = y - spacing*2;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Mouse ID (Box 1):');
    uid1 = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', 'Mouse1');
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Mouse ID (Box 2):');
    uid2 = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', 'Mouse2');
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Mouse ID (Box 3):');
    uid3 = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', 'Mouse3');
    y = y - spacing;
    uilabel(fig, 'Position', [20 y label_width 22], 'Text', 'Mouse ID (Box 4):');
    uid4 = uieditfield(fig, 'text', 'Position', [150 y field_width 22], 'Value', 'Mouse4');

    % NREM detection checkboxes
    y = y - spacing*2;
    uilabel(fig, 'Position', [20 y label_width+80 22], 'Text', 'Select boxes for detection:');
    cb1 = uicheckbox(fig, 'Text', 'Box 1', 'Position', [150 y-25 80 22]);
    cb2 = uicheckbox(fig, 'Text', 'Box 2', 'Position', [250 y-25 80 22]);
    cb3 = uicheckbox(fig, 'Text', 'Box 3', 'Position', [150 y-50 80 22]);
    cb4 = uicheckbox(fig, 'Text', 'Box 4', 'Position', [250 y-50 80 22]);

    % Recording checkboxes
    y = y - spacing*3;
    uilabel(fig, 'Position', [20 y label_width+80 22], 'Text', 'Select boxes to record from:');
    rec1 = uicheckbox(fig, 'Text', 'Box 1', 'Position', [150 y-25 80 22]);
    rec2 = uicheckbox(fig, 'Text', 'Box 2', 'Position', [250 y-25 80 22]);
    rec3 = uicheckbox(fig, 'Text', 'Box 3', 'Position', [150 y-50 80 22]);
    rec4 = uicheckbox(fig, 'Text', 'Box 4', 'Position', [250 y-50 80 22]);

    % Folder selection
    y = y - spacing*4;
    path_label = uilabel(fig, 'Text', 'No folder selected', ...
        'Position', [20 y+25 360 22], 'FontAngle', 'italic', 'HorizontalAlignment', 'left');
    folder_btn = uibutton(fig, 'Text', 'Select Folder', 'Position', [60 y-10 100 30], ...
        'ButtonPushedFcn', @(btn,event) select_folder(path_label)); %#ok<*NASGU>
    str_btn = uibutton(fig, 'Text', 'Start', 'Position', [200 y-10 100 30], ...
        'ButtonPushedFcn', @(btn,event) uiresume(fig));

    % Store and return params
    setappdata(fig, 'params', params);
    uiwait(fig);
    params = getappdata(fig, 'params');

    % Read user input
    params.session_name = char(name_field.Value);
    params.fs    = str2double(fs_field.Value);
    params.dur   = str2double(time_field.Value)  * 3600;
    params.delay = str2double(delay_field.Value) * 3600;

    mouse_ids   = {uid1.Value, uid2.Value, uid3.Value, uid4.Value};
    box_vals    = [cb1.Value,  cb2.Value,  cb3.Value,  cb4.Value];
    record_vals = [rec1.Value, rec2.Value, rec3.Value, rec4.Value];

    detect_boxes = find(box_vals);
    if numel(detect_boxes) > 2
        error('You can select at most 2 boxes for detection.');
    end

    eeg_map = {'ai0', 'ai2', 'ai8', 'ai10'};
    emg_map = {'ai1', 'ai3', 'ai9', 'ai11'};
    for i = 1:4
        params.boxes(i).eeg = eeg_map{i};
        params.boxes(i).emg = emg_map{i};
        params.boxes(i).mouse_id = mouse_ids{i};
        params.boxes(i).detect   = ismember(i, detect_boxes);
        params.boxes(i).record   = record_vals(i);

        % just set to 1 as default, this should never trigger a ttl
        params.boxes(i).delta_thresh = 1;
        params.boxes(i).emg_thresh   = 1;
    end

    close(fig)

    %%  Constants
    params.daq_id  = 'Dev1';
    params.nyq     = params.fs / 2;
    params.aq_dur  = 1;
    params.epoch   = 5;
    params.buffer  = round(params.fs * params.aq_dur);
    params.ttl_dur = 0.1;
    params.delta_frq = [0.5, 4];
    params.theta_frq = [5, 10];
    params.eeg_low   = 0.5;
    params.eeg_high  = 50;
    params.ord       = 4;
    params.ord_comb  = 50;
    params.fo = 60;
    params.q  = 35;
    params.bw = (params.fo / params.nyq) / params.q;

    [params.b_eeg,  params.a_eeg]  = butter (params.ord, [params.eeg_low, params.eeg_high] / params.nyq, 'bandpass');
    [params.b_comb, params.a_comb] = iircomb(params.ord_comb, params.bw, 'notch');

    if params.delay > 0
        fprintf('\n -- Delaying recording for %d hours. -- \n', params.delay / 3600);
        pause(params.delay)
    end
end

%% helper function to get the folder for calibration
function select_folder(path_label)
    folder = uigetdir;
    if folder ~= 0
        fig = path_label.Parent;
        params = getappdata(fig, 'params');
        params.calibration_folder = folder;
        setappdata(fig, 'params', params);
        truncated = truncate_path(folder, 50);
        path_label.Text = truncated;
        figure(fig); drawnow;
    else
        disp('Folder selection cancelled.');
    end
end

%% helper function to truncate file paths
function truncated = truncate_path(path_str, max_chars)
    if strlength(path_str) > max_chars
        truncated = "..." + extractAfter(path_str, strlength(path_str) - max_chars + 3);
    else
        truncated = path_str;
    end
end