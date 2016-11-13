data1 = load('MatsRandomRes.mat');
data2 = load('MatsScaledRes.mat');
data3 = load('MatsNNRes1.mat');

MML = MatsuokaML();
MML.perLim = [0.68 0.78];
MML.perLimOut = MML.perLim + [-0.08 0.08]; % Desired period range
MML.tStep = 0.01; % 0.01
MML.tEnd = 15; % 15

perRange = [min(data3.desPeriod(:)), max(data3.desPeriod(:))];
randPeriods = data1.periods(~isnan(data1.periods));
randPeriods(randPeriods>perRange(2)*5) = [];
randPeriods(randPeriods<perRange(1)/5) = [];
scalPeriods = data2.periods(~isnan(data2.periods));
scalPeriods(scalPeriods>perRange(2)*5) = [];
scalPeriods(scalPeriods<perRange(1)/5) = [];

% Plot histogram of periods
% figure
% hold on
% histogram(randPeriods,50,'facecolor',[1,0,0],'facealpha',0.5)
% histogram(scalPeriods,50,'facecolor',[0,0,1],'facealpha',0.5)

Nbins = 200;
[N1, bins1] = histcounts(randPeriods,Nbins);
N1 = N1/max(N1);
[N2, bins2] = histcounts(scalPeriods,Nbins);
N2 = N2/max(N2);

bins1n = (bins1 - min(bins1))/(max(bins1) - min(bins1));

% Plot heat map of periods
figure
subplot(2,1,1)
imagesc(N1)
axis off
set(gca,'FontSize',12);
title('Period distribution of random parameters')
subplot(2,1,2)
imagesc(N2)
set(gca,'YTickLabel',[]);
set(gca,'XTick',bins1n(1:Nbins/10:end)*Nbins);
set(gca,'XTickLabel',bins1(1:Nbins/10:end));
box off
title('Period distribution of random parameters after re-scaling')
set(gca,'FontSize',12);
set(gca,'FontWeight','bold');

% Plot scatter of random periods and parameters
good_ids = ~isnan(data1.periods);
periods = data1.periods(good_ids);
params = vertcat(data1.results.seq);
% Get only theta and beta
theta = params(good_ids,1);
beta = params(good_ids,2);
figure
subplot(1,2,1)
scatter(theta, periods, '*');
ylabel('CPG Period [sec]');
xlabel('\tau_r')
set(gca,'FontSize',12)
set(gca,'FontWeight','bold')
subplot(1,2,2)
scatter(beta, periods, '*');
xlabel('b')
set(gca,'FontSize',12)
set(gca,'FontWeight','bold')

% Plot scatter of scaled periods and parameters
good_ids = ~isnan(data2.periods);
periods = data2.periods(good_ids);
params = vertcat(data2.results.seq);
% Get only theta and beta
theta = params(good_ids,1);
beta = params(good_ids,2);
figure
subplot(1,2,1)
scatter(theta, periods, '*');
ylabel('CPG Period [sec]');
xlabel('\tau_r')
set(gca,'FontSize',12)
set(gca,'FontWeight','bold')
subplot(1,2,2)
scatter(beta, periods, '*');
xlabel('b')
set(gca,'FontSize',12)
set(gca,'FontWeight','bold')

% Plot histogram of all parameters
params = vertcat(data1.results.seq);
figure
for i = 1:23
    subplot(5,5,i);
    hist(params(:,i),100);
end
good_ids = ~isnan(data1.periods);
good_params = params(good_ids,:);
figure
for i = 1:23
    subplot(5,5,i);
    hist(good_params(:,i),100);
end

% Plot distribution for parameters "on average"
ids = {1;       % tau_r
       2;       % b
       7:18};   % weights
labels = {'\tau_r', 'b', 'W_{ij}'};
pars_norm = zeros(12*250000,1);
total = 0;
for i = 1:length(data1.results)
    if isnan(data1.periods(i))
        continue
    end
    W = data1.results(i).W;
    W(W == 0) = [];
    pars_norm(total+1:total+12) = W(:);
    total = total+12;
end
pars_norm = pars_norm(1:total+1);
pars_norm_b = pars_norm(pars_norm<25);
pars_norm_b = pars_norm_b(pars_norm_b>-5);

figure
for i = 1:length(ids)
    subplot(2,2,i);
    pars = good_params(:,ids{i});
    hist(pars(:),25)
    xlabel(labels{i});
    xlim([min(pars(:)) max(pars(:))]);
    set(gca,'YTickLabel',[], 'FontSize',12, 'FontWeight', 'bold');
end
subplot(2,2,4);
hist(pars_norm_b,25)
xlabel(labels{3});
xlim([min(pars_norm_b(:)) max(pars_norm_b(:))]);
set(gca,'YTickLabel',[], 'FontSize',12, 'FontWeight', 'bold');

% Plot NN Performance for different features
data4 = load('MatsNNTests.mat');
selected_meas = [2,3,4];
meas_labels = {'Converged ','Converged within range ','Accuracy'};

% Update the network performance
Nnets = data4.nCombos;
NNSamples = size(data4.sampPerf,2);
netPerf2 = data4.netPerf;
for i = 1:Nnets
    sampPerf = data4.sampPerf(i,:);
    desPeriod = data4.desPeriod(i,:);

    % How many converged?
    id_conv = find(~isnan(sampPerf));
    netPerf2(i,2) = length(id_conv)/NNSamples;
    
    % How many converged to the desired range?
    id_per = find(sampPerf >= MML.perLimOut(1) ...
        & sampPerf <= MML.perLimOut(2));
    netPerf2(i,3) = length(id_per)/NNSamples;
    
    % How close was the period to the desired period?
    sampDiff = (sampPerf - desPeriod)./desPeriod;
    netPerf2(i,4) = sum(sampDiff(id_conv).^2)/length(id_conv);
end
    
bar_data = netPerf2(:,selected_meas);
bar_data(:,end) = 1./(1+bar_data(:,end));

new_combo_order = [5,1,8,4,7,3,9,10,6,2];
for i = 1:Nnets
    comb_id = new_combo_order(i);
    combo_string = [int2str(comb_id),' -> (',int2str(i),') Features: '];
    feats = data4.sample_genes{data4.combos(comb_id,1)};
    trgts = data4.target_genes{data4.combos(comb_id,2)};
    for j = 1:numel(feats)
        combo_string = [combo_string, feats{j}, ', '];
    end
    combo_string = [combo_string(1:end-2), ' | Targets: '];
    for j = 1:numel(trgts)
        combo_string = [combo_string, trgts{j}, ', '];
    end
    disp(combo_string(1:end-2));
end
    
% Sort data by first column
data_ids = [(1:size(bar_data,1))',bar_data];
data_ids = sortrows(data_ids, -2);
inv_new_order = zeros(size(new_combo_order));
for i = 1:Nnets
inv_new_order(i) = find(new_combo_order == data_ids(i,1), 1, 'first');
end

% figure
% bar(bar_data);

figure
bar(data_ids(:,2:end));
legend(meas_labels, 'Orientation', 'Horizontal','Location','Best');
xlim([0.5 Nnets+0.5])
ylim([0 1])
set(gca,'FontSize',12,'FontWeight','bold')
set(gca, 'XTickLabel', inv_new_order)
% colormap(flipud(colormap('summer'))*diag([0.6, 0.8, 0.]))
colormap(flipud(0.5*(colormap('summer')+colormap('winter'))) ...
    * diag([0.6, 0.8, 0.6]))
grid on
grid minor

% Plot NN Performance for different architectures
selected_meas = [3,4];
meas_labels = {'Converged within range ','Accuracy'};
bar_labels = cellfun(@num2str,data3.architectures,'UniformOutput',false);
% Update the network performance
Nnets = data3.nArch;
NNSamples = size(data3.sampPerf,2);
netPerf2 = data3.netPerf;
for i = 1:Nnets
    sampPerf = data3.sampPerf(i,:);
    desPeriod = data3.desPeriod(i,:);

    % How many converged?
    id_conv = find(~isnan(sampPerf));
    netPerf2(i,2) = length(id_conv)/NNSamples;
    
    % How many converged to the desired range?
    id_per = find(sampPerf >= MML.perLimOut(1) ...
        & sampPerf <= MML.perLimOut(2));
    netPerf2(i,3) = length(id_per)/NNSamples;
    
    % How close was the period to the desired period?
    sampDiff = (sampPerf - desPeriod)./desPeriod;
    netPerf2(i,4) = sum(sampDiff(id_conv).^2)/length(id_conv);
end
    
bar_data = netPerf2(:,selected_meas);
bar_data(:,end) = 1./(1+bar_data(:,end));
    
% Sort data by first column
data_ids = [(1:size(bar_data,1))',bar_data];
data_ids = sortrows(data_ids, -2);
inv_new_order = zeros(size(new_combo_order));
for i = 1:Nnets
inv_new_order(i) = find(new_combo_order == data_ids(i,1), 1, 'first');
end

figure
bar(data_ids(:,2:end));
legend(meas_labels, 'Orientation', 'Horizontal','Location','Northeast');
xlim([0.5 Nnets+0.5])
ylim([0 1])
set(gca,'FontSize',12,'FontWeight','bold')
set(gca, 'XTickLabel', bar_labels)
% colormap(flipud(colormap('summer'))*diag([0.6, 0.8, 0.]))
colormap(flipud(0.5*(colormap('summer')+colormap('winter'))) ...
    * diag([0.6, 0.8, 0.6]))
grid on
grid minor


% Plot NN Performance for different architectures with # of samples
data5 = load('MatsNNRes2.mat');
data6 = load('MatsNNRes3.mat');

% Update network performance
nSampleSizes = data5.nSampleSizes;
NNSamples = size(data5.sampPerf,2);
netPerf5 = data5.netPerf;
netPerf6 = data6.netPerf;
for i = 1:nSampleSizes
    sampPerf1 = data5.sampPerf(i,:);
    desPeriod1 = data5.desPeriod(i,:);
    sampPerf2 = data6.sampPerf(i,:);
    desPeriod2 = data6.desPeriod(i,:);

    % How many converged?
    id_conv1 = find(~isnan(sampPerf1));
    netPerf5(i,2) = length(id_conv1)/NNSamples;
    id_conv2 = find(~isnan(sampPerf2));
    netPerf6(i,2) = length(id_conv2)/NNSamples;
    
    % How many converged to the desired range?
    id_per1 = find(sampPerf1 >= MML.perLimOut(1) ...
        & sampPerf1 <= MML.perLimOut(2));
    netPerf5(i,3) = length(id_per1)/NNSamples;
    id_per2 = find(sampPerf2 >= MML.perLimOut(1) ...
        & sampPerf2 <= MML.perLimOut(2));
    netPerf6(i,3) = length(id_per2)/NNSamples;
    
    % How close was the period to the desired period?
    sampDiff1 = (sampPerf1 - desPeriod1)./desPeriod1;
    netPerf5(i,4) = sum(sampDiff1(id_conv1).^2)/length(id_conv1);
    sampDiff2 = (sampPerf2 - desPeriod2)./desPeriod2;
    netPerf6(i,4) = sum(sampDiff2(id_conv2).^2)/length(id_conv2);
end

selected_meas = [2,3,4];
meas_labels = {'Conv. ','Conv. within range ','Accuracy'};

plot_data5 = netPerf5(:,selected_meas);
plot_data5(:,end) = 1./(1+plot_data5(:,end));
plot_data6 = netPerf6(:,selected_meas);
plot_data6(:,end) = 1./(1+plot_data6(:,end));
x_data = data5.sampleSizes;
x_labels = cellfun(@(x){num2str(x, '%.1f')}, ...
    num2cell(data5.sampleSizes/1000));

figure
colors = {[1,0,0], [0.2,0.8,0], [0,0,1]};
lineWidth = 1; lineWidthLeg = 2;
h = semilogx(x_data,plot_data5(:,1),'--');
set(h,'Color',colors{1}, 'LineWidth', lineWidth);
hold on
h = semilogx(x_data,plot_data5(:,2),'--');
set(h,'Color',colors{2}, 'LineWidth', lineWidth);
h = semilogx(x_data,plot_data5(:,3),'--');
set(h,'Color',colors{3}, 'LineWidth', lineWidth);
h = semilogx(x_data,plot_data6(:,1),'-.');
set(h,'Color',colors{1}, 'LineWidth', lineWidth);
h = semilogx(x_data,plot_data6(:,2),'-.');
set(h,'Color',colors{2}, 'LineWidth', lineWidth);
h = semilogx(x_data,plot_data6(:,3),'-.');
set(h,'Color',colors{3}, 'LineWidth', lineWidth);
h1 = plot(0,0,'k--', 'LineWidth', lineWidthLeg);
h2 = plot(0,0,'k-.', 'LineWidth', lineWidthLeg);
h3 = plot(0,0,'-','Color',colors{1}, 'LineWidth', lineWidthLeg);
h4 = plot(0,0,'-','Color',colors{2}, 'LineWidth', lineWidthLeg);
h5 = plot(0,0,'-','Color',colors{3}, 'LineWidth', lineWidthLeg);
legend([h1, h2, h3, h4, h5],...
    [{['Neurons: ',int2str(data5.architecture),' '],...
    ['Neurons: ',int2str(data6.architecture),' ']}, meas_labels]',...
    'Orientation','Horizontal','Location','Northwest')
xlim([min(x_data) max(x_data)])
ylim([0,1])
set(gca,'FontSize',12, 'FontWeight','bold')


% Sort data by first column
data_ids = [(1:size(bar_data,1))',bar_data];
data_ids = sortrows(data_ids, -2);
inv_new_order = zeros(size(new_combo_order));
for i = 1:Nnets
inv_new_order(i) = find(new_combo_order == data_ids(i,1), 1, 'first');
end

figure
bar(data_ids(:,2:end));
legend(meas_labels, 'Orientation', 'Horizontal','Location','Northeast');
xlim([0.5 Nnets+0.5])
ylim([0 1])
set(gca,'FontSize',12,'FontWeight','bold')
set(gca, 'XTickLabel', bar_labels)
% colormap(flipud(colormap('summer'))*diag([0.6, 0.8, 0.]))
colormap(flipud(0.5*(colormap('summer')+colormap('winter'))) ...
    * diag([0.6, 0.8, 0.6]))
grid on
grid minor


% Show GA results
GA1 = load('VGAM_11_09_13_55.mat');
GA2 = load('VGAM_11_09_06_37_RS.mat');
GA3 = load('VGAM_11_08_10_55_NNRS.mat');
x_data = 1:GA1.GA.Generations;
y_data1 = squeeze(max(GA1.GA.Fit(:,3,:),[],1));
y_data2 = squeeze(max(GA2.GA.Fit(:,3,:),[],1));
y_data3 = squeeze(max(GA3.GA.Fit(:,3,:),[],1));
y_data1m = squeeze(mean(GA1.GA.Fit(:,3,:),1));
y_data2m = squeeze(mean(GA2.GA.Fit(:,3,:),1));
y_data3m = squeeze(mean(GA3.GA.Fit(:,3,:),1));
legends = {'MOGA','MOGA + re-scaling','MOGA + NN + re-scaling'};

figure
hold on
plot(x_data, y_data1);
plot(x_data, y_data2);
plot(x_data, y_data3);
% plot(x_data, y_data1m,'--');
% plot(x_data, y_data2m,'--');
% plot(x_data, y_data3m,'--');
legend(legends, 'Location', 'Southeast');

% Show GA distance
diversity_file = 'MatsDisversity.mat';
if exist(diversity_file, 'file') ~= 2
    NGens = GA1.GA.Generations;
    Nn = GA1.GA.Population;
    dist1 = zeros(Nn,NGens);
    dist2 = zeros(Nn,NGens);
    dist3 = zeros(Nn,NGens);
    for i = 1:NGens
        dist1(:,i) = GA1.GA.GetDistance(i);
        dist2(:,i) = GA2.GA.GetDistance(i);
        dist3(:,i) = GA3.GA.GetDistance(i);
    end
    save(diversity_file,'NGens','Nn','dist1','dist2','dist3');
else
    load(diversity_file);
end

x_data = 1:NGens;
colors = {[1 0 0],[0 0 1],[0.6 0.8 0]};
h = zeros(3,1);
do_patch = 0;
figure
hold on
for i = 1:3
    if i == 1
        dist = dist1;
    end
    if i == 2
        dist = dist2;
    end
    if i == 3
        dist = dist3;
    end
    min_dist = min(dist,[],1);
    max_dist = max(dist,[],1);
    mean_dist = mean(dist,1);
    std_dist = std(dist,1);
    if do_patch
        patch('XData', [x_data, fliplr(x_data)], ...
            'YData', [mean_dist-std_dist, fliplr(mean_dist+std_dist)], ...
            'FaceColor', colors{i}, 'FaceAlpha', 0.5, 'EdgeAlpha', 0);
    else
        plot(x_data, mean_dist-std_dist, '--', ...
            'Color', colors{i}, 'LineWidth', 1.5);
        plot(x_data, mean_dist+std_dist, '--', ...
            'Color', colors{i}, 'LineWidth', 1.5);
    end
    h(i) = plot(x_data, mean_dist, 'Color', colors{i}, 'LineWidth', 2);
end
legend(h,legends);
set(gca,'FontSize',12,'FontWeight','bold');

%%%%%%%%%%%%%%%%%%%%%%%%

% Show performance with NN
perf = (data3.netPerf(:,2)+data3.netPerf(:,3))./data3.netPerf(:,4);
bestArc = find(perf == max(perf), 1, 'first');
NNPeriods = data3.sampPerf(bestArc,:);
scNNPeriods = data3.sampPerfSc(bestArc,:);

netPerf = zeros(1, 4);    % Array to store NN performance
sampPerf = zeros(1, NNSamples);
sampPerfSc = zeros(1, NNSamples);

genomeObj = MML.Gen;
genTauMin = MML.Gen.Range(1,1);
genTauMax = MML.Gen.Range(2,1);
runSimFuncHandle = @MML.runSim;
perLimMin = MML.perLim(1);
perLimMax = MML.perLim(2);

NNSamples = 500;
desPeriod = MML.perLim(1) + ...
             rand(1, NNSamples)*(MML.perLim(2)-MML.perLim(1));
parfor j = 1:NNSamples
    % Setup tau_r, tau_a, c, W and feedback gains using genome
%         seq = getRandFuncHandle(); % Get random genetic sequence
    seq = genomeObj.RandSeq(); %#ok<PFBNS> % Get random genetic sequence

    % Set random b
    if rand()>0.7
        beta = min(max(0.6+0.1*randn(),0.2),0.8);
    else
        beta = min(max(2.5+randn(),0.8),8);
    end

    % Get Tr estimates from NN
    genes = MML.Gen.GetGenes(seq, MML.sample_genes);
    in = [genes';  desPeriod(j)];

    % Normalize X
    in = bsxfun(@rdivide, bsxfun(@minus, in, ...
        MML.normParams(:,1)), MML.normParams(:,2));
    
    seq(1) = predict(Mdl,in');
    if seq(1) < genTauMin || seq(1) > genTauMax
%         warning(['Genetic sequence #', int2str(j), ...
%             ' out of bounds, using bounded tau gene'])
        % Bound tau gene
        seq(1) = min(max(seq(1), genTauMin), genTauMax);
    end

    % Run simulation
    [out, ~, ~] = runSimFuncHandle(seq, beta);    

    % Save resulting period
    if any(isnan(out.periods))
        sampPerf(j) = NaN;
    else
        sampPerf(j) = max(out.periods);
    end

    % Did period converge to the desired range?
    if sampPerf(j) < perLimMin || sampPerf(j) > perLimMax
        % Try rescaling time
        ratio = desPeriod(j)/sampPerf(j);
        seq(1) = seq(1)*ratio;
        if seq(1) < genTauMin || seq(1) > genTauMax
%             warning(['Genetic sequence #', int2str(j), ...
%                 ' out of bounds, using bounded tau gene'])
            % Bound tau gene
            seq(1) = min(max(seq(1), genTauMin), genTauMax);
        end

        % Run simulation
        [out, ~, ~] = runSimFuncHandle(seq, beta);
        % Save resulting period
        if any(isnan(out.periods))
            sampPerfSc(j) = NaN;
        else
            sampPerfSc(j) = max(out.periods);
        end
    else
        sampPerfSc(j) = sampPerf(j);
    end
end
