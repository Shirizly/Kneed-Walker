function [y, periods, signals, pos_work, neg_work] = ...
        processResults(obj, X, T)
%PROCESSRESULTS Calculates the output signals, CPG period, positive and
%negative work using the simulation results

    y = max(0, X(:, 1:obj.nNeurons));
    % Initialize output variables
    periods = zeros(obj.nNeurons/2,1);
    signals = obj.Sim.Con.OutM*y';
    pos_work = zeros(obj.nNeurons/2,1);
    neg_work = zeros(obj.nNeurons/2,1);

    for i = 1:obj.nNeurons/2
        signal = signals(i,:);

        % Calculate signal period
        sig2proc = 0.3; % start calculating period after 30% of the signal
        % to skip transient
        sig_idx = floor(sig2proc*length(signal)):length(signal);
        ac = xcorr(signal(sig_idx),signal(sig_idx),'coeff');
        [~,locs]=findpeaks(ac, 'MinPeakheight',0.3, ...
                    'MinPeakProminence', 0.05);
        
        if isempty(locs)
            periods(i) = NaN;
            continue
        end
        
        if length(locs) == 1
            if std(signal(sig_idx)) < 1e-3
                periods(i) = NaN;
                continue
            end
            
            % Get peaks straight from signal
            norm_signal = (signal(sig_idx)-min(signal(sig_idx))) / ...
                (max(signal(sig_idx)) - min(signal(sig_idx)));
            [~,locs]=findpeaks(norm_signal, 'MinPeakheight',0.5, ...
                'MinPeakProminence', 0.05);
            if length(locs) < 3
                periods(i) = NaN;
            else
                periods(i) = mean(diff(locs))*mean(diff(T));
            end
        else
            % Find linear fit
            loc_half = locs(1:floor(length(locs)/2));
            k = loc_half'\ac(loc_half)';
            diffs = abs(ac(loc_half)-k*loc_half);
            outliers = sum(diffs>mean(diffs)+3*std(diffs) | diffs > 0.2);
            if outliers == 0 || length(loc_half) < 3
                % Use normal approach
                periods(i) = mean(diff(locs))*mean(diff(T));
            else
                % Get good peaks
                good_peak_ids = ...
                    1 + find(ac(locs(2:end-1)) > ac(locs(1:end-2)) & ...
                    ac(locs(2:end-1)) > ac(locs(3:end))); % Local peak
                good_peaks = locs(good_peak_ids);
                periods(i) = mean(diff(good_peaks))*mean(diff(T));
            end
        end

        % Calculate positive and negative work
        pos_signal = max(signal,0);
        neg_signal = min(signal,0);
        pos_work(i) = trapz(T,pos_signal);
        neg_work(i) = trapz(T,neg_signal);
    end
end

