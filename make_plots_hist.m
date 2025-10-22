clear all
close all

which = 'drifts';
which = 'saccades';

if strcmp(which,'saccades')
    rmax = 1.5;
    rticklblfmt = '%.2f°';
elseif strcmp(which,'drifts')
    rmax = 0.6;
    rticklblfmt = '%.2f°';
end
rtick= linspace(0,rmax,5); rtick(1) = [];
thetatick = [0:45:359];
cmap = DNcolormap2(64)./255;

stims = {
    'Gaussian', 'Circle', 'Point', 'CircleCrossPoint', 'Bessel',
    };

dfolder = fullfile(cd,'data',which);
rfolder = fullfile(cd,'results');
[files,nfile] = FileFromFolder(dfolder,'','tsv');
% parse filenames
parse = split({files.name}.','_');
[files.condition] = parse{:,1};
[files.subject] = parse{:,2};
fp = cellfun(@(x) x(1:end-4), parse(:,4), 'uni', false);
[files.fixPoint] = fp{:};

conditions = unique({files.condition});
subjects   = unique({files.subject});
for c=1:length(conditions)
    qCond = strcmp({files.condition},conditions{c});
    figure('Position',[3.4000 50.2000 888.8000 835.6000]);
    t = tiledlayout(length(subjects)*3+1, length(stims)*3+1, TileIndexing="rowmajor", TileSpacing="tight", Padding="tight");
    ti=1;
    axs      = cell(1,length(subjects)*length(stims));
    axs_cart = cell(1,length(subjects)*length(stims));
    for s=1:length(subjects)
        qSubj = qCond & strcmp({files.subject},subjects{s});
        for f=1:length(stims)
            qStim = qSubj & strcmp({files.fixPoint},stims{f});

            iFiles = find(qStim);
            alldata = cell(1,length(iFiles));
            for i=1:length(iFiles)
                fi = iFiles(i);
                alldata{i} = readtable(fullfile(files(fi).folder,files(fi).name),'FileType','text','Delimiter','\t');
            end
            data = vertcat(alldata{:});

            [x,y]=pol2cart(data.direction,data.displacement);
            [bandwidth,density,X,Y]=kde2d([x y],2^9,[-rmax -rmax],[rmax rmax]);
            density(hypot(X,Y)>rmax) = 0;
            md = max(density(:));
            levels = linspace(0,md,22);

            axs{ti}=polaraxes(t,'RTick',rtick,'ThetaTick',thetatick);
            axs{ti}.Layout.Tile = (s-1)*(length(stims)*3+1)*3+(f-1)*3+2;
            axs{ti}.Layout.TileSpan = [3 3];
            rlim([0 rmax])
            axs{ti}.RAxis.TickLabelFormat = rticklblfmt;
            [axs{ti}.RTickLabel{[1 3]}] = deal('');

            axs_cart{ti} = axes();
            axs_cart{ti}.Position = axs{ti}.Position;

            contourf(X,Y,density,levels(2:end),'LineStyle','none');

            xlim(axs_cart{ti},[-max(get(axs{ti},'RLim')),max(get(axs{ti},'RLim'))]);
            ylim(axs_cart{ti},[-max(get(axs{ti},'RLim')),max(get(axs{ti},'RLim'))]);
            axis square; set(axs_cart{ti},'visible','off');
            ti = ti+1;
            colormap(cmap);
        end
    end
    % add participant labels
    for s=1:length(subjects)
        ax = axes(t); %#ok<LAXES>
        ax.Layout.Tile = (s-1)*(length(stims)*3+1)*3+length(stims)*3+2;
        text(.5,.5,subjects{s},'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',16);
        set(ax,'visible','off');
    end
    % add stimuli images
    off = (length(stims)*3+1)*3*length(subjects);
    for f=1:length(stims)
        ax = axes(t); %#ok<LAXES>
        ax.Layout.Tile = off+(f-1)*3+3;
        fixTarget = imread(fullfile('stim',[stims{f} '.png']));
        imshow(fixTarget,'Border','tight');
        ax.XAxis.Visible = false;
        ax.YAxis.Visible = false;
        ax.XLabel.Visible = false;
        ax.YLabel.Visible = false;
        ax.Clipping = 'off';
        ax.XLim = [.5+size(fixTarget,1)/10*3 .5+size(fixTarget,1)/10*7];
        ax.YLim = [.5+size(fixTarget,1)/10*3 .5+size(fixTarget,1)/10*7];
    end
    
    % final layout labels
    lbl = [upper(which(1)) which(2:end-1)];
    title(t,[lbl ' histogram - ' conditions{c}])
    xlabel(t,'Fixation target')
    ylabel(t,'Participant')

    % ensure overlaid axes are in the right place
    for i=1:length(axs)
        axs_cart{i}.Position = axs{i}.Position;
        xlim(axs_cart{i},[-max(get(axs{i},'RLim')),max(get(axs{i},'RLim'))]);
        ylim(axs_cart{i},[-max(get(axs{i},'RLim')),max(get(axs{i},'RLim'))]);
    end
    print(fullfile(rfolder,[lbl ' histogram - ' conditions{c} '.png']),'-dpng','-r300');
end
