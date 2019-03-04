% Find the files
files = dir('V:\Russell\Matlab Functions\Self Admin\Philes');
files = files(~[files.isdir]);

t = [];
for i = 1:length(files)
t = [t; LoadData([files(i).folder '\' files(i).name])];
end


func = @(x) deal(sum(x == 'Infusion start'), sum(x == 'Left active FR press' | x == 'Left press during infusion'));

a = rowfun(func,t,...
    'InputVariables',{'event'},...
    'GroupingVariables',{'subject','dose','experiment','group','date'},...
    'OutputVariableNames',{'infusions', 'active'});

% calculate price
a.price = 1 ./ a.dose;

a.group(a.group == 'hM4di') = 'hM4Di';

% make figure
figure
g = gramm('x',log(a.price),'y',log(a.infusions .* a.dose),'color',a.subject,'subset',(log(a.infusions .* a.dose) > 0) )

g.stat_summary('geom',{'line','errorbar'})
% g.geom_line

g.set_names('x','Dose','y','Infusions')
g.draw



% Save unstacked
a.GroupCount = [];
unstacked = unstack(a,{'infusions','active'},'date');
writetable(unstacked,'V:\Russell\Matlab Functions\Self Admin\Philes\output.xlsx')