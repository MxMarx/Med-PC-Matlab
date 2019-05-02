function economicsFigures(t,p,a,type)

switch type
    case 'Estimate brain levels'
        figure('position',[100,100,1164,815]);
        g = gramm('x',p.time,'y',p.druglevel,'color',p.box,'lightness',p.session);
        g.geom_line;
        g.facet_wrap(p.subject,'ncols',5)
        g.set_names('x','Time (m)','y','Estimated Brain Level (uM)','column','Rat','lightness','Day');
        g.set_color_options('legend','merge','lightness_range',[30,80])
        g.set_layout_options('redraw_gap',.01)
        g.draw
        
        
    case 'Raster plot of lever presses'
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
        
        
    case 'Average demand curve for each group'
        % Calculate mean over all days
        func = @(x) mean(x);
        b = rowfun(func,a,...
            'InputVariables',{'infusions'},...
            'GroupingVariables',{'subject','dose','experiment','group','price','color','lightness'},...
            'OutputVariableNames',{'infusions'});
        figure
        g = gramm('x',b.price, 'y',b.infusions .* b.dose, 'color',b.color, 'lightness', b.lightness, 'subset',b.infusions > 0);
        g.stat_summary('geom',{'line','errorbar'},'type','sem')
        g.set_names('x','Price','y','Consumption', 'color', 'Virus', 'lightness' , 'Treatment');
        g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
        g.set_line_options('base_size',2)
        g.axe_property('YScale','log', 'XScale','log')
        g.draw
        
        
    case 'Demand curve for group by day'
        figure
        g = gramm('x',a.price, 'y',a.infusions .* a.dose, 'color',a.color, 'lightness',a.lightness, 'subset',a.infusions > 0);
        g.facet_wrap(a.session, 'ncols', 99) % Change 'ncols' to 1 to make it vertical
        g.stat_summary('geom',{'line','errorbar'},'type','sem')
        g.set_names('x','Price','y','Consumption', 'color', 'Treatment', 'column', 'Session');
        g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120)
        g.axe_property('YScale','log', 'XScale','log')
        g.draw
        
        
    case 'Demand curve for rat by day + drug level'
        figure
        g = gramm('x',a.price, 'y',a.infusions .* a.dose, 'color',a.color, 'lightness',a.lightness, 'subset',a.infusions > 0);
        g.facet_grid(a.subject, a.session);
        g.geom_line();
        g.geom_point();

        g.set_names('x','Price','y','Consumption', 'color', 'Treatment', 'column', 'Session');
        g.set_order_options('row',0);
        g.set_color_options('lightness_range',[40,80], 'legend', 'expand', 'chroma_range', [100, 100], 'hue_range', [25 385] + 120);
        g.set_line_options('base_size',2);
        g.set_layout_options('redraw_gap',.01);
        g.axe_property('YScale','linear', 'XScale','log')
        g.draw
        
        YLIM = ylim(g.results.geom_line_handle(1).Parent);
        y = cellfun(@(x) YLIM(2) .* (x+YLIM(1)) ./ max([p.druglevel{:}]), p.druglevel, 'UniformOutput', false);
        x = cellfun(@(x) exp(linspace(min(log(a.price)),log(max(a.price)),length(x))), p.time, 'UniformOutput', false);
        
        g.update('x', x,'y',y,'color',[],'row',p.subject,'column',p.session)
        g.geom_line
        g.set_color_options('lightness',0)
        g.draw
        
    case 'Infusions and drug level for each rat for each session'
        t = t(t.event == 'Infusion start', :);
        figure
        g = gramm('x', t.time/60,'color',t.dose)
        g.facet_grid(t.subject, t.session,'scale','free_y');
        g.stat_bin('fill', 'all', 'geom', 'stairs', 'edges',(0:200:6600)/60,'normalization','count')
        % g.stat_density
        g.set_layout_options('redraw_gap',.01);
        g.set_names('x','Time','y','Count','color','Dose','column','Session','row','Rat')
        g.update('x', p.time,'y',p.druglevel,'color',[],'row',p.subject,'column',p.session)
        g.geom_line
        g.set_color_options('lightness',0)
        g.draw
end
