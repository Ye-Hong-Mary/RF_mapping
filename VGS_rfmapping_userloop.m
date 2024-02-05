%
% rfmapping_userloop.m
%
% Mary Ye Hong
% 
%

function [C,timingfile,userdefined_trialholder] = VGS_rfmapping_userloop(MLConfig,TrialRecord)

C = [];
timingfile = 'VGS_RFmapping.m';
userdefined_trialholder = '';

persistent RunTime;
if isempty(RunTime)
    if isfile('protocol_settings.mat')
        TrialRecord.User.Settings = matfile('protocol_settings.mat').Settings;
    else
        TrialRecord.User.Settings = default_params();
        Settings = TrialRecord.User.Settings;
        save('protocol_settings.mat', 'Settings');
    end

    show_settings(TrialRecord);

    rng('shuffle');
    TrialRecord.User.BlockNumber = 0;
    % TrialRecord.User.Stats = SessionStats();
    RunTime = get_function_handle(embed_timingfile(MLConfig,timingfile,userdefined_trialholder));
    return;
end

% gen_str = sprintf('gen(darkly_gen, %g, %g)', TrialRecord.User.Settings.Position.Center(1), TrialRecord.User.Settings.Position.Center(2));
% stim = {gen_str};

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
    % C = mltaskobject(stim,MLConfig,TrialRecord);
    timingfile = RunTime;
    return;
end

TrialRecord.User.trial = get_trial(TrialRecord.User.state);

% gp_settings = TrialRecord.User.Settings.GP;

% TrialRecord.User.width = gp_settings.Diameter;
% TrialRecord.User.height = TrialRecord.User.width;
% TrialRecord.User.pattern_diameter = compose("%.0f", TrialRecord.User.width);
% TrialRecord.User.dotsize = compose("%.0fpx", gp_settings.DotSize);
% TrialRecord.User.dotcount = compose("%.0f", gp_settings.DotCount);
% TrialRecord.User.coherence = compose("%.3f", TrialRecord.User.trial.Coherence);
% TrialRecord.User.spacing = compose("%.0fpx", gp_settings.Spacing);
% TrialRecord.User.red = compose("%.3f", gp_settings.Color(1));
% TrialRecord.User.green = compose("%.3f", gp_settings.Color(2));
% TrialRecord.User.blue = compose("%.3f", gp_settings.Color(3));
% if TrialRecord.User.trial.Left
%     TrialRecord.User.angle = TrialRecord.User.Settings.Angle.Left;
% else
%     TrialRecord.User.angle = TrialRecord.User.Settings.Angle.Right;
% end

% Note: If timing were calculated here, then it wouldn't have to use the maximum timing values

% timing_settings = TrialRecord.User.Settings.Timing;
% if ~isstruct(timing_settings.GPOnToGPOff)
%     total_ms = timing_settings.GPOnToGPOff;
% elseif timing_settings.GPOnToGPOff.Exponential
%     total_ms = timing_settings.GPOnToGPOff.Mean * timing_settings.GPOnToGPOff.Maxscale;
% else
%     total_ms = timing_settings.GPOnToGPOff.Max;
% end
% TrialRecord.User.glass_frames = compose("%d", ceil(0.001 * total_ms * MLConfig.Screen.RefreshRate));

% C = mltaskobject(stim,MLConfig,TrialRecord);
timingfile = RunTime;
