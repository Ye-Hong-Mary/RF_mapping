function times = generate_times(Settings)
    names = {'AcquireFP', 'FPHold', 'TGOnToFPOff', 'ResponseWindow', 'MaximumSaccade', 'TGHoldToReward', 'InterTrialInterval', 'RewardDuration', 'InvalidTimeout'};
    for i = 1:length(names)
        times.(names{i}) = fuzz(Settings.Timing.(names{i}));
    end
    % if ~Settings.TaskIsDelay
    %     times.GPOnToGPOff = max(times.GPOnToGPOff, times.MinimumReactionTime); % Minimum reaction time can't exceed GP time
    %     times.ResponseWindow = max(times.ResponseWindow, times.GPOnToGPOff);   % Response window must be no smaller than GP time
    % end
    times.RewardOnSuccess = (rand(1) < Settings.RewardProbability); % Records whether this instance contains a reward
end
