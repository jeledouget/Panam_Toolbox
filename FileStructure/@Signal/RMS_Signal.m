% RMS_Signal: compute the Root Mean Square of the Signal over a defined Time Window
% around each time point. Default window is 1s
% NaNs are affected when the RMS can't be computed (not enough points on
% left or right side)
% INPUTS
    % timeWindow : length of the time window on which the RMS is computed (default = 1)
% OUTPUT
    % RmsSignal : RMS signal

    

function RmsSignal = RMS_Signal(self, timeWindow)

% handles default parameters
if nargin < 2 || isempty(timeWindow)
    timeWindow = 1;
end

% copy of the object
RmsSignal = self;

% compute RMS
temp_data = RmsSignal.Data .^ 2; % square signal
nSamplesHalf = round(timeWindow * RmsSignal.Fech / 2); % number of samples 
for ii = 1:length(RmsSignal.Data)
    if ii <= nSamplesHalf || ii >= size(temp_data,2) - nSamplesHalf
        RmsSignal.Data(:,ii) = nan;
    else
        RmsSignal.Data(:,ii) = sqrt(mean(temp_data(:,ii-nSamplesHalf:ii+nSamplesHalf),2));
    end
end

% history
zeroMeanSignal.History{end+1,1} = datestr(clock);
zeroMeanSignal.History{end,2} = ...
        ['Root Mean Square of the signal over a time window of ' num2str(timeWindow) 's'];

end