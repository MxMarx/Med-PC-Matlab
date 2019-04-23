%% Find the files in the folder
files = dir('E:\Within-Session Threshold SPIW');
files = files(~[files.isdir]);

% Get the fata from each file
t = [];
b = [];
for i = 1:length(files)
    get_timestamps = 1;
    fname = [files(i).folder '\' files(i).name];
    [binned_data, timestamps] = LoadData(fname,get_timestamps);
    
    t = [t; timestamps];
    b = [b; binned_data];
end

% Remove dead rats
exclude = ismember(t.subject,[3]);
t = t(~exclude,:);
exclude = ismember(b.subject,[3]);
b = b(~exclude,:);

%% Save to excel
b = sortrows(b,{'group','subject','session'})

b.sessionStr = cellstr(num2str(b.session, 'S%-u'))
[fname, fpath] = uiputfile('*.xlsx');
if ~isnumeric(fpath)
    infusions = b(:, {'Infusions', 'subject', 'group', 'sessionStr'});
    infusions = unstack(infusions,'Infusions','sessionStr');
    infusions.Type = repmat({'infusion'},height(infusions),1);
    
    active = b(:, {'ActiveLeverPresses', 'subject', 'group', 'sessionStr'});
    active = unstack(active,'ActiveLeverPresses','sessionStr');
    active.Type = repmat({'Active'},height(active),1);
    
    inactive = b(:, {'InactiveLeverPresses', 'subject', 'group', 'sessionStr'});
    inactive = unstack(inactive,'InactiveLeverPresses','sessionStr');
    inactive.Type = repmat({'Inactive'},height(inactive),1);

    output = [infusions; active; inactive]
    output = movevars(output,'Type','Before',1)
    
    writetable(output,[fpath fname])
end

%% By date
b = sortrows(b,{'session','group'});
a = stack(b,{'Infusions','ActiveLeverPresses','InactiveLeverPresses'},'IndexVariableName','event','NewDataVariableName','count');
a.event = renamecats(a.event,{'Infusions','ActiveLeverPresses','InactiveLeverPresses'},{'Infusions','Active lever presses','Inactive lever presses'});

% Infusions
figure('position',[100,100,400,420])
g = gramm('x',b.sessionStr,'y',b.Infusions,'color',b.group);
g.stat_summary('geom',{'line','errorbar','point'},'setylim',1,'dodge',.05);
g.set_names('x','Day','y','Infusions','color',' ');
g.set_limit_extra([.05,.05],[0,0]);
g.set_line_options('styles',{'--'});
g.set_title('Infusions')
g.set_order_options('x',0)
g.draw;
g.facet_axes_handles.YLim(1) = 0; % Make the ylim zero


% Lever presses
figure('position',[100,100,700,420])
g = gramm('x',datenum(dateshift(a.date,'start','day')),'y',a.count,'color',a.group,'lightness',a.event,'subset',a.event ~= 'Infusions');
g.stat_summary('geom',{'line','errorbar','point'},'setylim',1,'dodge',.05);
g.set_names('x','Day','y','Count','column',[],'color','Group','lightness','Lever');
g.set_limit_extra([.2,.2],[0,0]);
g.set_line_options('styles',{'--'});
g.set_color_options('legend','expand','lightness_range',[40,80])
g.draw;
g.facet_axes_handles.YLim(1) = 0; % Make the ylim zero

% g.export('file_name','presses_over_day_smoothed')


%% By hour
GroupingVariables = {'box','filename','date','event','group'};
InputVariables = {'time'};
OutputVariableNames = {'count','hour'};
func = @(x) BinByHour(x,600,190*60);
a = rowfun(func,t,'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);
a = sortrows(a,'date');

% Plot the means for each hour
figure('position',[100,100,800,420])
g = gramm('x',a.hour - 0.5,'y',a.count,'color',a.group,'column',a.event,'fig',cellstr(datestr(a.date,'mmm-dd')));
g.stat_summary('geom',{'errorbar','line'},'setylim',1);
g.set_order_options('column',0,'row',0);
g.set_names('x','Time (h)','y','Count','column',[]);
g.no_legend;
g.draw;

% % Optional, update the plot with each individual as a single line
% g.update('group',findgroups(a(:,GroupingVariables)));
% g.geom_line('alpha',.13);
% g.no_legend;
% g.draw;
% g.update('group',[]); % This part just returns the ylim to the original
% g.stat_summary('geom',{'errorbar','line'},'setylim',1);
% g.no_legend;
% g.draw;
% % g.export('file_name','presses_over_time')


% Plot the data in smoothed 10 minute bins
func = @(x) BinByHour(x,600,190*60);
a = rowfun(func,t,'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);
figure('position',[100,100,800,420])
g = gramm('x',a.hour,'y',a.count,'color',a.event,'subset',a.event ~= 'infusionEnd','column',a.event);
g.stat_smooth('setylim',1);
g.set_order_options('column',0);
g.set_point_options('base_size',1);
g.set_names('x','Time (h)','y','Count','column',[],'color',' ');
g.no_legend;
g.draw;
% g.export('file_name','presses_over_time_smoothed','file_type','png')


%% Plot raster
GroupingVariables = {'box','filename','date','event','subject'};
InputVariables = {'time'};
OutputVariableNames = {'time'};
a = rowfun(@(x) {x./60},t,'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);
a = sortrows(a,'date');

figure('position',[100,100,1276,300])
g = gramm('x',a.time,'column',a.event,'color',a.subject)
g.geom_raster
g.set_names('x','Time (m)','y','Session','column',[],'color','Rat ID')
g.draw


%% Plot estimated levels
GroupingVariables = {'box','filename','date','room','subject','group'};
InputVariables = {'time','event', 'box', 'date'};
OutputVariableNames = {'druglevel','time'};
a = rowfun(@(x1,x2,box,date)...
    pharmacokineticsV3([x1(x2=='Infusions'),x1(x2=='Infusions')+3.5] * 1000),...
    t(t.event=='Infusions',:),...
    'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);

s = findgroups(a(:,{'box','filename'}));
figure('position',[100,100,764,615]);
g = gramm('x',a.time,'y',a.druglevel,'lightness',a.group,'color',cellstr(datestr(a.date,'mmm-dd')));
% g.fig(a.room)
g.geom_line;
g.facet_wrap(a.subject,'ncols',5)
% g.facet_grid(cellstr(a.date,'MMM-dd'),a.subject);
g.set_names('x','Time (m)','y','Estimated Brain Level (uM)','column','Rat','lightness','Day');
g.set_color_options('legend','separate','lightness_range',[50,80])
g.set_layout_options('redraw_gap',.01)
g.draw
