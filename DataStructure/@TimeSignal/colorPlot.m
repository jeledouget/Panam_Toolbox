% COLORPLOT
% plot the 'TimeSignal' elements as columns of a colorplot (data vs.
% time bins). Each element must have the same Time property
% valid only if number of dimensions <= 2 in Data property
% WARNING : if several channels are present, they will be averaged or
% superimposed. default : averaged
% INPUTS :
% OUTPUTS :
    % h : handle to the axes of the plot


function h = colorPlot(self, varargin)

% default outputs
h = [];

% args & options
if ~isempty(varargin)
    if ischar(varargin{1}) % kvPairs
        varargin = panam_args2struct(varargin);
    else % structure
        varargin = varargin{1};
    end
else
    varargin = [];
end
defaultOption.newFigure = 'yes'; % by default : a new figure is created
defaultOption.channels = 'grid'; % default : 1 subplot per channel
defaultOption.title = '';
defaultOption.colormap = 'lines'; % default colormap for plots
defaultOption.xaxis = 'auto';
defaultOption.events = 'yes';
defaultOption.smooth = [1 1 1 1];% nb of points and std dev for gaussian smoothing. Default : no smoothing
defaultOption.eventColormap = 'lines'; % use the colormap 'lines' to draw events
option = setstructfields(defaultOption, varargin);

% case empty
if isempty(self)
    if option.newFigure
        figure;
    end
    return;
end

% TODO : check inputs
if ~all(arrayfun(@isNumTime, self)) || ~any(arrayfun(@isNumTime, self))
    error('Time property of the elements of the TimeSignal must be all numeric or all discrete');
end

% figure
if strcmpi(option.newFigure, 'yes')
    v = get(0, 'MonitorPosition'); % avoid Java isssues
    v1 = v(1,:);
    v1(1) = v1(1) - 1;
    sumX = sum(v(:,3));
    v1 = v1 ./ [sumX v1(4) sumX v1(4)]; % normalize
    figure('Name',option.title,'units','normalized','outerposition',v1)
end

% make self a column
self = self(:);

% check that Time property is the same for each element of self
self = self.adjustTime;

% init events
if strcmpi(option.events, 'yes')
    [eventNames, eventColors, legStatus, legLabels, legHandles] =  init_events(self, option);
end

% create data
switch option.channels
    case 'superimpose'
        channels = {'All Channels'};
        tmp = [];
        events{1} = {};
        for ii = 1:numel(self)
            tmp = cat(2, tmp, self(ii).Data);
            if strcmpi(option.events, 'yes')
                events{1}(end+1:end+size(self(ii).Data, 2)) = {self(ii).Events};
            end
        end
        data = {tmp'};
    case 'grid'
        channels = arrayfun(@(x) x.ChannelTags, self, 'UniformOutput',0);
        [channels, order] = unique([channels{:}]);
        [~,order] = sort(order);
        channels = channels(order);
        for jj = 1:numel(channels)
            tmp = [];
            events{jj} = {};
            for ii = 1:numel(self)
                indChan = find(strcmpi(self(ii).ChannelTags, channels{jj}),1);
                if ~isempty(indChan)
                    tmp = cat(2, tmp, self(ii).Data(:,indChan));
                    if strcmpi(option.events, 'yes')
                        events{jj}{end+1} = self(ii).Events;
                    end
                end
            end
            data{jj} = tmp';
        end
end

% smooth data with gaussian filter
nPointsSmoothHor = option.smooth(1);
nPointsSmoothVert = option.smooth(2);
stdDevSmoothHor = option.smooth(3);
stdDevSmoothVert = option.smooth(4);
gaussFilter = customgauss([nPointsSmoothVert nPointsSmoothHor], stdDevSmoothVert, stdDevSmoothHor,0,0,1,[0 0]);
ratio = sum(sum(gaussFilter));
for ii = 1:numel(data)
    data{ii} = conv2(data{ii}, gaussFilter, 'same') / ratio;
end

% plot
[nH, nV] = panam_subplotDimensions(numel(data));
for ii = 1:numel(data)
    h(ii) = subplot(nH, nV, ii);
    hold on
    set(gca,'YDir','normal');
    if self(1).isNumTime
       htmp =  imagesc(self(1).Time,[],data{ii});
    else
       htmp = imagesc(1:size(data,1),[],data{ii});
    end
    axis tight
    title(h(ii),channels(ii));
    set(htmp,'alphadata',~isnan(dataTmp));
end

% events
if strcmpi(option.events, 'yes')          
    for ii = 1:numel(h)
        [h(ii), legStatus, legLabels, legHandles] = plot_events(h(ii), events{ii}, eventNames, eventColors, legStatus, legLabels, legHandles);
        if strcmpi(option.events, 'yes')
            legend(legHandles, legLabels, 'Position', [0.94 0.85 0.03 0.1]);
        end
    end
end

% axes properties
for ii = 1:numel(h)
    set(h(ii),'YTick',[]);
    xlabel(h(ii),'Time')
    hold off
end

% xaxis
if ~isequal(option.xaxis, 'auto')
    for i = 1:length(h)
        xlim(h(i), option.xaxis);
    end
end

end



function [hOut, legStatusOut, legLabelsOut, legHandlesOut] = plot_events(hIn, events, eventNames, eventColors, legStatusIn, legLabelsIn, legHandlesIn)

hOut = hIn;
axes(hOut);
hold on

legStatusOut = legStatusIn;
legLabelsOut = legLabelsIn;
legHandlesOut = legHandlesIn;

% events
if iscell(events) % 1 event for each data plot)
    for i = 1:numel(events)
        for k = 1:numel(events{i})
            ind = find(strcmp(events{i}(k).EventName, eventNames));
            t1 = events{i}(k).Time;
            t2 = t1 + events{i}(k).Duration;
            minEv = i - 0.5;
            maxEv = i + 0.5;
            if t2 == t1 % Duration = 0
                plot([t1 t2], [minEv maxEv],'color', eventColors{ind},'Tag',events{i}(k).EventName,'LineWidth',1);
                ev = plot((t1+t2)/2, (minEv + maxEv)/2, '-*','color', eventColors{ind},'Tag',events{i}(k).EventName,'LineWidth',1,'MarkerSize',4);
            else
                ev = fill([t1, t1,t2, t2], [minEv, maxEv,maxEv, minEv],eventColors{ind},'EdgeColor', eventColors{ind}, 'Tag',events{i}(k).EventName, 'FaceAlpha', 0.2);
            end
            if legStatusOut(ind) == 0
                legHandlesOut(end+1) = ev;
                legLabelsOut(end+1) = {events{i}(k).EventName};
                legStatusOut(ind) = 1;
            end
        end
    end
else % straightly events structure : same events for all plots of the gca
    for k = 1:numel(events)
        ind = find(strcmp(events(k).EventName, eventNames));
        t1 = events(k).Time;
        t2 = t1 + events(k).Duration;
        a = axis(hOut);
        minEv = a(3);
        maxEv = a(4);
        if t2 == t1 % Duration = 0
            ev = plot([t1 t2], [minEv maxEv],'color', eventColors{ind},'Tag',events(k).EventName,'LineWidth',1);
        else
            ev = fill([t1, t1,t2, t2], [minEv, maxEv,maxEv, minEv],eventColors{ind},'EdgeColor', eventColors{ind}, 'Tag',events(k).EventName, 'FaceAlpha', 0.2);
        end
        if legStatusOut(ind) == 0
            legHandlesOut(end+1) = ev;
            legLabelsOut(end+1) = {events(k).EventName};
            legStatusOut(ind) = 1;
        end
    end
end

end



function [eventNames, eventColors, legStatus, legLabels,legHandles] =  init_events(self, option)

tmp = arrayfun(@(x) {x.Events.EventName}, self, 'UniformOutput',0);
eventNames = unique([tmp{:}]);
evColorMap = option.eventColormap;
eval(['eventColors = ' evColorMap '(numel(eventNames));']);
eventColors = num2cell(eventColors,2);
legStatus = zeros(1,numel(eventNames)); % for legend
legLabels = {}; % associated legend entries
legHandles = [];

end