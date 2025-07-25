function save_session(params, shared)
    %% save raw data to local storage
    date = datestr(now, 'yyyymmdd');

    % local folder to save to (automate?)
    local_folder = 'vlpag_ne';
    local_full = params.session_name;
    for i = 1:length(params.boxes)
        local_full = [local_full, '_', params.boxes(i).mouse_id];
    end

    % build path/file names
    local_name = [local_full, '_', datestr(now, 'yymmdd_HHMMSS'), '.mat'];
    local_save = ['F:\Nidaq_data\', local_folder, '\' , date, '\'];

    % make dir if needed
    if isempty(dir(local_save)), mkdir(local_save); end

    % save shared file, ignore warning about acquisition object
    warning('off', 'MATLAB:save:UnableToWriteObject');
    save([local_save, local_name], 'shared')
    warning('on', 'MATLAB:save:UnableToWriteObject');
    
    %% save split files to dropbox
    file_name = [params.session_name, '_', date];
    file_save = ['C:\Users\batoth\University of Michigan Dropbox\MED-burgesslab\' ...
        'BurgessLab_data_transfer\AccuSleep_NT\', params.session_name, '\', date, '\'];
    if isempty(dir(file_save)), mkdir(file_save); end

    for i = 1:numel(shared)
        mouse_id = shared(i).params.boxes(i).mouse_id;
        EEG = filtfilt(params.b_eeg,  params.a_eeg,  shared(i).eeg_data);
        EMG = filtfilt(params.b_comb, params.a_comb, shared(i).emg_data);
        ttl = shared(i).ttl;
        labels = zeros(floor(length(EEG) / (params.epoch * params.fs)), 1) + 4;

        save([file_save, 'EEG_', mouse_id, '_', file_name], 'EEG');
        save([file_save, 'EMG_', mouse_id, '_', file_name], 'EMG');
        save([file_save, 'ttl_', mouse_id, '_', file_name], 'ttl');
        save([file_save, 'labels_', mouse_id, '_', file_name], 'labels');
    end

    clc, fprintf('-- Finished. -- \n')
end