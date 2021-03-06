% Method for class 'TimeFreqSignal'
% Concatenate 'TimeFreqSignal' objects
% INPUTS
    % otherSignals : vector array or cell of Signals objects to concatenate to
    % self
    % dim : key to the dimension along which mean remval is performed (ex :
    % time), or number of the dimension
% OUTPUT
    % newSignal : 'Signal' object with concatenation of otherSignals



function newSignal = concatenate(self, otherSignals, dim, subclassFlag)

% default
if nargin < 4 || isempty(subclassFlag)
    subclassFlag = 0;
end
if nargin < 3 || isempty(dim)
    dim = 'chan';
end
if ~iscell(otherSignals)
    otherSignals= num2cell(otherSignals);
end

% handle dimensions
if ischar(dim)
    dimName = dim;
    dim = self.dimIndex(dim);
else
    dimName = self.DimOrder(dim);
end

% concatenation
if (self.isNumFreq && all(cellfun(@isNumFreq, otherSignals))) || ...
        (~self.isNumFreq && all(~cellfun(@isNumFreq, otherSignals)))
    tmp = cellfun(@(x) x.Freq, otherSignals,'UniformOutput',0);
else
    error('to be concatenated frequencies must be of same type (numeric OR char)');
end
% check frequencies are consistent
freq = [{self.Freq}, tmp];
if self.isNumFreq % check that the closest frequencies in Freq keep the indices
    for ii=1:length(otherSignals)
        if any(arrayfun(@(x) panam_closest(self.Freq, otherSignals{ii}.Freq(x)) - x, 1:length(otherSignals{ii}.Freq)))
            error('frequency vectors differ : concatenation impossible');
        end
    end
elseif ~isequal(freq{:})
    error('frequencies must be the same for concatenation');
end
newSignal = self.concatenate@TimeSignal(otherSignals, dim, 1);
    
% if dimension is Frequency, concatenate frequencies, else check
% frequencies are consistent
if strcmpi(dimName, 'freq')
    freq = [self.Freq, tmp{:}];
    newSignal.Freq = freq;
else % check frequencies are consistent
    freq = [{self.Freq}, tmp];
    if self.isNumFreq % check that the closest frequencies in Freq keep the indices
        for ii=1:length(otherSignals)
            if any(arrayfun(@(x) panam_closest(self.Freq, otherSignals{ii}.Freq(x)) - x, 1:length(otherSignals{ii}.Freq)))
                error('frequency vectors differ : concatenation impossible');
            end
        end
    elseif ~isequal(freq{:})
        error('frequencies must be the same for concatenation');
    end
end

% concatenate freqMarkers
for ii = 1:length(otherSignals)
    newSignal.FreqMarkers = [newSignal.FreqMarkers, otherSignals{ii}.FreqMarkers];
end
newSignal.FreqMarkers = newSignal.FreqMarkers.unifyMarkers;

% history
if ~subclassFlag
    newSignal.History{end+1,1} = datestr(clock);
    newSignal.History{end,2} = ...
        'Concatenation of Signals';
end

end