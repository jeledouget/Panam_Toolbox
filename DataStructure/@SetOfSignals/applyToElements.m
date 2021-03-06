% APPLYTOELEMENTS
% apply a function to each element of the Signals property in a
% SetOfSignals property, with variable arguments


function output = applyToElements(self, func, elementArgs,  varargin)

% element-specific arguments
if isa(elementArgs, 'function_handle')
    funcStr = funs2str(elementArgs);
    elementArgs = arrayfun(elementArgs, self, 'UniformOutput',0);
elseif isnumeric(elementArgs)
    elementArgs = num2cell(elementArgs);
elseif isstruct(elementArgs)
    elementArgs = arrayfun(@(x) x, elementArgs, 'UniformOutput',0);
end

% compute and store result of function on each element
tmp = cell(size(self.Signals));
for ii = 1:numel(self.Signals)
    tmp{ii} = func(self.Signals(ii),elementArgs{ii}, varargin{:});
end

% affect output : if tmp is full of Signals, then return a set
% otherwise return Signals
if isa(tmp{1},'Signal')
    output = self;
    dims = size(self.Signals);
    output.Signals = reshape([tmp{:}], dims);
    % history
    output.History{end+1,1} = datestr(clock);
    if exist('funcStr','var')
        output.History{end,2} = ...
            ['Apply function ''' func2str(func) ''' to all elements, with function arguments defined by ''' funcStr];
    else
        output.History{end,2} = ...
            ['Apply function ''' func2str(func) ''' to all elements, with element-dependant input function arguments'];
    end
else
    output = tmp;
end



end

