function outputStruct = panam_timeFrequencyCompute_GNG(inputStruct, param)


% description : panam_timeFrequency computes the time-frequency analysis for the signal contained in the inputStruct. Based on the FieldTrip toolbox.

% inputs :
% inputStruct : PANAM data structure with fields Infos, Trials, RemovedTrials
% param : parameters of the computation (structure)
% .method : 'mtmconvol' (default), 'wavelet', 'tfr'
% .foi : req of interest (default: 1:0.5:100)
% OR .foilim : frequency band of interest
% CASE MTMCONVOL : cf ft_freqanalysis.m
% .toi : the times on which the analysis windows should becentered
% (default : startTrialTime:0.02:endTrialTime)
% .tapsmofrq : amount of spectral smoothing (default : 4)
% .taper : (default = 'dpss')
% .t_ftimwin : length of time window (default : max([ones(1,length(param.foi)).*0.5 ; 2./param.foi]);
% CASE WAVELET and TFR : cf ft_freqanalysis.m
% .toi
% .width
% .gwidth
% .computeRemoved : 1 if computation of removedTrials is desired (default : 1)

% outputs
% outputStruct : PANAM data structure for timeFrequency data





%% input check

% inputStruct
if ~isstruct(inputStruct) || ...
        ~isfield(inputStruct, 'Infos') || ...
        ~isfield(inputStruct, 'Trials') || ...
        ~isfield(inputStruct, 'RemovedTrials')
    error('input structure must be a structure with mandatory fields Infos, Trials, RemovedTrials');
end

% inputStruct.Infos
if ~isfield(inputStruct.Infos,'SubjectCode') || ...
        ~isfield(inputStruct.Infos,'SubjectNumber') || ...
        ~isfield(inputStruct.Infos,'Type')
    error('input structure must have a field Infos with mandatory fields SubjectCode, SubjectNumber and Type');
end

% inputStruct.Trials
if ~isfield(inputStruct.Trials, 'PreProcessed')
    error('input structure must have a field Trials, which is a structure array with mandatory field PreProcessed');
end
if ~arrayfun(@(x) isa(x.PreProcessed, 'Signal'), inputStruct.Trials)
    error('inputStructure must have Trials.PreProcessed be Signal class structure');
end


%% parameters check and init

% default parameters
defaultParam.method = 'mtmconvol';
defaultParam.foi = 1:0.5:100;

% default toi
if isfield(param, 'timestep')
    timeStep = param.timestep;
else
    timeStep = 0.02; % default
end
tmpMin = arrayfun(@(x) min(x.PreProcessed.Time), inputStruct.Trials);
tmpMax = arrayfun(@(x) max(x.PreProcessed.Time), inputStruct.Trials);
defaultParam.toi = min(tmpMin):timeStep:max(tmpMax);

defaultParam.tapsmofrq = 4;
defaultParam.taper = 'dpss';
defaultParam.t_ftimwin = max([ones(1,length(defaultParam.foi)).*0.2 ; 3./defaultParam.foi]);
defaultParam.computeRemoved = 1;
defaultParam.output = 'pow';
defaultParam.keeptrials = 'yes';
defaultParam.pad = []; % padding = data length

% check or affect parameters
if nargin < 2
    param = defaultParam;
else
    % foi
    if ~isfield(param,'foi') && ~isfield(param,'foilim')
        param.foi = defaultParam.foi;
    elseif isfield(param, 'foi') && ~isfield(param, 'foilim')
        if ~isnumeric(param.foi) || ~isequal(size(param.foi,1),1) || ~(param.foi > 0) || ~issorted(param.foi)
            error('the field ''foi'' of param structure must be a sorted numeric vector with positive values');
        end
    elseif isfield(param, 'foilim') && ~isfield(param, 'foi')
        if~isnumeric(param.foilim) || ~isequal(size(param.foi),[1 2]) || ~(param.foilim(1) > 0) || ~(param.foilim(2) > param.foilim(1))
            error('the field ''foi'' of param structure must be a numeric vector with 2 increasing positive values');
        end
    else % both field foi and foilim
        error('param structure cannot have both fields ''foi'' and ''foilim''');
    end
    %  keeptrials
    if ~isfield(param, 'keeptrials')
        param.keeptrials = defaultParam.keeptrials;
    elseif ~strcmp('yes',param.keeptrials) && ~strcmp('no',param.keeptrials)
        error('field ''keeptrials'' of the param structure must be ''yes'' or ''no''');
    end
    % computeRemoved
    if ~isfield(param, 'computeRemoved')
        param.computeRemoved = defaultParam.computeRemoved;
    elseif ~isequal(0,param.computeRemoved) && ~isequal(1,param.computeRemoved)
        error('field ''computeRemoved'' of the param structure must be 1 or 0');
    end
    % output
    if ~isfield(param, 'output')
        param.output = defaultParam.output;
    elseif ~ischar(param.output) || ~ismember(param.output,{'pow','fourier', 'powandcsd'})
        error('field ''output'' in param structure must be pow, fourier or powandcsd');
    end
    % method
    if ~isfield(param, 'method')
        param.method = 'mtmconvol';
    elseif ~ismember(param.method, {'mtmconvol', 'wavelet', 'tfr'})
        error('the field ''method'' of the param structure must be mtmconvol,  wavelet or tfr');
    end
    switch param.method
        case 'mtmconvol'
            % toi
            if ~isfield(param,'toi')
                param.toi = defaultParam.toi;
            elseif ~isnumeric(param.toi) || ~isequal(size(param.toi,1),1) || ~issorted(param.foi)
                error('the field ''toi'' of param structure must be a sorted numeric vector');
            end
            % taper
            if ~isfield(param, 'taper')
                param.taper = defaultParam.taper;
            end % warning : no check for other tapers
            % tapsmofrq
            if ~isfield(param, 'tapsmofrq')
                param.tapsmofrq = defaultParam.tapsmofrq;
            elseif ~isnumeric(param.tapsmofrq) || ~isequal(length(param.tapsmofrq),1) || ~(param.tapsmofrq > 0)
                error('field ''tapsmofrq'' in param structure must be a positive number');
            end
            % t_ftimwin
            if ~isfield(param, 't_ftimwin')
                param.t_ftimwin = defaultParam.t_ftimwin;
            elseif ~isnumeric(param.t_ftimwin) || ~isequal(size(param.t_ftimwin,1),size(param.foi)) || ...
                    ~(param.t_ftimwin > 0)
                error('field ''t_ftimwin'' in param structure must be a positive vector with same length as param.foi');
            end
            % pad
            if ~isfield(param, 'pad')
                param.pad = defaultParam.pad;
            elseif ~isnumeric(param.pad) || ~isequal(length(param.pad),1) || ~(param.pad >= 0)
                error('field ''pad'' in param structure must be a positive number');
            end
        otherwise
            % NO CHECK FOR OTHER METHODS YET
    end
end


%% compute analysis

% cfg
cfg.method = param.method; %mtmconvol
cfg.keeptrials = param.keeptrials;
cfg.output = param.output;
cfg.verbose = 0;
try cfg.toi = param.toi;end
try cfg.tapsmofrq = param.tapsmofrq;end
try cfg.foi = param.foi;end
try cfg.foilim = param.foilim;end
try cfg.taper = param.taper;end
try cfg.t_ftimwin = param.t_ftimwin;end
try cfg.pad = param.pad;end
try cfg.width = param.width;end
try cfg.gwidth = param.gwidth;end

% label
data.label = inputStruct.Trials(1).PreProcessed.Tag;

% trial and time
for i=1:length(inputStruct.Trials)
    data.trial{i} = inputStruct.Trials(i).PreProcessed.Data;
    data.time{i} = inputStruct.Trials(i).PreProcessed.Time;
    trialName{i} = inputStruct.Trials(i).PreProcessed.TrialName;
    trialNum(i) = inputStruct.Trials(i).PreProcessed.TrialNum;
end

% compute
freq = ft_freqanalysis(cfg, data);
freq.analyse = 'timefrequency';
freq.label = data.label;
freq.TrialName = trialName;
freq.TrialNum = trialNum;


% removed trials
data.trial = [];
data.time = [];
trialName = [];
trialNum = [];
if param.computeRemoved && ~isempty(inputStruct.RemovedTrials)
    for i=1:length(inputStruct.RemovedTrials)
        data.trial{i} = inputStruct.RemovedTrials(i).PreProcessed.Data;
        data.time{i} = inputStruct.RemovedTrials(i).PreProcessed.Time;
        trialName{i} = inputStruct.RemovedTrials(i).PreProcessed.TrialName;
        trialNum(i) = inputStruct.RemovedTrials(i).PreProcessed.TrialNum;
    end
    % compute
    freq_removed = ft_freqanalysis(cfg, data);
    freq_removed.analyse = 'timefrequency';
    freq_removed.label = data.label;
    freq_removed.TrialName = trialName;
    freq_removed.TrialNum = trialNum;
end

%% update Infos

Infos = inputStruct.Infos;
Infos.Type = [Infos.Type '_TimeFreq_' upper(param.output)];

%% output

outputStruct.TimeFreqData = freq;
if param.computeRemoved && ~isempty(inputStruct.RemovedTrials)
    outputStruct.TimeFreqRemovedTrials = freq_removed;
end
outputStruct.Infos = Infos;
outputStruct.Param = param;
outputStruct.History{1,1} = datestr(clock);
outputStruct.History{1,2} = ['Creation of the time frequency structure from signal structure ' inputStruct.Infos.FileName];


end