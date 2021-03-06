% Method for class 'Signal' and subclasses
%  sortElements : sort the elements of a Signal vector
% INPUTS
    % 
% OUTPUT
    % sortedSignal : sorted Signal elements


function sortedSignal = sortElements(self, filter)

% check that self is a vector
if ~isvector(self)
    self = self(:);
    warning('object has been ordered as a column');
end

% init
sortedSignal = self;

% switch between filters
if isnumeric(filter) && isvector(filter)
    if ~isequal(sort(filter), 1:length(self))
        error('to sort by order, you must input a permutation of the elements opf the Signal object');
    end
    order = filter;
elseif isa(filter, 'function_handle')
    res = arrayfun(filter, self, 'UniformOutput', 0);
    if all(cellfun(@isnumeric,res))
        res = cell2mat(res);
    end
    [~, order] = sort(res);
elseif ischar(filter)
    res = arrayfun(@(x) x.Infos(filter), self, 'UniformOutput', 0);
    if all(cellfun(@isnumeric,res))
        res = cell2mat(res);
    end
    [~, order] = sort(res);
end

% sort
sortedSignal = sortedSignal(order);
    

end
