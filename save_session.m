function save_session(params, shared)
    %% save raw data to local storage
    date = datestr(now, 'yyyymmdd');

    % local folder to save to (automate?)
    local_folder = 'vlpag_ne';
    local_full   = params.session_name;
    for i = 1:length(params.boxes)
        if ~params.boxes(i).record
            continue;  % Skip boxes that were not set to record
        end
        local_full = [local_full, '_', params.boxes(i).mouse_id]; %#ok<*AGROW>
    end

    % build path/file names
    local_name = [local_full, '_',  datestr(now,  'yymmdd_HHMMSS'), '.mat'];
    local_save = ['F:\Nidaq_data\', local_folder, '\' , date, '\'];

    % make dir if needed
    if isempty(dir(local_save)), mkdir(local_save); end

    % save shared file, ignore warning about acquisition object
    warning('off', 'MATLAB:save:UnableToWriteObject');
    save([local_save, local_name], 'shared', 'params')
    warning('on',  'MATLAB:save:UnableToWriteObject');
    
    %% save split files to dropbox
    for i = 1:numel(shared)
        if ~params.boxes(i).record
            continue;  % Skip boxes that were not set to record
        end

        % build path/file names
        file_name = [params.boxes(i).mouse_id, '_', date];
        file_save = ['C:\Users\batoth\University of Michigan Dropbox\MED-burgesslab\' ...
            'BurgessLab_data_transfer\AccuSleep_NT\', params.boxes(i).mouse_id, '\', date, '\'];
        
        % make dir if needed
        if isempty(dir(file_save)), mkdir(file_save); end
        
        % filter EEG/EMG before saving
        EEG = filtfilt(params.b_eeg,  params.a_eeg,  shared(i).eeg_data);
        EMG = filtfilt(params.b_comb, params.a_comb, shared(i).emg_data);
        ttl = shared(i).ttl;

        % create AccuSleep labels file
        labels = zeros(floor(length(EEG) / (params.epoch * params.fs)), 1) + 4;
        
        % save everything
        save([file_save, 'EEG_',    file_name], 'EEG');
        save([file_save, 'EMG_',    file_name], 'EMG');
        save([file_save, 'ttl_',    file_name], 'ttl');
        save([file_save, 'labels_', file_name], 'labels');
    end
    
    %% yay we're done
    fprintf('-- Finished. -- \n')
end