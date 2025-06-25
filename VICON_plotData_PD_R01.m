function VICON_plotData_PD_R01(varargin)

p = inputParser;
addOptional(p,'srcDir',[]);
addOptional(p,'srcFile',[]);
addOptional(p,'dataTable',[]);
addOptional(p,'figPosition',get(0,'ScreenSize')); 
addOptional(p,'figFontSize',6);
addOptional(p,'textFontSize',6);
addOptional(p,'labelFontSize',12);
addOptional(p,'labelFontWeight','bold');
addOptional(p,'EMGYLim',[0 3]);
addOptional(p,'COMPosminusLVDTYLim',[-10 10]);
addOptional(p,'COMVeloYLim',[-15 15]);
addOptional(p,'COMAccelYLim',[-0.4 0.4]);
addOptional(p,'FzYLim',[-10 800]);
addOptional(p,'LVDTYLim',[-10 10]);
addOptional(p,'pertDir',0:30:330);
addOptional(p,'footLiftFz',5);
addOptional(p,'trialColor',0.5*[1 1 1]);
addOptional(p,'avColor',[0 0 0]);
addOptional(p,'footLiftColor',0.5*[1 0 0]);
parse(p,varargin{:});

if ~isempty(p.Results.srcFile)
	srcFile = p.Results.srcFile;
	load(srcFile);
else
	[srcFile,srcPath] = uigetfile('*.mat', 'Select Interpolated Data File');
	load(srcPath+string(srcFile));
end

plotVarNames = [...
	"EMG_TA_L";
	"EMG_MGAS_L";
	"EMG_SOL_L";
	"EMG_TA_R";
	"EMG_MGAS_R";
	"EMG_SOL_R";
	"COMPosminusLVDT_X";
	"COMPosminusLVDT_Y";
	"COMVelo_X";
	"COMVelo_Y";
	"COMAccel_X";
	"COMAccel_Y";
	"Left_Fz";
	"Right_Fz";
	"LVDT_X";
	"LVDT_Y";
	];

rowNum = (1:length(plotVarNames))';

YL = [...
	repmat(p.Results.EMGYLim,6,1);
	repmat(p.Results.COMPosminusLVDTYLim,2,1);
	repmat(p.Results.COMVeloYLim,2,1);
	repmat(p.Results.COMAccelYLim,2,1);
	repmat(p.Results.FzYLim,2,1);
	repmat(p.Results.LVDTYLim,2,1);
	];

XL = repmat([-0.5 1],size(YL,1),1);

rowParams = table(rowNum,XL,YL); rowParams.Properties.RowNames = cellstr(plotVarNames);
rowParams.Label = string(rowParams.Properties.RowNames);

pertDir = sortrows(unique(dataTable.pertdir_calc_round_deg));
%p.Results.pertDir(:);
% pertDir = sortrows(repmat(unique(dataTable.pertdir_calc_round_deg),3,1));%p.Results.pertDir(:);
% pertMagn = ["L";"M";"H";"L";"M";"H"];
colNum = (1:length(pertDir))';
pertDirNames = "pd_"+string(pertDir);%+pertMagn;

colParams = table(colNum,pertDir);%,pertMagn);
colParams.Properties.RowNames = cellstr(pertDirNames);

nHeaderRows = 1;
nHeaderCols = 1;

colParams.colNum = colParams.colNum + nHeaderCols;
rowParams.rowNum = rowParams.rowNum + nHeaderRows;

% check for foot Lift
dataTable.footLift = nan(size(dataTable,1),1);

% HERE IS THE PROBLEM
% average across like trials
[trialData,avgData] = deal(cell2table(cell(length(plotVarNames),length(pertDirNames)),'RowNames',cellstr(plotVarNames),'VariableNames',cellstr(pertDirNames)));
for pd = pertDirNames'
	pertdir_calc_round_deg = colParams{cellstr(pd),'pertDir'};
%     pertmagn = colParams{cellstr(pd),'pertMagn'};
	lookup = (round(dataTable.pertdir_calc_round_deg) == pertdir_calc_round_deg);%&(dataTable.pertmagn == pertmagn);
	for v = plotVarNames'
		
		tempTrials = dataTable{lookup,cellstr(v)};
		tempAvg = nanmean(tempTrials,1);
		
		trialData{cellstr(v),cellstr(pd)}{1} = tempTrials;
		avgData{cellstr(v),cellstr(pd)}{1} = tempAvg;
	end
end

trialNames = [];
footLifts = [];
for pd = pertDirNames'
    pertdir_calc_round_deg = colParams{cellstr(pd),'pertDir'};
%     pertmagn = colParams{cellstr(pd),'pertMagn'};
    lookup = (round(dataTable.pertdir_calc_round_deg) == pertdir_calc_round_deg);%&(dataTable.pertmagn == pertmagn);
    trialNames.(char(pd)) = dataTable{lookup,'trialname'};
	footLifts.(char(pd)) = dataTable{lookup,'footLift'};
end

fg = figure;
fg.MenuBar='none';
fg.Name = srcFile;

fg.Position = p.Results.figPosition;
nrows = max(rowParams.rowNum);
ncols = max(colParams.colNum);

atime = dataTable.atime(1,:);
for pd = pertDirNames'
	for v = plotVarNames'
		tempTrials = trialData{cellstr(v),cellstr(pd)}{1};
		tempAvg = avgData{cellstr(v),cellstr(pd)}{1};
		
		sp = plotij(nrows,ncols,rowParams{cellstr(v),'rowNum'},colParams{cellstr(pd),'colNum'});
		
		sp.FontSize = p.Results.figFontSize;
		sp.XLim = rowParams{cellstr(v),'XL'};
		sp.YLim = rowParams{cellstr(v),'YL'};

        th = plot(atime,tempTrials);
		ah = plot(atime,tempAvg);
		
		% mark each trial with the trial number
		tn = trialNames.(char(pd));
		fl = footLifts.(char(pd));
		for th_i = 1:length(th)
			line_handle = th(th_i);
			line_tag = tn(th_i);
			line_handle.UserData.Tag = deblank(char(line_tag));
			line_handle.UserData.DisplayTag = false;
			line_handle.UserData.TagHandle = [];
			line_handle.ButtonDownFcn = @displayTag;
            if 0
			if fl(th_i)
				line_handle.Color = p.Results.footLiftColor;
			else
				line_handle.Color = p.Results.trialColor;
            end
            end
		end
		ah.Color = p.Results.avColor;
		ah.LineWidth = 1;
		
		n = size(tempTrials,1);
		nstr = "n = " + string(n);
		th = text(max(sp.XLim),max(sp.YLim),char(nstr));
		th.HorizontalAlignment='right';
		th.VerticalAlignment='top';
		th.FontSize = p.Results.textFontSize;
	end
end

for r = 1:size(rowParams,1)
	plotij(nrows,ncols,rowParams{r,'rowNum'},1);
	axis off
	th = text(0.5,0.5,rowParams.Label{r});
	th.FontSize = p.Results.labelFontSize;
end

for r = 1:size(colParams,1)
	plotij(nrows,ncols,1,colParams.colNum(r));
	axis off
	th = text(0.5,0.5,colParams.Properties.RowNames{r});
	th.HorizontalAlignment='right';
	th.FontSize = p.Results.labelFontSize;
end

plotij(nrows,ncols,1,1);
axis off
th = text(0.5,0.5,char(unique(dataTable.viconid)));
th.HorizontalAlignment = 'center';
th.FontSize = p.Results.labelFontSize;
th.FontWeight = p.Results.labelFontWeight;

srcDir = string(fileparts(char(p.Results.srcFile)));
figName = srcDir+'\'+extractBetween(srcFile,'PD_EEG\','.mat')+'.fig';
epsName = srcDir+'\'+extractBetween(srcFile,'PD_EEG\','.mat')+'.eps';
saveas(fg,char(figName))
print(fg,'-depsc2',char(epsName))





