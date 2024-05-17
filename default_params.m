function params = default_params()
    params.FP = struct('Color', [1 0 0], 'Size', 0.5, 'Threshold', 1.0);
    params.TG = struct('Color', [1 1 1], 'Size', 0.5, 'Threshold', 1.0);
    
    params.RepeatStimulusInvalid = false;
    params.RewardProbability = 1.0;
    
    params.Timing = struct( ...
        'AcquireFP', 1000, ...
        'FPHold', fuzzed_uniform(900, 1100), ...
        'TGOnToFPOff', fuzzed_uniform(900, 1100), ...
        'ResponseWindow', 3000, ...
        'MaximumSaccade', 1000, ...
        'TGHoldToReward', 0, ...
        'InterTrialInterval', fuzzed_uniform(1000, 1000), ...
        'RewardDuration', fuzzed_uniform(100, 100), ...
        'InvalidTimeout', 0 ...
        );
    
    params.DefaultBlock = {};
    angles = [0,pi/4,pi/2,pi*3/4,pi,pi*5/4,pi*3/2,pi*7/4];
    eccens = [3.5,5,7,10];
    for angle_idx = 1:length(angles)
        for eccen_idx = 1:length(eccens)
            x = eccens(eccen_idx)*sin(angles(angle_idx));
            y = eccens(eccen_idx)*cos(angles(angle_idx));
            params.DefaultBlock = [params.DefaultBlock,struct('x', round(x,2), 'y', round(y,2), 'TrialCount', 10)];
        end
    end
    params.BlockOverride = 0;
    params.Block = params.DefaultBlock;
    params.NewBlock = {struct('x',3,'y',3,'TrialCount',10)};

    params.Position = struct('Center', [0 0]);
    % params.Angle = struct('Left', '135deg', 'Right', '45deg');
end
