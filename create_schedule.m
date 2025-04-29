%
% schedule.m
% Pass a cell array of structs containing
%   x
%   y
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
        trial_type.TGPosition = [cfg_item.x, cfg_item.y];
        trial_type.Remaining = cfg_item.TrialCount;
        if isfield(cfg_item, 'UserData')
            trial_type.UserData = cfg_item.UserData;
        end

        schedule_state.TrialTypes = [schedule_state.TrialTypes; trial_type];

        schedule_state.Remaining = schedule_state.Remaining + trial_type.Remaining;
    end
end
