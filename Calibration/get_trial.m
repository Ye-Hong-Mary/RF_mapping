%
% Draws a random fp position from the remaining set 

% Note that this doesn't remove it from the schedule;
% on a successful trial, call remove_trial.
%

function fp_position = get_trial(schedule_state)
    % This case is the stop condition: no further trials remain, and there are no remaining trial types
    if schedule_state.Remaining == 0 || isempty(schedule_state.TrialTypes)
        fp_position = [];
        return;
    end

    % Of all trials in all types, draw one at random
    selected_index = randi(schedule_state.Remaining);
    % keyboard
    % This ensures that the next trial type is chosen
    % with a probability proportional to remaining trials in each trial type
    for i = 1:size(schedule_state.TrialTypes, 2)
        if selected_index <= schedule_state.TypeRemaining(i)
            fp_position = schedule_state.TrialTypes{i};
            selected_index = i;
            break;
        else
            selected_index = selected_index - schedule_state.TypeRemaining(i);
        end
    end

    if isempty(fp_position)
        % This case can only occur if the schedule_state is modified externally
        error("Scheduler could not select a trial type for the next trial");
    end


end
