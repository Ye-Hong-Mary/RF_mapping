%
% Draws a random trial from the remaining set containing:
%   TGPosition
%   ScheduleIndex (i.e. which of the original cell array did it belong to?)
%   UserData (Optional)
% Note that this doesn't remove it from the schedule;
% on a successful trial, call remove_trial.
%

function next_trial = get_trial(schedule_state)
    % This case is the stop condition: no further trials remain, and there are no remaining trial types
    if schedule_state.Remaining == 0 || isempty(schedule_state.TrialTypes)
        next_trial = [];
        return;
    end

    % Of all trials in all types, draw one at random
    selected_index = randi(schedule_state.Remaining);

    % This ensures that the next trial type is chosen
    % with a probability proportional to remaining trials in each trial type
    for i = 1:size(schedule_state.TrialTypes, 1)
        if selected_index <= schedule_state.TrialTypes{i}.Remaining
            trial_type = schedule_state.TrialTypes{i};
            selected_index = i;
            break;
        else
            selected_index = selected_index - schedule_state.TrialTypes{i}.Remaining;
        end
    end

    if isempty(trial_type)
        % This case can only occur if the schedule_state is modified externally
        error("Scheduler could not select a trial type for the next trial");
    end

    % Construct the instance of the selected trial type and populate it
    next_trial = struct();
    next_trial.TGPosition = trial_type.TGPosition;
    next_trial.ScheduleIndex = selected_index;
    if isfield(trial_type, 'UserData')
        next_trial.UserData = trial_type.UserData;
    end

end
