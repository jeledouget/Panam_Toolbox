classdef FreqSignal < Signal
    
    %FREQSIGNAL Class for freq-sampled signal objects
    % A signal has a Data and Freq component
    % 1st Dimension of Data property is for freq
    %
    % Freq = numeric vector for frequency samples

    
    
    %% properties
    
    properties
        Freq; % numeric vector for frequency samples
    end
    
    
    
    %% methods
    
    methods
        
        %% constructor
        
        function self = FreqSignal(data, varargin)
            subclassFlag = 0;
            indicesVarargin = []; % initiate vector for superclass constructor
            freq = 1:size(data,1); % default value for freq
            if nargin > 1
                for i_argin = 1 : 2 : length(varargin)
                    switch lower(varargin{i_argin})
                        case 'freq'
                            freq = varargin{i_argin + 1};
                        case 'subclassflag'
                            subclassFlag = varargin{i_argin + 1};
                        otherwise
                            indicesVarargin = [indicesVarargin i_argin i_argin+1];
                    end
                end
            end
            % call Signal constructor
            self@Signal('data', data, varargin{indicesVarargin}, 'subclassFlag', 1);
            self.Freq = freq;
            if ~subclassFlag
                self.History{end+1,1} = datestr(clock);
                self.History{end,2} = 'Calling FreqSignal constructor';
                self.setDefaults;
                self.checkInstance;
            end
        end
        
        
        %% set, get and check methods
        
        % set default values
        function self = setDefaults(self)
            
        end
        
        % check instance properties
        function checkInstance(self)
            
        end
        
        % set freq
        function self = set.Freq(self, freq)
            if ~isnumeric(freq) || ~isvector(freq)
                error('''Freq'' property must be set as a numeric vector');
            end
            self.Freq = freq;
        end
        
        
        %% other methods
        
        
        %% external methods
        
        
    end
end