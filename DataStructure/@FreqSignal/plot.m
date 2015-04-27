% PLOT
% plot the 'FreqSignal' as data vs. frequency bins
% valid only if number of dimensions <= 2 in Data property
% plot the different channels on the same plot


function h = plot(self, commonOptions, specificOptions)


% TODO : check inputs


% default
if nargin < 3 || isempty(specificOptions)
    specificOptions = {};
end
if nargin < 2 || isempty(commonOptions)
    commonOptions = {};
end

% colormap
cm = find(strcmpi(commonOptions,'colormap'));
if ~isempty(cm)
    nChannels = length(self.ChannelTags);
    cmap = commonOptions{cm+1};
    eval(['cmap = ' cmap '(nChannels);']);
    cmap = mat2cell(cmap, ones(1,nChannels),3);
    specificOptions{end+1} = 'color';
    specificOptions{end+1} = cmap;
    commonOptions(cm:cm+1) = [];
end
    

% plot
for ii = 1:size(self.Data,2)
    specificOptions_current = specificOptions;
    for jj = 2:2:length(specificOptions)
        specificOptions_current{jj} = specificOptions{jj}{ii};
    end
    options = [commonOptions, specificOptions_current];
    if self.isNumFreq % numeric freq vector
        h = plot(self.Freq, self.Data(:,ii), options{:});
    else
        h = plot(self.Data(:,ii), options{:});
    end
    hold on
end

if ~self.isNumFreq
    set(gca,'XTick',1:length(self.Freq), 'XTickLabel', self.Freq);
    a = axis;
    axis([a(1)-1 a(2)+1 a(3) a(4)]);
end

xlabel('Frequency')
legend(self.ChannelTags{:})
legend hide
hold off

end

