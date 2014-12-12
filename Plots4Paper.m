function Plots4Paper()
% Plotting parameters
InputFile = 'GA_11_24_10_25.mat';
SelectedGen = 4;

AutoLC = 0; % Set to 1 to plot the LC for the steepest up/downward slope
% Otherwise set the desired values here (in degrees):
DSLC = -8.0;
USLC = 7.0;    

% DoPlots = [1,... Initial Conditions
%            2,... Torques plot
%            3,... Limit cycles
%            4,... Eigenvalues vs slope
%            5,... Eigenvalues locus
%            6]; % MOOGA statistics
DoPlots = 6;
       
% Plots format
AxesFont = 16;
LabelFont = 18;
TitleFont = 20;
LineWidth = 4;
AxesLineWidth = 2;
LineStyles = {'-',':','--','-.','-*','-o'};
Markers = {'+','o','d','^','v'};
Colors = {[0 0 1],[1 0 0],[0 0.7 0.8],[0 0.7 0],[0.8 0 0.8]};
Legends = {'\theta_1','\theta_2','d\theta_1/dt',...
                    'd\theta_2/dt','\phi_C_P_G'};
Genes = {'f_{osc}','\phi_{ext}','T_1','\phi_1','\Delta\phi_1',...
         'T_2','\phi_2','\Delta\phi_2','T_3','\phi_3',...
         '\Delta\phi_1','k_f^+','k_1^+','k_2^+','k_3^+',...
         'k_f^-','k_1^-','k_2^-','k_3^-'};
Fits = {'Velocity','Efficiency','Stability','Up*Down','Up','Down'};

% Close open figures
close all;

% Load data
if ~exist('GA','var')
    In = load(InputFile);
    GA = In.GA;
end
Data = GA.Analyze(GA.Progress,SelectedGen,'CL');

if AutoLC == 1
    DSLC = 1;
    USLC = length(Data.Slopes);
else
    DSLC = find(Data.Slopes >= DSLC,1,'first');
    USLC = find(Data.Slopes <= USLC,1,'last');
end
    
% Show genome results
% GA.DisplayGen(SelectedGen);

%% %%%%%%%%%%%%% Begin plots %%%%%%%%%%%%% %%

% Number of system coordinates
Ncoords = size(Data.IC,1)/max(Data.Period(:,1));

% Plot walking speed VS slope
% plot(Data.Slopes,sin(abs(Data.IC(1,:)-Data.IC(2,:))/2)*2./cellfun(@max,Data.LCt))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% IC plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(1,DoPlots)
    % Plot angles, angular velocities and CPG phase in 3 subplots
    figure('units','normalized','Position',[0.3,0.03,0.35,0.8]);
    spheight = [4,4,2]; % Define subplot height
    Nsp = sum(spheight);

    lh = DoSubplot(1,[1,2]);
    set(gca,'XTickLabel',[]);
    ylabel('Angles [rad]','FontSize',LabelFont);
    set(lh,'Location','SouthEast');

    lh = DoSubplot(2,[3,4]);
    set(gca,'XTickLabel',[]);
    ylabel('Ang. velocities [rad/sec]','FontSize',LabelFont);
    set(lh,'Location','NorthWest');

    DoSubplot(3,5);
    xlabel('Slope [deg]','FontSize',LabelFont);
    ylabel('CPG phase','FontSize',LabelFont);
%     set(lh,'Location','SouthEast');
end

    function lh = DoSubplot(sp,coords)
        spID0 = sum(spheight(1:sp-1))+1;
        spIDs = spID0:spID0+spheight(sp)-1;
        subplot(Nsp,1,spIDs);
        hold on
        h = zeros(Ncoords,1);
        for p = 1:length(Data.Zones)
            pZone = Data.Zones{p};
            for z = 1:length(pZone)
                zIDs = pZone{z};
                for c = coords
                    StCoord = (p-1)*Ncoords+c;
                    h(c) = plot(Data.Slopes(zIDs),Data.IC(StCoord,zIDs),...
                        LineStyles{c},'LineWidth',LineWidth,...
                        'Color',Colors{c});
                end
            end
        end
        axis([min(Data.Slopes) max(Data.Slopes) ylim])
        lh = legend(h(coords),Legends(coords),'FontSize',AxesFont);
        set(gca,'FontSize',AxesFont,'LineWidth',AxesLineWidth);
    end

%%%%%%%%%%%%%%%%% CPG phase / Torque signal plot %%%%%%%%%%%%%%%%%
if ismember(2,DoPlots)
    % Plot the CPG phase and torque signal for a specific slope

    SlopeID = find(Data.Slopes == 0, 1, 'first');
%     SlopeID = length(Data.Slopes);

    T = Data.LCt{SlopeID};
    CPGphi = Data.LCx{SlopeID}(:,5);
    Torques = Data.LCtorques{SlopeID};

    ShiftKind = 2;
    if ShiftKind == 1
        % Shift the signal so it doesn't necessarily start right after impact
        Shift = 0.25; % Percentage of period
        ShiftN = round(Shift*length(T));
    else
        % Shift the signal so it fits a CPG cycle
        ShiftN = find(CPGphi == 0, 1, 'first');
    end

    % Find new impact time
    DeltaT = T(end) - T(ShiftN);
    ImpN = find(T >= DeltaT, 1, 'first');

    % T = [T(ShiftN:end); T(1:ShiftN-1)];
    Torques = [Torques(ShiftN:end,:); Torques(1:ShiftN-1,:)];
    CPGphi = [CPGphi(ShiftN:end,:); CPGphi(1:ShiftN-1,:)];

    figure('units','normalized','Position',[0.25,0.15,0.33,0.6]);
%     subplot(3,1,[1 2]);
    hold on
    plot(CPGphi,Torques(:,1),...
        LineStyles{2},'LineWidth',LineWidth,'Color',Colors{1});
    plot(CPGphi,Torques(:,2),...
        LineStyles{1},'LineWidth',LineWidth,'Color',Colors{2});
    hl = legend('Ankle','Hip');
    set(hl,'FontSize',LabelFont);
%     set(gca,'XTickLabel',[]);
    set(gca,'FontSize',AxesFont,'LineWidth',AxesLineWidth);
    xlabel('CPG phase (mod 1)','FontSize',LabelFont);
    ylabel('Torques [Nm]','FontSize',LabelFont);
    axis([CPGphi(1) CPGphi(end) ylim])

    % Add impact time
    MaxT = max(max(Torques));
    text(CPGphi(ImpN),0.3*MaxT,'Impact','rotation',90,'FontSize',12);
    DrawArrow([CPGphi(ImpN),0.3*MaxT],[CPGphi(ImpN),0.03*MaxT]);

%     subplot(3,1,3);
%     hold on
%     plot(CPGphi,CPGphi,...
%         LineStyles{3},'LineWidth',LineWidth,'Color',Colors{3});
%     set(gca,'FontSize',AxesFont,'LineWidth',AxesLineWidth);
%     xlabel('Time [sec]','FontSize',LabelFont);
%     ylabel('CPG Phase','FontSize',LabelFont);
%     axis([CPGphi(1) CPGphi(end) ylim])
end

    function DrawArrow(Tail, Head)
        Dir=Head-Tail;
        Dir=Dir/norm(Dir);
        AR = ylim/xlim;
        TrDir=[-Dir(2) Dir(1)]/AR; % transverse direction
        hLength=0.15*norm(Head-Tail);

        % Plot arrow
        Points=[Head;
                Head-hLength*Dir-hLength/4*TrDir;
                Head-hLength*Dir+hLength/4*TrDir;
                Tail];
        line(Points([1 4],1),[Points(2,2) Points(4,2)*0.9],...
            'LineWidth',3,'Color',[0 0 0]);
        patch(Points(1:3,1), Points(1:3,2),[0,0,0],'EdgeColor',[0,0,0]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%% Limit cycle plot %%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(3,DoPlots)
    TitleSpacing = 0.12;
    LabelSpacing = 0.07;
    TickSpacing = 0.04;
    AxHeight = 1-TitleSpacing-LabelSpacing;
    AxWidth = (1-3*TickSpacing-2*LabelSpacing)/3;
    Pos = zeros(3,4);
    Pos(1,:) = [LabelSpacing+TickSpacing,...
                LabelSpacing+TickSpacing,...
                AxWidth, AxHeight];
    Pos(2,:) = Pos(1,:) + [AxWidth+TickSpacing 0 0 0];
    Pos(3,:) = Pos(2,:) + [AxWidth+TickSpacing 0 0 0];
    
    % Plot the limit cycle for a level slope and steepest up/downwards slope
    LCEqual = 0;
    figure('units','normalized','Position',[0.1,0.15,0.8,0.55]);
    axes('units','normalized','Position',Pos(1,:));
    PlotLC(DSLC);
    ylabel('Ang. velocity [rad/sec]','FontSize',LabelFont);

    axes('units','normalized','Position',Pos(2,:));
    PlotLC(find(Data.Slopes == 0, 1,'first'));
    xlabel('Leg Angle [rad]','FontSize',LabelFont);

    axes('units','normalized','Position',Pos(3,:));
    PlotLC(USLC);
end

    function PlotLC(Slope)
        th1 = Data.LCx{Slope}(:,1);
        th2 = Data.LCx{Slope}(:,2);
        th1t = Data.LCx{Slope}(:,3);
        th2t = Data.LCx{Slope}(:,4);
        
        % Extend plots to connect to the next
        th1e = [th1;th2(1)];
        th2e = [th2;th1(1)];
        th1te = [th1t;th2t(1)];
        th2te = [th2t;th1t(1)];
        
        hold on
        plot(th1e,th1te,LineStyles{1},'LineWidth',LineWidth,...
            'Color',Colors{1});
        plot(th1e(1),th1te(1),'.','MarkerSize',20,...
            'LineWidth',LineWidth,'Color',Colors{1});
        plot(th2e,th2te,LineStyles{2},'LineWidth',LineWidth,...
            'Color',Colors{2});
        plot(th2e(1),th2te(1),'.','MarkerSize',20,...
            'LineWidth',LineWidth,'Color',Colors{2});
        set(gca,'FontSize',AxesFont,'LineWidth',AxesLineWidth);
        title(sprintf('Slope: %.2f\\circ',Data.Slopes(Slope)),...
            'FontSize',LabelFont);
        if LCEqual
            axis([-0.4 0.5 -3 3])
        end
    end
        
%%%%%%%%%%%%%%%%%%%%%%%%% Eigenvalues plot %%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(4,DoPlots)
    % Plot the Poincare map eigenvalues over the range of slopes
    figure('units','normalized','Position',[0.2,0.1,0.5,0.65]);
    % Separate into zones
    zID = find(diff(Data.Period(DSLC:USLC,1))~=0);
    zID = [zID; USLC];
    sID = DSLC;
    ZoneLetter = 0;
    for z = 1:length(zID)
        IDs = sID:zID(z);
        sID = zID(z)+1;
        if length(IDs)<2
            continue
        end
        plot(Data.Slopes(IDs),abs(Data.EigV(:,IDs)),...
            'LineWidth',LineWidth);
        if length(zID)>1
            % Add zone letter and display period number
            zmid = mean(Data.Slopes(IDs));
            ZString = [char(ZoneLetter+'A'),' - ',...
                int2str(Data.Period(IDs(1),1))];
            ZoneLetter = ZoneLetter+1;
            text(zmid,0.95,ZString,'FontSize',AxesFont,...
                'HorizontalAlignment','center');
        end
        if z<length(zID)
            % Add a vertical line
            Lx = (Data.Slopes(sID)+Data.Slopes(sID-1))/2;
            line([Lx Lx],[0 1],'LineWidth',LineWidth,...
                'Color',[0 0 0])
        end
    end
    % plot(Data.Slopes,Data.Period(:,1));
    axis([Data.Slopes(DSLC) Data.Slopes(USLC) 0 1])
    set(gca,'FontSize',AxesFont,'LineWidth',AxesLineWidth);
    xlabel('Slope [deg]')
    ylabel('|\lambda_i|')
end


%%%%%%%%%%%%%%%%%%%%% Eigenvalues locus plot %%%%%%%%%%%%%%%%%%%%%
if ismember(5,DoPlots)
    % Plot the Poincare map eigenvalues over the range of slopes
end


%%%%%%%%%%%%%%%%%%%%% MOOGA statistics plot %%%%%%%%%%%%%%%%%%%%%
if ismember(6,DoPlots)
    % Plot statistics for evolved genomes based on the final parameter
    % distribution
    
    [GoodIDs,~] = GA.GetTopPop(GA.Fittest(1)); % fitness = genes
    AllFits = GA.Fit(:,:,GA.Progress);
    
    % Weed out genomes with some fit == 0
%     GoodIDs = all(AllFits~=0,2);
    GoodFits = AllFits(GoodIDs,:);
    GoodParams = GA.Seqs(GoodIDs,:,GA.Progress);
    GF = GoodFits;
    GP = GoodParams;
    
    ClimbIDs = GoodFits(:,4)>30;
    ClimbFits = GoodFits(ClimbIDs,:);
    ClimbParams = GoodParams(ClimbIDs,:);
    
    RemoveIDs(ClimbIDs);
    
%     ClimbUpIDs = GoodFits(:,5)>5;
%     ClimbUpFits = GoodFits(ClimbUpIDs,:);
%     ClimbUpParams = GoodParams(ClimbUpIDs,:);
%     
%     ClimbDownIDs = GoodFits(:,6)>5;
%     ClimbDownFits = GoodFits(ClimbDownIDs,:);
%     ClimbDownParams = GoodParams(ClimbDownIDs,:);
    
    SlowIDs = GoodFits(:,2)>0.995;
    SlowFits = GoodFits(SlowIDs,:);
    SlowParams = GoodParams(SlowIDs,:);
    
    RemoveIDs(SlowIDs);
    
    FastIDs = GoodFits(:,1)>0.4;
    FastFits = GoodFits(FastIDs,:);
    FastParams = GoodParams(FastIDs,:);
    
    RemoveIDs(FastIDs);
    
    StabIDs = GoodFits(:,3)>0.6;
    StabFits = GoodFits(StabIDs,:);
    StabParams = GoodParams(StabIDs,:);
    
%     GrLegends = {'General','Ascend','Descend','Efficient'};
%     GrLegends = {'General','Climbers','Efficient'};
%     GrLegends = {'General','Climbers','Efficient','Stable'};
    GrLegends = {'Climbers','Efficient','Fast','Stable','General'};
    
    PlotAvgTorque(FastParams,1);
    PlotAvgTorque(ClimbParams,4);
    PlotAvgTorque(StabParams,3);
    PlotAvgTorque(SlowParams,2);
    
    % 30 bins for fitness
    % 20 bins for genes
    Nbins = 20;
    
    PlotGenes([1,12,16]);
    PlotGenes(3:11);
    PlotGenes([13:15,17:19]);
    
    figure
    for sp=1:4
        hmin = min(GF(:,sp));
        hmax = max(GF(:,sp));
        xvalues = linspace(hmin,hmax,Nbins);
        padding = (hmax-hmin)/Nbins;
        nelements = zeros(length(xvalues),length(GrLegends)-1);
        
        MySubplot(2,2,sp);
        hold on
        nelements(:,1) = hist(ClimbFits(:,sp),xvalues);
%         hist(ClimbUpFits(:,sp),xvalues);
%         hist(ClimbDownFits(:,sp),xvalues);
        nelements(:,2) = hist(SlowFits(:,sp),xvalues);
        nelements(:,3) = hist(FastFits(:,sp),xvalues);
        nelements(:,4) = hist(StabFits(:,sp),xvalues);
        
        bar_h = bar(xvalues,nelements,'stacked');
        SetBarColors(bar_h);
%         hist(GF(:,sp),xvalues);
        
        h = findobj(gca,'Type','patch');
        set(h,'Facecolor',[1 1 1],'EdgeColor','k','facealpha',0);
        title(Fits{sp})
%         tx = 0.05;
%         if sp == 3
%             tx = 0.7;
%         end
%         text(tx,0.88,Fits{sp},'Units','normalized',...
%               'VerticalAlignment','bottom',...
%               'HorizontalAlignment','left',...
%               'FontSize',AxesFont);
        axis([hmin-padding hmax+padding ylim])
        set(gca,'FontSize',AxesFont,'LineWidth',2);
    end
    legend(GrLegends)
    
    
end

    function PlotGenes(IDs)
        figure
        NRows = ceil(length(IDs)/3);
        for gi=1:length(IDs)
            gp = IDs(gi);
            
            hmin = min(GP(:,gp));
            hmax = max(GP(:,gp));
            xvalues = linspace(hmin,hmax,Nbins);
            padding = (hmax-hmin)/Nbins;
            nelements = zeros(length(xvalues),length(GrLegends)-1);

            MySubplot(NRows,3,gi);
            hold on
            nelements(:,1) = hist(ClimbParams(:,gp),xvalues);
    %         hist(ClimbUpParams(:,gp),xvalues);
    %         hist(ClimbDownParams(:,gp),xvalues);
            nelements(:,2) = hist(SlowParams(:,gp),xvalues);
            nelements(:,3) = hist(FastParams(:,gp),xvalues);
            nelements(:,4) = hist(StabParams(:,gp),xvalues);

            bar_h = bar(xvalues,nelements,'stacked');
            SetBarColors(bar_h);
%             hist(GP(:,gp),xvalues);

            h = findobj(gca,'Type','patch');
            set(h,'Facecolor',[1 1 1],'EdgeColor','k','facealpha',0);
            title(Genes{gp})
%             text(0.1,0.85,Genes{gp},'Units','normalized',...
%                   'VerticalAlignment','bottom',...
%                   'HorizontalAlignment','left',...
%                   'FontSize',AxesFont);
            axis([hmin-padding hmax+padding ylim])
            set(gca,'FontSize',AxesFont,'LineWidth',2);
        end
    end

    function PlotAvgTorque(Params,Style)
        nG = size(Params,1);
        
        % Prepare torque signal
        MaxPeriod = max(1./Params(:,1));
        dT = 0.001;
        Torque = zeros(ceil(MaxPeriod/dT),2);
        mT = zeros(1,nG);
        
        % Load signal for each genome
        for ge = 1:nG
            gSim = deepcopy(GA.Sim);
            gSim = GA.Gen.Decode(gSim,Params(ge,:));
            phi_step = dT*Params(ge,1);
            [Time,TorqueSig] = gSim.Con.GetTorqueSig(phi_step,1);
            range = 1:length(TorqueSig);
            Torque(range,:) = Torque(range,:) + TorqueSig/nG;
            mT(ge) = max(max(abs(TorqueSig)));
        end
        
        % Prepare time vector
        Time = linspace(0,MaxPeriod,length(Torque));
        
        figure(1)
        MySubplot(2,2,Style);
        hold on
%         plot(Time/MaxPeriod,Torque(:,1),'r--','LineWidth',2);
%         plot(Time/MaxPeriod,Torque(:,2),'b--','LineWidth',2);
        gSim = deepcopy(GA.Sim);
        gSim = GA.Gen.Decode(gSim,mean(Params));
        phi_step = dT*mean(Params(:,1));
        [Time,TorqueSig] = gSim.Con.GetTorqueSig(phi_step,1);
%         plot(Time/max(Time),TorqueSig(:,1),LineStyles{2},...
%             'Color',Colors{Style},'LineWidth',2);
%         plot(Time/max(Time),TorqueSig(:,2),LineStyles{1},...
%             'Color',Colors{Style},'LineWidth',2)
        area(Time/max(Time),TorqueSig(:,1),'LineStyle',LineStyles{2},...
            'FaceColor',Colors{Style},'LineWidth',2);
        area(Time/max(Time),TorqueSig(:,2),'LineStyle',LineStyles{1},...
            'FaceColor',Colors{Style},'LineWidth',2);
        
        set(gca,'FontSize',AxesFont);
        switch Style
            case 1
                title('Fast walkers')
            case 2
                title('Efficient walkers')
            case 3
                title('Quick convergence')
            case 4
                title('Good climbers')
                h1 = plot(0,0,LineStyles{2},'Color',[0 0 0],'LineWidth',2);
                h2 = plot(0,0,LineStyles{1},'Color',[0 0 0],'LineWidth',2);
                legend([h1; h2],{'ankle','hip'})
        end
        axis([0 1 -15 55])
    end

    function SetBarColors(bar_h)
        for gr = 1:length(bar_h)
            set(bar_h(gr),'FaceColor',Colors{gr});
        end
        set(bar_h,'LineWidth',2);
    end

    function RemoveIDs(IDs)
%         GoodParams(IDs,:) = [];
%         GoodFits(IDs,:) = [];
    end

    function MySubplot(Ny,Nx,N)
        % For fitness plot
        if Nx == 2
            yPad = 0.03;
            TitlePad = 0.08;
            xPad = 0.06;
        else
            if Ny == 1
                yPad = 0.07;
                TitlePad = 0.16;
                xPad = 0.06;
            elseif Ny == 2
                yPad = 0.07;
                TitlePad = 0.16;
                xPad = 0.06;
            else
                yPad = 0.04;
                TitlePad = 0.08;
                xPad = 0.06;
            end
        end
        
        xAx = (1-xPad*(Nx+1))/Nx;
        yAx = (1-TitlePad*Ny-yPad*(Ny+1))/Ny;
        
        Col = 1+mod((N-1),Nx);
        Row = 1+floor((N-1)/Nx);
        
        AxPos = [xPad + (xPad+xAx)*(Col-1),...
                 1 - TitlePad*Row - yAx*Row - yPad*(Row-1), xAx, yAx];
        axes('Position',AxPos);
    end
end