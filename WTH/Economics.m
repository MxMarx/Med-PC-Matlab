% Find the files
files = dir('D:\Within-Session Threshold SPIW\Within Session');
files = files(~[files.isdir]);

t = [];
for i = 1:length(files)
t = [t; LoadDataWTH([files(i).folder '\' files(i).name])];
end

% Remove dead rats
exclude = ismember(t.subject, [4]);
t = t(~exclude,:);
exclude = ismember(t.session, [1]);
t = t(~exclude,:);



t.time = t.times ./ 100;
%% Estimate brain estimated levels
GroupingVariables = {'subject','experiment','group','box','date'};
InputVariables = {'time','event'};
OutputVariableNames = {'druglevel','time'};
a = rowfun(@(time,event,box,date)...
    pharmacokineticsV3([time(event=='Infusion start'),time(event=='Infusion end')]*1000, .5, 2, 110, 0),... % [start time, end time], rat size in kg, session length in minutes
    t,...
    'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);

%% Raster plot of lever presses
GroupingVariables = {'subject','experiment','group','box','session'};
InputVariables = {'time'};
OutputVariableNames = {'time'};
d = rowfun(@(x) {x}, t(t.event == 'Left active FR press',:), 'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);
figure
g = gramm('x',d.time,'color',d.group,'column',d.session)
g.set_names('x','Time (s)','color','Group');
g(2,1) = g.copy
g(1,1).geom_raster
g(2,1).stat_density
g.draw

%% Plot brain levels
figure('position',[100,100,1164,815]);
g = gramm('x',a.time,'y',a.druglevel,'color',a.box,'lightness',a.date);
g.geom_line;
g.facet_wrap(a.subject,'ncols',5)
g.set_names('x','Time (m)','y','Estimated Brain Level (uM)','column','Rat','lightness','Day');
g.set_color_options('legend','merge','lightness_range',[30,80])
g.set_layout_options('redraw_gap',.01)
g.draw
g.export('file_name','Brain cocaine levels','file_type','png');

%%
func = @(x) deal(sum(x == 'Infusion start'), sum(x == 'Left active FR press' | x == 'Left press during infusion'));
a = rowfun(func,t,...
    'InputVariables',{'event'},...
    'GroupingVariables',{'subject','dose','experiment','group','session'},...
    'OutputVariableNames',{'infusions', 'active'});
% calculate price
a.price = 1 ./ a.dose;
a.group(a.group == 'hM4di') = 'hM4Di';
a = sortrows(a,{'group'});

a.color = contains(cellstr(a.group), 'GFP');
% color = randi([0 1],height(a),1)
a.color = categorical(a.color, [0,1], {'hM4Di', 'GFP'});

a.lightness = contains(cellstr(a.group), 'Veh');
% lightness = randi([0 1],height(a),1)
a.lightness = categorical(a.lightness, [0,1], {'CNO', 'Veh'});

%% Calculate mean over all days
func = @(x) mean(x);
b = rowfun(func,a,...
    'InputVariables',{'infusions'},...
    'GroupingVariables',{'subject','dose','experiment','group','price','color','lightness'},...
    'OutputVariableNames',{'infusions'});

%% make figure
figure
g = gramm('x',log(b.price), 'y',log(b.infusions .* b.dose), 'color',b.color, 'lightness', b.lightness, 'subset',(log(b.infusions .* b.dose) >= 0))
g.stat_summary('geom',{'line','errorbar'},'type','sem')
% g.stat_boxplot
g.set_names('x','Price','y','Consumption', 'color', 'Virus', 'lightness' , 'Treatment');
g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
g.set_line_options('base_size',2)
g.draw


%% make figure
figure
g = gramm('x',log(a.price), 'y',log(a.infusions .* a.dose), 'color',a.color, 'lightness',a.lightness, 'subset',(log(a.infusions .* a.dose) > 0))
g.facet_wrap(a.session, 'ncols', 99) % Change 'ncols' to 1 to make it vertical
% g.facet_wrap(a.session, 'ncols', 1)
g.stat_summary('geom',{'line','errorbar'},'type','sem')
g.set_names('x','Price','y','Consumption', 'color', 'Treatment', 'column', 'Session');
g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
g.draw

%% make figure
figure
g = gramm('x',log(a.price), 'y',log(a.infusions .* a.dose), 'color',a.color, 'lightness',a.lightness, 'subset',(log(a.infusions .* a.dose) > 0))
g.facet_grid(a.subject, a.session)
g.geom_line
g.set_names('x','Price','y','Consumption', 'color', 'Treatment', 'column', 'Session');
g.set_order_options('row',0);
g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
g.set_line_options('base_size',2)
g.draw

%% make figure
figure
g = gramm('x',log(a.price), 'y',log(a.infusions .* a.dose), 'color',a.color, 'lightness',a.lightness, 'subset',(log(a.infusions .* a.dose) > 0))
g.facet_wrap(a.subject,'ncols',9)
g.stat_summary('geom',{'line','errorbar'},'type','sem')
g.set_names('x','Price','y','Consumption', 'color', 'Treatment');
g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
g.set_line_options('base_size',2)
g.set_order_options('row',0,'column',0);
g.draw






% Save unstacked
a.GroupCount = [];
unstacked = unstack(a,{'infusions','active'},'session');
writetable(unstacked,'V:\Russell\Matlab Functions\Self Admin\Philes\output.xlsx')