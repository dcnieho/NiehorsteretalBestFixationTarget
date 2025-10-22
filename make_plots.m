clear all
close all

vars = {
    'msRate'           ,'Microsaccade rate'        ,'Hz'   ,[0 3.4 ],'l';
    'msDisplacement'   ,'Microsaccade displacement','deg'  ,[0 0.51],'r';
    'driftDisplacement','Drift displacement'       ,'deg'  ,[0 0.51],'r';
    'driftPathLength'  ,'Drift path length'        ,'deg'  ,[0 1.33],'r';
    'driftSpeed'       ,'Drift speed'              ,'deg/s',[0 1.22],'l';
    'BCEA'             ,'BCEA'                     ,'deg^2',[0 0.15],'r';
    };

stims = {
    'Gaussian', 'Circle', 'Point', 'CircleCrossPoint', 'Bessel',
    };

clrs = {
    'P1',[0 1 0], 'd';
    'P2',[0 0 1], 's';
    'P3',[1 0 0], 'o';
    'P4',[0 1 1], 'x';
    'P5',[1 0 1], '+';
    'P6',[1 .5 0], '^';
    };

dfolder = fullfile(cd,'data');
rfolder = fullfile(cd,'results');
[files,nfile] = FileFromFolder(dfolder,'','tsv');
data = cell(1,nfile);
for fl=1:nfile
    data{fl} = readtable(fullfile(dfolder,files(fl).name),'FileType','text','Delimiter','\t');
    data{fl} = addvars(data{fl}, repmat(string(files(fl).fname),size(data{fl},1),1), 'Before', 1, 'NewVariableNames',{'condition'});
end
data = vertcat(data{:});
conditions = unique(data.condition);

off = .1;
for v=1:size(vars,1)
    % collect data
    smeans = nan(length(conditions),length(stims),size(clrs,1));
    for c=1:length(conditions)
        qCond = strcmp(data.condition,conditions(c));
        for s=1:length(stims)
            qStim = qCond & strcmp(data.fix_target,stims{s});
            for p=1:size(clrs,1)
                qSubj = qStim & strcmp(data.subject,clrs{p,1});
                smeans(c,s,p) = mean(data.(vars{v})(qSubj));
            end
        end
    end
    gmeans = mean(smeans,3);

    figure, hold on
    % plot subjects
    for c=1:length(conditions)
        fac = sign(c-1.5);
        for p=1:size(clrs,1)
            clr = clrs{c,2};
            clr = clr + .67*(1-clr);
            plot([1:length(stims)]+fac*off, squeeze(smeans(c,:,p)),clrs{p,3},"MarkerFaceColor",clr,"MarkerEdgeColor",clr,'LineStyle','-','Color',clr)
        end
    end
    hndls = gobjects(1,length(conditions));
    for c=1:length(conditions)
        fac = sign(c-1.5);
        hndls(c) = plot([1:size(gmeans,2)]+fac*off,gmeans(c,:),"Marker",'o',"MarkerFaceColor",clrs{c,2},"MarkerEdgeColor",clrs{c,2},'LineStyle','none','MarkerSize',10,'LineStyle','-','LineWidth',2,'Color',clrs{c,2});
    end

    %title(files(fl).fname)
    ylabel(sprintf('%s (%s)',vars{v,2:3}));
    if ~isempty(vars{v,4})
        ylim(vars{v,4})
    end
    ax=gca;
    if startsWith(vars{v,1},'BCEA')
        ax.YAxis.TickLabelFormat = '%.2f';
    else
        ax.YAxis.TickLabelFormat = '%.1f';
    end
    ax.YAxis.FontSize = 12;
    ax.YAxis.Label.FontSize = 14;
    xlim([0 length(stims)+1])
    ax.XTick = [1:length(stims)];
    % get tick label positions
    drawnow
    xtl_pos = ax.XRuler.TickLabelChild.VertexData;
    ax.XTickLabel = [];
    if vars{v,5}=='l'
        lpos = 'NorthWest';
    else
        lpos = 'NorthEast';
    end
    hl=legend(hndls,conditions,'Location',lpos,'Box','off');
    title(hl,'Polarity')

    ax.Clipping = 'off';
    ar = diff(ax.YLim)/ax.PlotBoxAspectRatio(2)/diff(ax.XLim)*ax.PlotBoxAspectRatio(1);
    for s=1:length(stims)
        fixTarget = imread(fullfile('stim',[stims{s} '.png']));
        image('CData',repmat(fixTarget,1,1,3),'XData',xtl_pos(1,s)+[-.2 .2],'YData',xtl_pos(2,s)+[-.4 0]*ar);
    end

    print(fullfile(rfolder,sprintf('all_%s.png',vars{v,1})),'-dpng','-r300');
    close;
end
