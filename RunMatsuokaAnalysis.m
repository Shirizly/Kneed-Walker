%% Initialize machine learning object for Matsuoka analysis
MML = MatsuokaML();
MML.perLim = [0.68 0.78];
MML.perLimOut = MML.perLim + [-0.08 0.08]; % Desired period range
MML.tStep = 0.01; % 0.01
MML.tEnd = 15; % 15

% % Set constant beta
% MML.Sim.Con.beta = 7;

nPlotSamples = 0; % 10;

% Turn off findpeaks warning
warning('off','signal:findpeaks:largeMinPeakHeight');

%% Phase 1 - Run lots of Matsuoka simulations with different parameters
filename1 = 'MatsRandomRes.mat';
nSamples = 250000;
MML.runRandomSims(nSamples, filename1);

%% Phase 2 - Re-run simulations that converged outside the desired range,
% this time with scaled temporal parameters
filename2 = 'MatsScaledRes.mat';
data = load(filename1);
reDo_ids = zeros(1, data.nSims);
reDo_ids(~isnan(data.periods)) = 1;
reDo_ids(data.periods >= MML.perLimOut(1) & ...
    data.periods <= MML.perLimOut(2)) = 0;
% reDo_ids(data.id_conv) = 1;
% reDo_ids(data.id_per) = 0;
inputData = data.results(logical(reDo_ids));
inputPeriods = data.periods(logical(reDo_ids));
MML.runScaledSims(inputData, inputPeriods, filename2);

%% Phase 2.1 - Check damping condition
data = load(filename2);
results = data.results;
converged = ~isnan(data.periods);
passed_cond1 = zeros(length(results),1);
tp1 = passed_cond1; fp1 = tp1; tn1 = fp1; fn1 = tp1;
for i = 1:length(results)
    cr = results(i);
%     disp(['(',num2str(cr.Tr,5),' - ',num2str(cr.Ta,5),')^2 = ',...
%         num2str((cr.Tr-cr.Ta)^2,5)]);
    if (cr.Tr-cr.Ta)^2 >= 4*cr.Tr*cr.Ta*cr.b
        passed_cond1(i) = 1;
%         disp('              >=');
    else
%         disp('              <');
    end
%     disp(['4*',num2str(cr.Tr,5),'*',num2str(cr.Ta,5),'*',num2str(cr.b,5),' = ',...
%         num2str(4*cr.Tr*cr.Ta*cr.b,5)]);
%     disp(' ');
    
    if passed_cond1(i)
        if converged(i)
            tp1(i) = 1;
        else
            fp1(i) = 1;
        end
    else
        if converged(i)
            fn1(i) = 1;
        else
            tn1(i) = 1;
        end
    end
end
% Show results
disp(['Converged: ', int2str(sum(converged)), ...
    ' out of ', int2str(numel(converged))]);
disp(['Passed condition 1: ', int2str(sum(passed_cond1)), ...
    ' out of ', int2str(numel(passed_cond1))]);
disp(['True positives: ', int2str(sum(tp1))]);
disp(['True negatives: ', int2str(sum(tn1))]);
disp(['False positives: ', int2str(sum(fp1))]);
disp(['False negatives: ', int2str(sum(fn1))]);

% Show some cases
n_cases = nPlotSamples;
% True positives
MML.plotSamples(results, tp1, n_cases, 'Cond. 1 true positive sample #');
% True negatives
MML.plotSamples(results, tn1, n_cases, 'Cond. 1 true negative sample #');
% False positives
MML.plotSamples(results, fp1, n_cases, 'Cond. 1 false positive sample #');
% False negatives
MML.plotSamples(results, fn1, n_cases, 'Cond. 1 false negative sample #');

%% Phase 2.2 - Check tonic input condition
passed_cond2 = zeros(length(results),length(results(1).c));
tp2 = 0*converged; fp2 = tp2; tn2 = fp2; fn2 = tp2;
for i = 1:length(results)
    cr = results(i);
    passed_cond2(i, :) = (cr.c > cr.W*cr.c/(1+cr.b))';
        
    if all(passed_cond2(i, :))
        if converged(i)
            tp2(i) = 1;
        else
            fp2(i) = 1;
        end
    else
        if converged(i)
            fn2(i) = 1;
        else
            tn2(i) = 1;
        end
    end
end
% Show results
disp(['Converged: ', int2str(sum(converged)), ...
    ' out of ', int2str(numel(converged))]);
disp(['Passed condition 2: ', int2str(sum(all(passed_cond2'))), ...
    ' out of ', int2str(numel(converged))]);
disp(['True positives: ', int2str(sum(tp2))]);
disp(['True negatives: ', int2str(sum(tn2))]);
disp(['False positives: ', int2str(sum(fp2))]);
disp(['False negatives: ', int2str(sum(fn2))]);

% Show some cases
n_cases = nPlotSamples;
% True positives
MML.plotSamples(results, tp2, n_cases, 'Cond. 2 true positive sample #');
% True negatives
MML.plotSamples(results, tn2, n_cases, 'Cond. 2 true negative sample #');
% False positives
MML.plotSamples(results, fp2, n_cases, 'Cond. 2 false positive sample #');
% False negatives
MML.plotSamples(results, fn2, n_cases, 'Cond. 2 false negative sample #');

%% Phase pre-3 - Train NNs using different features and targets

% Combinations for genome with tau, beta, amp and weights.
sample_genes = {{'amp','weights'};
                {'beta','amp','weights'};
                {'weights'};
                {'beta','weights'};
                {'\tau_r','weights'};
                {'\tau_r','amp','weights'}};
target_genes = {{'\tau_r'};
                {'\tau_r','beta'};
                {'beta'}};
combos = [1,1; % {'amp','weights'}          -> {'\tau_r'}           0.52    0.18
          1,2; % {'amp','weights'}          -> {'\tau_r','beta'}    0.81    0.14 ++
          1,3; % {'amp','weights'}          -> {'beta'}             0.83    0.10 +gr
          2,1; % {'beta','amp','weights'}   -> {'\tau_r'}           0.52    0.18
          3,1; % {'weights'}                -> {'\tau_r'}           0.54    0.20
          3,2; % {'weights'}                -> {'\tau_r','beta'}    0.78    0.12 +++
          3,3; % {'weights'}                -> {'beta'}             0.80    0.06 +
          4,1; % {'beta','weights'}         -> {'\tau_r'}           0.50    0.20 
          5,3; % {'\tau_r','weights'}       -> {'beta'}             0.85    0.09 +
          6,3];% {'\tau_r','amp','weights'} -> {'beta'}             0.85    0.09 +
      
% Combinations for genome with tau, tau_ratio, beta, amp and weights.
% sample_genes = {{'amp','weights'};
%                 {'beta','amp','weights'};
%                 {'weights'};
%                 {'beta','weights'};
%                 {'\tau_r','weights'};
%                 {'amp','weights','\tau_ratio'};
%                 {'beta','amp','weights','\tau_ratio'};
%                 {'weights','\tau_ratio'};
%                 {'beta','weights','\tau_ratio'};
%                 {'\tau_r','weights','\tau_ratio'}};
% target_genes = {{'\tau_r'};
%                 {'\tau_r','beta'};
%                 {'beta'};
%                 {'\tau_r','\tau_ratio'};
%                 {'\tau_r','beta','\tau_ratio'};
%                 {'beta','\tau_ratio'}};
% combos = [1,1; % {'amp','weights'}          -> {'\tau_r'}           0.50    0.19
%           1,2; % {'amp','weights'}          -> {'\tau_r','beta'}    0.80    0.14 ++
%           1,3; % {'amp','weights'}          -> {'beta'}             0.81    0.08 +
%           1,4;
%           1,5;
%           1,6; % **** 6
%           2,1; % {'beta','amp','weights'}   -> {'\tau_r'}           0.49    0.16
%           2,4;
%           3,1; % {'weights'}                -> {'\tau_r'}           0.52    0.18
%           3,2; % **** 10 {'weights'}                -> {'\tau_r','beta'}    0.81    0.18 +++
%           3,3; % **** 11 {'weights'}                -> {'beta'}             0.79    0.09 +
%           3,4;
%           3,5; % **** 13
%           3,6; % **** 14
%           4,1; % {'beta','weights'}         -> {'\tau_r'}           0.52    0.19 
%           4,4;
%           5,3; % **** 17 {'\tau_r','weights'}      -> {'beta'}             0.83    0.08 +
%           5,6;
%           6,1; % {'amp','weights'}          -> {'\tau_r'}           0.50    0.19
%           6,2; % **** 20 {'amp','weights'}          -> {'\tau_r','beta'}    0.80    0.14 ++
%           6,3; % **** 21{'amp','weights'}          -> {'beta'}             0.81    0.08 +
%           7,1; % {'beta','amp','weights'}   -> {'\tau_r'}           0.49    0.16
%           8,1; % {'weights'}                -> {'\tau_r'}           0.52    0.18
%           8,2; % {'weights'}                -> {'\tau_r','beta'}    0.81    0.18 +++
%           8,3; % **** 25 {'weights'}                -> {'beta'}             0.79    0.09 +
%           9,1; % {'beta','weights'}         -> {'\tau_r'}           0.52    0.19 
%           10,3]; % **** 27 {'\tau_r','weights'}      -> {'beta'}             0.83    0.08 +
      
% Combinations for genome with tau, amp and weights (no beta)
% sample_genes = {{'amp','weights'};
%                 {'weights'}};
% target_genes = {{'\tau_r'};
%                 {'\tau_r','amp'};
%                 {'amp'}};
% combos = [1,1; % {'amp','weights'}          -> {'\tau_r'}           0.50    0.19
%           2,1; % {'weights'}                -> {'\tau_r'}           0.52    0.18
%           2,2; % {'weights'}                -> {'\tau_r','amp'}    0.81    0.18 +++
%           2,3]; % {'weights'}                -> {'amp'}             0.79    0.09 +

maxN = min(nSamples, 250000);
NNSamples = 500;
inFilenames = {filename1, filename2};

nCombos = size(combos,1);
net = cell(nCombos, 1);           % Cell array to store NNs
tr = cell(nCombos, 1);            % Cell array to store NNs training res
netPerf = zeros(nCombos, 4);      % Array to store NN performance
% Array to store NN per sample performance
desPeriod = zeros(nCombos, NNSamples);
sampPerf = zeros(nCombos, NNSamples);
sampPerfSc = zeros(nCombos, NNSamples); % re-scaled results
    
for i = 1:nCombos
    MML.sample_genes = sample_genes{combos(i,1)};
    MML.target_genes = target_genes{combos(i,2)};
    
    [samples, targets, normParams] = MML.prepareNNData(inFilenames, maxN);
    MML.normParams = normParams;
    
    [net{i}, tr{i}, netPerf(i,:), desPeriod(i,:), ...
            sampPerf(i,:), sampPerfSc(i,:)] = ...
            MML.trainNN(samples, targets, [30, 30], NNSamples);
        
%     [net1, tr1, netPerf1, desPeriod1, sampPerf1, sampPerfSc1] = ...
%             MML.trainNN(samples, targets, 20, NNSamples);
end

save('MatsNNTests', 'sample_genes', 'target_genes', 'combos', ...
     'nCombos', 'net', 'tr', 'netPerf', 'desPeriod', ...
     'sampPerf', 'sampPerfSc');
 
 % Display results
 for i = 1:nCombos
     disp([num2cell(netPerf(i,:)), ...
         'Feat:', cellstr(sample_genes{combos(i,1)}), ...
         'Target:', cellstr(target_genes{combos(i,2)})])
 end
 
%% Phase 3 - Train NNs using the data from phases 1 and 2

% Pick best features
score = netPerf(:,2) + netPerf(:,3);
best_comb = find(score == max(score));
if length(best_comb) > 1
    best_scores = netPerf(best_comb,2);
    id = find(best_scores == max(best_scores), 1, 'first');
    best_best = best_comb(id);
    best_comb = best_best;
end
disp('Best features/target combo:');
disp(['Features', sample_genes{combos(best_comb,1)}]);
disp(['Targets', target_genes{combos(best_comb,2)}]);
disp(netPerf(best_comb,:));

MML.sample_genes = sample_genes{combos(best_comb,1)};
MML.target_genes = target_genes{combos(best_comb,2)};
    
filename3 = 'MatsNNData.mat';
filename4 = 'MatsNNRes1.mat';
filename5 = 'MatsNNRes2.mat';
filename6 = 'MatsNNRes3.mat';
if exist(filename3, 'file') ~= 2
    maxN = min(nSamples, 250000);
    NNSamples = 500;
    inFilenames = {filename1, filename2};
    [samples, targets, normParams] = MML.prepareNNData(inFilenames, maxN);
    save(filename3, 'maxN', 'NNSamples', ...
                    'samples', 'targets', 'normParams');
else
    load(filename3);
end
MML.normParams = normParams;

% Train networks with different architectures and all samples
if exist(filename4, 'file') ~= 2
    architectures = {5, 20, 50, [25, 25], [15, 25, 10]};
    nArch = numel(architectures);
    
    net = cell(nArch, 1);           % Cell array to store NNs
    tr = cell(nArch, 1);            % Cell array to store NNs training res
    netPerf = zeros(nArch, 4);      % Array to store NN performance
    % Array to store NN per sample performance
    desPeriod = zeros(nArch, NNSamples);
    sampPerf = zeros(nArch, NNSamples);
    sampPerfSc = zeros(nArch, NNSamples); % re-scaled results
    
    for i = 1:nArch
        [net{i}, tr{i}, netPerf(i,:), desPeriod(i,:), ...
            sampPerf(i,:), sampPerfSc(i,:)] = ...
            MML.trainNN(samples, targets, architectures{i}, NNSamples);
    end
    save(filename4, 'architectures', 'nArch', 'net', 'tr', ...
                    'netPerf', 'desPeriod', 'sampPerf', 'sampPerfSc');
else
    load(filename4);
end

% Train network with specific architecture and different number of samples
if exist(filename5, 'file') ~= 2
    maxN = size(samples, 2);
    architecture = architectures{2};
    nSampleSizes = 10;
    sampleSizes = floor(logspace(1,3,nSampleSizes)*maxN/1000);
    
    net = cell(nSampleSizes, 1);       % Cell array to store NNs
    tr = cell(nArch, 1);            % Cell array to store NNs training res
    netPerf = zeros(nSampleSizes, 4);  % Array to store NN performance
    % Array to store NN per sample performance
    desPeriod = zeros(nSampleSizes, NNSamples);
    sampPerf = zeros(nSampleSizes, NNSamples);
    sampPerfSc = zeros(nArch, NNSamples); % re-scaled results
    
    for i = 1:nSampleSizes
        ids = randsample(maxN, sampleSizes(i));
        [net{i}, tr{i}, netPerf(i,:), desPeriod(i,:), ...
            sampPerf(i,:), sampPerfSc(i,:)] = ...
            MML.trainNN(samples(:, ids), targets(:, ids), ...
                        architecture, NNSamples);
    end
    save(filename5, 'nSampleSizes', 'sampleSizes', 'architecture',...
                    'net', 'tr', 'netPerf', 'desPeriod', ...
                    'sampPerf', 'sampPerfSc');
else
    load(filename5);
end

% Train network with specific architecture and different number of samples
if exist(filename6, 'file') ~= 2
    maxN = size(samples, 2);
    architecture = architectures{end};
    nSampleSizes = 10;
    sampleSizes = floor(logspace(1,3,nSampleSizes)*maxN/1000);
    
    net = cell(nSampleSizes, 1);       % Cell array to store NNs
    tr = cell(nArch, 1);            % Cell array to store NNs training res
    netPerf = zeros(nSampleSizes, 4);  % Array to store NN performance
    % Array to store NN per sample performance
    desPeriod = zeros(nSampleSizes, NNSamples);
    sampPerf = zeros(nSampleSizes, NNSamples);
    sampPerfSc = zeros(nArch, NNSamples); % re-scaled results
    
    for i = 1:nSampleSizes
        ids = randsample(maxN, sampleSizes(i));
        [net{i}, tr{i}, netPerf(i,:), desPeriod(i,:), ...
            sampPerf(i,:), sampPerfSc(i,:)] = ...
            MML.trainNN(samples(:, ids), targets(:, ids), ...
                        architecture, NNSamples);
    end
    save(filename6, 'nSampleSizes', 'sampleSizes', 'architecture',...
                    'net', 'tr', 'netPerf', 'desPeriod', ...
                    'sampPerf', 'sampPerfSc');
else
    load(filename6);
end

%% Phase 4 - Train SVMs using the data from phases 1 and 2

%% Phase 5 - ???

%% Phase 6 - Profit! (Plot results)
data1 = load(filename1); % Random results
data2 = load(filename2); % Scaled results
data3 = load(filename4); % NN results - diff. architectures
data4 = load(filename5); % NN results - diff. number of training samples
data5 = load(filename6); % NN results - diff. number of training samples
load(filename3);

MML.plotNNConv(data1, data2, data3, 1);
MML.plotNNConv(data1, data2, data4, 2);
MML.plotNNConv(data1, data2, data5, 2);

nBins = 50;
nDists = 1+size(data3.sampPerf,1);
rows = max(floor(sqrt(nDists)),1);
cols = ceil(nDists/rows);

% figure
% % Plot distribution of random samples
% subplot(rows, cols, 1);
% hist(max([data1.results(data1.id_conv).periods]),nBins)
% for i = 2:nDists
%     % Plot distribution of NN samples
%     subplot(rows, cols, i)
%     hist(data3.sampPerf(i-1,:),nBins)
% end

figure
% Plot distribution of random samples
subplot(rows, cols, 1);
% hist(max([data1.results(data1.id_conv).periods]),nBins)
[counts,centers]=hist(max([data1.results(data1.id_conv).periods]),nBins);
% b1=bar(centers,counts/trapz(centers,counts));
b1=bar(centers,counts/max(counts));
hold on
[counts,centers]=hist(max([data2.results(data2.id_conv).periods]),nBins);
% b2=bar(centers,counts/trapz(centers,counts));
b2=bar(centers,counts/max(counts));
set(get(b1,'Children'),'Facecolor',[0 0 1],'EdgeColor','k','FaceAlpha',0.5);
set(get(b2,'Children'),'Facecolor',[1 0 0],'EdgeColor','k','FaceAlpha',0.5);
% h = findobj(gca,'Type','patch');
% set(h(1),'Facecolor',[1 0 0],'EdgeColor','k','FaceAlpha',0.5);
% set(h(2),'Facecolor',[0 0 1],'EdgeColor','k','FaceAlpha',0.5);

for i = 2:nDists
    % Plot distribution of NN samples
    subplot(rows, cols, i)
    hist(data3.sampPerf(i-1,:),nBins)
end
