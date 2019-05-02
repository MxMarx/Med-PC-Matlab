%% Find the files
files = dir('C:\Users\Russell\OneDrive - UW\GitHub\Med-PC-Matlab\Data\Within-Session Threshold SPIW\Within Session');
files = files(~[files.isdir]);

t = [];
for i = 1:length(files)
t = [t; LoadDataWTH([files(i).folder '\' files(i).name])];
end
t.dose = t.dose * (0.366 / 3.156);

%% Remove dead rats
exclude = ismember(t.subject, [4,5,9]);
t = t(~exclude,:);
exclude = ismember(t.session, [1]);
t = t(~exclude,:);

% Rename misnamed groups
t.group(t.group == 'hM4di') = 'hM4Di';


%% Estimate brain  levels
GroupingVariables = {'subject','experiment','group','box','session'};
InputVariables = {'time','event'};
OutputVariableNames = {'druglevel','time'};
p = rowfun(@(time,event)...
    pharmacokineticsV3([time(event=='Infusion start'),time(event=='Infusion end')]*1000),... % [start time, end time], rat size in kg, session length in minutes
    t,...
    'GroupingVariables',GroupingVariables,'InputVariables',InputVariables,'OutputVariableNames',OutputVariableNames);


%% Calculate consumption and price
func = @(x) deal(sum(x == 'Infusion start'), sum(x == 'Left active FR press' | x == 'Left press during infusion'));
a = rowfun(func,t,...
    'InputVariables',{'event'},...
    'GroupingVariables',{'subject','dose','experiment','group','session'},...
    'OutputVariableNames',{'infusions', 'active'});
% calculate price
a.price = 1 ./ a.dose;

a.color = contains(cellstr(a.group), 'GFP');
a.color = categorical(a.color, [0,1], {'hM4Di', 'GFP'});
a.lightness = contains(cellstr(a.group), 'Veh');
a.lightness = categorical(a.lightness, [0,1], {'CNO', 'Veh'});

%% Plot
economicsFigures(t,p,a,'Estimate brain levels')

economicsFigures(t,p,a,'Raster plot of lever presses')

economicsFigures(t,p,a,'Average demand curve for each group')

economicsFigures(t,p,a,'Demand curve for group by day')

economicsFigures(t,p,a,'Demand curve for rat by day + drug level')


    economicsFigures(t,p,a,'Infusions and drug level for each rat for each session')





% Save unstacked table
a.GroupCount = [];
unstacked = unstack(a,{'infusions','active'},'session');
writetable(unstacked,'V:\Russell\Matlab Functions\Self Admin\Philes\output.xlsx')