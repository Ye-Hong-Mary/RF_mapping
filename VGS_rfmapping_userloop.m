%
% rfmapping_userloop.m
%
% Mary Ye Hong
% 

function [C,timingfile,userdefined_trialholder] = VGS_rfmapping_userloop(MLConfig,TrialRecord)

C = [];
timingfile = 'VGS_RFmapping.m';
userdefined_trialholder = '';

persistent RunTime;
if isempty(RunTime)
    if isfile('vgs_settings.mat')
        TrialRecord.User.Settings = matfile('vgs_settings.mat').Settings;
    else
        TrialRecord.User.Settings = default_params();
        Settings = TrialRecord.User.Settings;
        save('vgs_settings.mat', 'Settings');
    end

    show_settings(TrialRecord);

    rng('shuffle');
    TrialRecord.User.BlockNumber = 0;
    % TrialRecord.User.Stats = SessionStats();
    RunTime = get_function_handle(embed_timingfile(MLConfig,timingfile,userdefined_trialholder));
    return;
end


if isfield(TrialRecord.User, 'state') && TrialRecord.User.remove_trial
    TrialRecord.User.state = remove_trial(TrialRecord.User.state, TrialRecord.User.trial);
end

if ~isfield(TrialRecord.User, 'state') || (TrialRecord.User.state.Remaining <= 0)
    TrialRecord.User.state = create_schedule(TrialRecord.User.Settings.Block);
    if TrialRecord.User.state.Remaining <= 0
        error('Blocks must have at least one trial');
    end

    next_scheduled_block(TrialRecord);
end

if TrialRecord.User.RepeatStimulusOnTrial
    timingfile = RunTime;
    return;
end

TrialRecord.User.trial = get_trial(TrialRecord.User.state);
timingfile = RunTime;
