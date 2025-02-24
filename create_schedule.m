%
% schedule.m
% Pass a cell array of structs containing
%   LeftBias
%   Coherence
%   TrialCount
%   UserData (Optional)
% And an initialized schedule_state will come back
% Note that you should initialize the random number generator _before_ calling this
%

function schedule_state = create_schedule(trial_types)
    schedule_state = struct();
    schedule_state.TrialTypes = {}; % Records the remaining counts (total and left-aligned) and coherence
    schedule_state.Remaining = 0;   % The total of all remaining trials across all types

    for i = 1:length(trial_types)
        cfg_item = trial_types{i};

        trial_type = struct();
        trial_type.ScheduleIndex = i;
        trial_type.Coherence = cfg_item.Coherence;
        trial_type.Remaining = cfg_item.TrialCount;
        if isfield(cfg_item, 'UserData')
            trial_type.UserData = cfg_item.UserData;
        end

        % Left bias is not directly recorded in the state; instead, the
        % count of left/total trials are computed with any fractional
        % trials being randomly assigned using a probability that gives
        % repeating the trial-type an expected value of LeftBias for the
        % proportion of left trials
        L = cfg_item.LeftBias * cfg_item.TrialCount;
        frac = mod(L, 1);
        if frac > 0
            if rand(1) < frac
                L = ceil(L);
            else
                L = floor(L);
            end
        end
        trial_type.RemainingLeft = L;
        schedule_state.TrialTypes = [schedule_state.TrialTypes; trial_type];

        schedule_state.Remaining = schedule_state.Remaining + trial_type.Remaining;
    end
end
