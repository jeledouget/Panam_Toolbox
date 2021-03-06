% Method for class 'SampledTimeSignal'
% Resample a 'SampledTimeSignal' object to a specified sampling frequency
% INPUTS
% newFreq : new sampling frequency
% OUTPUT
% resampledSignal : resampled 'Signal' object


function resampledSignal = resampling(self, newFreq, tol)

% copy of the object
resampledSignal = self;

if nargin < 3 || isempty(tol)
    tol = 1e-6; % default
end

for ii = 1:numel(self)
    % dimensions of data
    dims = size(self(ii).Data);
    
    % get old Freq
    oldFreq = self(ii).Fs;
    
    % compute resampling
    [n, k] = rat(newFreq / oldFreq, newFreq / oldFreq * tol);
    data = resample(self(ii).Data,n, k);
    dims(1) = size(data,1);
    resampledSignal(ii).Data = reshape(data, dims);
    resampledSignal(ii).Time = self(ii).Time(1)+ 1. / newFreq * (0:size(resampledSignal(ii).Data,1)-1);
    resampledSignal(ii).Fs = newFreq;
    
    % check
    resampledSignal(ii).checkTime;
    
    % history
    resampledSignal(ii).History{end+1,1} = datestr(clock);
    resampledSignal(ii).History{end,2} = ...
        ['Resampling : from ' num2str(oldFreq) ' to ' num2str(newFreq)];
end

end

