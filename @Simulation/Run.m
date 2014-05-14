function [ sim ] = Run( sim )
% Run the simulation until an event occurs
% Handle the event and keep running
    X = [];
    T = [];
    
    if sim.Graphics == 1
        options=odeset('MaxStep',sim.tstep/10,'RelTol',.5e-7,'AbsTol',.5e-8,...
            'OutputFcn', @sim.Render, 'Events', @sim.Events);
    else
        options=odeset('MaxStep',sim.tstep/10,'RelTol',.5e-7,'AbsTol',.5e-8,...
            'Events', @sim.Events);
    end
    
    tspan = sim.tstart:sim.tstep:sim.tend;
    [TTemp,XTemp,TE,YE,IE] = ...
        ode45(@sim.Derivative,tspan,sim.IC,options); %#ok<ASGLU>
    
    if sim.infTime == 1
        TimeCond = true;
        sim.tend = sim.tend + TTemp(end)-tspan(1);
    else
        TimeCond = TTemp(end)<sim.tend;
    end
    
    % Save state and time
    SuppPos = [ones(length(TTemp),1)*sim.Mod.xS, ...
               ones(length(TTemp),1)*sim.Mod.yS];
    X = [X; XTemp];
    T = [T; TTemp];
    Torques = [];
    
    if sim.nOuts>0
        % Save torques
        TorquesTemp = zeros(length(TTemp),sim.nOuts);
        for j=1:length(TTemp)
            TorquesTemp(j,:) = sim.Con.NeurOutput()';
        end
        Torques = TorquesTemp;
    end

    while TimeCond && sim.StopSim == 0
        % Deal with it
        StoreIC = 0;
        Xa = XTemp(end,:);
        for ev = 1:length(IE)
            % Is it a model event?
            ModEvID = find(IE(ev) == sim.ModEv,1,'first');
            if ~isempty(ModEvID)
                [sim.Mod,Xa(sim.ModCo)] = ...
                    sim.Mod.HandleEvent(ModEvID, ...
                        XTemp(end,sim.ModCo),TTemp(end));

                % Handle event interactions
                if ModEvID == 1 % Ground contact
                    StoreIC = 1; % Store the initial conditions right after impact
                    
                    [sim.Con, Xa(sim.ModCo), Xa(sim.ConCo)] = ...
                        sim.Con.HandleExtFB(Xa(sim.ModCo),Xa(sim.ConCo));
                    
                    sim = sim.UpdateStats(TTemp,XTemp);
                    
                    if ~ischar(sim.Mod.curSpeed)
                        sim.TimeStr = ['t = %.2f s\nOsc.=%.3f\n',...
                         'Slope = %.2f ',char(176)','\nSpeed = %.3f m/s'];
                    end
                end
                
                if ModEvID == 2 % Robot fell down (hip height too low)
                    sim.Out.Type = 1;
                    sim.Out.Text = 'Robot fell down (hip height too low)';
                    sim.StopSim = 1;
                    break;
                end
            end

            % Is it a controller event?
            ConEvID = find(IE(ev) == sim.ConEv,1,'first');
            if ~isempty(ConEvID)
                [sim.Con,Xa(sim.ConCo)] = ...
                    sim.Con.HandleEvent(ConEvID, XTemp(end,sim.ConCo));

                % Handle event interactions
                switch ConEvID
                    case 1 % Neuron fired
                        sim.Mod.LegShift = sim.Mod.Clearance;
                    case 2 % Leg extension
                        sim.Mod.LegShift = 0;
                end 
            end
        end

        % Set new initial conditions
        sim.IC = Xa;
        if StoreIC
            sim.ICstore(:,2:end) = sim.ICstore(:,1:end-1);
            sim.ICstore(:,1) = sim.IC';
            sim = sim.CheckConvergence();
            
            if sim.Out.Type == 5
                % Simulation converged, calculate walking period
                StepTimes = T(diff(SuppPos(:,1))~=0);
                Periods = diff(StepTimes);
                sim.Period = [sim.Period, Periods(end)];
            end                
        end
        
        if sim.StopSim
            break;
        end

        % Continue simulation
        tspan = TTemp(end):sim.tstep:sim.tend;
        if length(tspan)<2
            % Can happen at the end of tspan
            break;
        end
        [TTemp,XTemp,TE,YE,IE] = ...
            ode45(@sim.Derivative,tspan,sim.IC,options); %#ok<ASGLU>
        
        if sim.infTime == 1
            TimeCond = true;
            sim.tend = sim.tend + TTemp(end)-tspan(1);
        else
            TimeCond = TTemp(end)<sim.tend;
        end
        
        % Save state and time
        SuppPos = [SuppPos;
                   ones(length(TTemp),1)*sim.Mod.xS, ...
                   ones(length(TTemp),1)*sim.Mod.yS]; %#ok<AGROW>
        X = [X; XTemp]; %#ok<AGROW>
        T = [T; TTemp]; %#ok<AGROW>
        
        if sim.nOuts>0
            % Save torques
            TorquesTemp = zeros(length(TTemp),sim.nOuts);
            for j=1:length(TTemp)
                TorquesTemp(j,:) = sim.Con.NeurOutput()';
            end
            Torques = [Torques; TorquesTemp]; %#ok<AGROW>
        end
    end
    
    % Prepare simulation output
    sim.Out.X = X;
    sim.Out.T = T;
    sim.Out.SuppPos = SuppPos;
    sim.Out.Torques = Torques;
    sim.Out.nSteps = sim.StepsTaken;
    sim.Out.StepsSS = sim.stepsSS;
    sim.Out.MaxSlope = [sim.MinSlope, sim.MaxSlope];
end
