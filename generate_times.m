function times = generate_times(Settings)
    names = {'AcquireFP', 'FPHold', 'TGOnToFPOff', 'ResponseWindow', 'MaximumSaccade', 'TGHoldToReward', 'InterTrialInterval', 'RewardDuration', 'InvalidTimeout'};
    for i = 1:length(names)
        times.(names{i}) = fuzz(Settings.Timing.(names{i}));
    end

    times.RewardOnSuccess = (rand(1) < Settings.RewardProbability); % Records whether this instance contains a reward
end
