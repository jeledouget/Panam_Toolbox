classdef SetOfSignals
    
    % SETOFSIGNALS Class containing information about a set of trials
    % e.g. a set of trials can contain the LFP signals for one subject and
    % one condition
    %
    % Properties:
    % Signals = matrix of 'Signal' (or 'Signal' subclass) instances
    % Infos = common information to all the signals included in the Signals property (1 x 1 containers.Map)
    % DimOrder = cell of strings with dimensions of the Signals property (eg. {'subject','trials'})
    % History = history of operations on the SetOfSignals instance (n x 2 string cells)
    
    
    
    %% properties
    
    properties
        Signals@Signal matrix; % matrix of 'Signal' or 'Signal' subclass instances
        Infos@struct;%containers.Map = containers.Map; % common information to all the signals included in the Signals property
        DimOrder@cell vector = {}; % cell of strings with dimensions of the Signals property
        History@cell matrix; % history of operations on the SetOfSignals instance
    end
    
    properties(Hidden)
        Temp; % store temporary information
    end
    
    
    
    %% methods
    
    methods
        
        %% constructor
        
        function self = SetOfSignals(varargin)
            if nargin > 1
                for i_argin = 1 : 2 : length(varargin)
                    switch lower(varargin{i_argin})
                        case 'signals'
                            self.Signals = varargin{i_argin + 1};
                        case 'infos'
                            self.Infos = varargin{i_argin + 1};
                        case 'dimorder'
                            self.DimOrder = varargin{i_argin + 1};
                        otherwise
                            warning(['Property ''' varargin{i_argin} ''' is not present in the SetOfSignals class or subclasses']);
                    end
                end
            end
            self.History{end+1,1} = datestr(clock);
            self.History{end,2} = 'Calling SetOfSignals constructor';
            if  ~isempty(varargin)
                self = self.setDefaults;
                self.checkInstance;
            end
        end
        
        
        %% set, get and check methods
        
        % set default values
        function self = setDefaults(self)
            self = self.setDefaultDimOrder;
        end
        
         % set default DimOrder property
        function self = setDefaultDimOrder(self)
            if isempty(self.DimOrder)
                nDims = ndims(self.Signals);
                self.DimOrder(1:nDims-1) = arrayfun(@(x) ['dim' num2str(x)],1:nDims-1,'UniformOutput',0);
                self.DimOrder{nDims} = 'trials';
            end
        end
           
        % check instance properties
        function checkInstance(self)
            self.checkSignals;
            self.checkDimOrder;
        end
        
        % check Data property
        function checkSignals(self)
            if isempty(self.Signals)
                error('Signals property is empty: cannot instantiate SetOfSignals');
            end
        end
        
        % check DimOrder property
        function checkDimOrder(self)
            if size(self.DimOrder,2) ~= ndims(self.Signals)
                error('the number of dimensions in DimOrder property does not correspond to the number of dimensions in Signals property');
            end
        end
        
        
        %% other methods
        
        % dim index
        function dimIndex = dimIndex(self, dimString)
            dimIndex = find(strcmpi(self.DimOrder, dimString));
            if isempty(dimIndex)
                error(['dimension ''' dimString ''' does not exist']);
            end
        end
        
        % clear hidden Temp property
        function self = clearTemp(self)
            self.Temp = [];
        end
                
        
        %% external methods
        
        output = apply(self, func, varargin)
        output = applyToElements(self, func, elementArgs,  varargin)
        newSet = removeSignals(self, selectedSignals, keepInTemp);
        newSet = retrieveSignals(self, selectedSignals);
        newSet = concatenate(self, otherSets, dimension, forceMode)
        newSet = sort(self, filter)
        avgSet = avgSignals(self)
        
        % to do
        
                
    end
    
end

