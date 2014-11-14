function outputStruct = panam_timeFrequencyProcess( inputData, inputEvents, param )

%PANAM_TIMEFREQUENCYPROCESS Function to compute corrections and averages on
%Panam TimeFrequency structures

% inputData :
% must be a structure with field files : string or a cell array of
% strings (files addresses, partial or full), and with field path : folder in which to
% find the files (will be concatenated with the file address)
% OR a structure with field structures : PANAM_TIMEFREQUENCY structure or
% PANAM_TIMEFREQUENCY structure cell array
% Possible to mix both inputs but not recommended
% (OPTIONAL) inputEvents
% same as inputData but with PANAM_TRIALPARAMS as structure instead
% of PANAM_TIMEFREQUENCY
% (OPTIONAL) param:
% structure of parameters for the TIMEFREQUENCY preocessing operation


%% default parameters
% define the default parameters


%% check/affect parameters


%% check the format of input files and input events structures, and prepare for loading the data
% input files
if isfield(inputData,'files')
    if isempty(inputData.files)
        inputData = rmfield(inputData,'files');
    else % non-empty
        % one input as a string
        if ischar(inputData.files)
            inputData.files = {inputData.files};
        end
        if ~iscell(inputData.files) || ~all(cellfun(@ischar,inputData.files))
            error('''files'' field must be a string or cell array of strings');
        end
        % path
        if isfield(inputData,'path')
            if ischar(inputData.path)
                inputData.files = cellfun(@fullfile, ...
                    repmat({inputData.path},[1 length(inputData.files)]),inputData.files,'UniformOutput',0);
            else
                error('''path'' field in inputData must be a string indicating the common origin folder of the inputStruct files');
            end
        end
    end
end
% events
if nargin > 1
    if isempty(inputEvents)
        inputEvents = {};
        warning('no TrialParams have been input, therefore no events information : trials will be aligned with the trigger');
    end
    if isfield(inputEvents,'files')
        if isempty(inputEvents.files)
            inputEvents = rmfield(inputEvents,'files');
        else % non-empty
            % one input as a string
            if ischar(inputEvents.files)
                inputEvents.files = {inputEvents.files};
            end
            if ~iscell(inputEvents.files) || ~all(cellfun(@ischar,inputData.files))
                error('''files'' field must be a string or cell array of strings');
            end
            % path
            if isfield(inputEvents,'path')
                if ischar(inputEvents.path)
                    inputEvents.files = cellfun(@fullfile, ...
                        repmat({inputEvents.path},[1 length(inputEvents.files)]),inputEvents.files,'UniformOutput',0);
                else
                    error('''path'' field in inputEvents must be a string indicating the common origin folder of the inputStruct files');
                end
            end
        end
    end
else
    inputEvents = {};
    warning('no TrialParams have been input, therefore no events information : trials will be aligned with the trigger');
end


%% load the data

% load input structures from inputData.files
if isfield(inputData, 'files')
    for ii = 1:length(inputData.files)
        inputData.files{ii} = load(inputData.files{ii});
    end
end
% load input event structures from inputEvents.files
if nargin > 1
    if isfield(inputEvents, 'files')
        for ii = 1:length(inputEvents.files)
            inputEvents.files{ii} = load(inputEvents.files{ii});
        end
    end
end

% concatenate input files and input structures
if ~isfield(inputData,'structures')
    inputData.structures = {};
end
if ischar(inputData.structures)
    inputData.structures = {inputData.structures};
end
if ~iscell(inputData.structures)
    error('''structures'' field of inputData must be a cell array of time-frequency elements');
end
if isfield(inputData, 'files')
    for ii = 1:length(inputData.files)
        field = fieldnames(inputData.files{ii});
        for jj = 1:length(field)
            inputData.structures{end+1} = inputData.files{ii}.(field{jj});
        end
    end
end
TimeFreqData = inputData.structures;
clear inputData;

% concatenate input event files and input event structures
if ~isempty(inputEvents)
    if ~isfield(inputEvents,'structures')
        inputEvents.structures = {};
    end
    if ischar(inputEvents.structures)
        inputEvents.structures = {inputEvents.structures};
    end
    if ~iscell(inputEvents.structures)
        error('''structures'' field of inputEvents must be a cell array of PANAM TrialParams structures');
    end
    if isfield(inputEvents, 'files')
        for ii = 1:length(inputEvents.files)
            field = fieldnames(inputEvents.files{ii});
            for jj = 1:length(field)
                inputEvents.structures{end+1} = inputEvents.files{ii}.(field{jj});
            end
        end
    end
    Events = inputEvents.structures;
else
    Events = {};
end
clear inputEvents;


%% check the final structure

% check for identical structures, which throws an error
for ii = 1:length(TimeFreqData)-1
    for jj = ii+1:length(TimeFreqData)
        if isequal(TimeFreqData{ii}.Infos, TimeFreqData{jj}.Infos)
            error('replications of structures in the input - please check the unicity of the inputs');
        end
    end
end
if ~isempty(inputEvents)
    for ii = 1:length(Events)-1
        for jj =ii+1:length(Events)
            if isequal(Events{ii}.Infos, Events{jj}.Infos)
                error('replications of structures in the input - please check the unicity of the inputs');
            end
        end
    end
end

% check for correspondance between input structures and input events structures
if ~isempty(inputEvents)
    % check the correspondance of structures (inputs and events)
    indices = [];
    for ii = 1:length(TimeFreqData)
        stringData = ['GBMOV_POSTOP_' TimeFreqData{ii}.Infos.SubjectCode '_' TimeFreqData{ii}.Infos.MedCondition '_' ...
                      TimeFreqData{ii}.Infos.SpeedCondition];
        stringsEvents = cellfun(@(x) x.Infos.FileName,Events,'UniformOutput',0);
        ind = find(strcmpi(stringsEvents, stringData));
        if length(ind) == 1 % one unique corresponding structure
            indices(ii) = ind;
        else
            error(['TimeFreq data structure number ' num2str(ii) ' (at least) has no corresponding events structure']);
        end
    end
    Events = Events(indices); % reorganize events so that data and events structures indices correspond
end


%% average contacts
% define the contacts selected for each input structure
% then average over the contacts

% contacts selection filter
for ii = 1:length(param.contacts)
    switch param.contacts{ii}
        case {'avgAll','all'}
            contact_filter{ii} = [1 1 1 1 1 1];
        case {'avgRight','right'}
            contact_filter{ii} = [1 1 1 0 0 0];
        case {'avgLeft','left'}
            contact_filter{ii} = [0 0 0 1 1 1];
        case {1,2,3,4,5,6}
            contact_filter{ii} = zeros(1,6);
            contact_filter{ii}(param.contacts) = 1;
        otherwise
            error('param.contacts is wrong');
    end
end

% filter STN
if strcmpi(param.filter_STN,'yes')
    try
        locContacts_isSTN = load(param.locContacts_STN_filename);
    catch 
        error('param.locContacts_STN_filename unspecified or wrong. Needs to be the full adress of the loc file');
    end
    temp = fieldnames(locContacts_isSTN);
    locContacts_isSTN = locContacts_isSTN.(temp{1});
    for ii = 1:length(TimeFreqData)
        temp = find(strcmpi(locContacts_isSTN.SubjectNumber,TimeFreqData{ii}.SubjectNumber),1);
        if ~isempty(temp)
            STN_contacts{ii} = find(locContacts_isSTN(temp).dipole);
        else
            STN_contacts{ii} = 1:6;
            warning(['No STN localisation for subj number ' TimeFreqData{ii}.SubjectNumber ', all contacts considered in the STN']);
        end
        for jj = 1:length(param.contacts)
            % final filter
            contact_filter_final{jj,ii} = contact_filter{jj} .* STN_contacts{ii};
        end
    end
    % rewrite
    contact_filter = contact_filter_final;
end




%% trials filtering
% select trials which correpond to the specified filter


%% subject averaging
% in case of multi-subjcet inputs, average over subjects if option is selected


%% baseline correction
% apply baseline correction on the trials/subjects :
% decibel - zscore - ratio of change from baseline - (average t-maps ?)


%% events handling
% compute events averages


%% output affectation


%% visualization


end

