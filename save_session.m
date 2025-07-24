function save_session(params, shared)
% we want to save to two different locations:
% 1) save all the raw data to a local drive (F:)
% 2) save raw data + split out EEG/EMG/labels/ttl files to dropbox
% this should make it easy to grab the params + labels file
% for doing the calibrate step after a baseline recording

%% save raw files to local storage
date = datestr(now, 'yyyymmdd');
local_folder = 'vlpag_ne'; % probably want to automate this...

% create local file names/paths
local_name = [params.session_name, '_', datestr(now, 'yymmdd_HHMMSS'), '.mat'];
local_save = ['F:\Nidaq_data\', local_folder, '\' , date, '\'];

% make the dir if needed
if isempty(dir(local_save))
    mkdir(local_save)
end

% save everything, suppress warning
warning('off', 'MATLAB:save:UnableToWriteObject');
save([local_save, local_name], 'shared')
warning('on', 'MATLAB:save:UnableToWriteObject');

%% save raw + split files to dropbox
% create dropbox file names/paths
file_name = [params.session_name, '_', date];
file_save = ['C:\Users\batoth\University of Michigan Dropbox\MED-burgesslab\' ...
    'BurgessLab_data_transfer\AccuSleep_NT\', params.session_name, '\', date, '\'];

% filters for cleaning up the data
% why don't I just save the cleaned up data during acquisition...
EEG = filtfilt(params.b_eeg,  params.a_eeg,  shared.eeg_data);
EMG = filtfilt(params.b_comb, params.a_comb, shared.emg_data);
ttl = shared.ttl;
labels = zeros(floor(length(EEG) / params.epoch * params.fs), 1) + 4;

% make the dir if needed
if isempty(dir(file_save))
    mkdir(file_save)
end

% save everything
save([file_save, 'EEG_', file_name], 'EEG');
save([file_save, 'EMG_', file_name], 'EMG');
save([file_save, 'ttl_', file_name], 'ttl');
save([file_save, 'labels_', file_name], 'labels');

%% yay, we're done
clc, fprintf('-- Finished. -- \n')

end