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
    params.angles = [0,45,90,135,180,215,270,315];
    params.eccens = [3.5,5,7,10];
    for angle_idx = 1:length(angles)
        for eccen_idx = 1:length(eccens)
            x = eccens(eccen_idx)*sin(angles(angle_idx)*pi/180);
            y = eccens(eccen_idx)*cos(angles(angle_idx)*pi/180);
            params.DefaultBlock = [params.DefaultBlock,struct('x', round(x,2), 'y', round(y,2), 'TrialCount', 10)];
        end
    end
    params.handmap = 1;
    params.BlockOverride = 0;
    params.Block = params.DefaultBlock;
    params.NewBlock = {struct('x',3,'y',3,'TrialCount',10)};

    params.Position = struct('Center', [0 0]);
    % params.Angle = struct('Left', '135deg', 'Right', '45deg');
end
