%
% Removes a trial of the specified type from the schedule.
% This respects the ScheduleIndex and Left fields,
% so that the correct proportion of left/right are drawn.
%

function schedule_state = remove_trial(schedule_state, trial)
    schedule_state.Remaining = schedule_state.Remaining - 1;
    
    schedule_index = trial.ScheduleIndex;    
    schedule_state.TrialTypes{schedule_index}.Remaining = schedule_state.TrialTypes{schedule_index}.Remaining - 1;        
    % if trial.Left
    %     schedule_state.TrialTypes{schedule_index}.RemainingLeft = schedule_state.TrialTypes{schedule_index}.RemainingLeft - 1;
    % end
end
