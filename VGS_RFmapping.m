%
% VGS_RFmapping.m
% VGS with random locations or inRF/outRF locations
% Mary Ye Hong
%

if ~exist('eye_','var'), error('This demo requires eye signal input. Please set it up or try the simulation mode.'); end
if ~exist('mouse_','var'), error('This demo requires the mouse input. Please enable it in the main menu or try the simulation mode.'); end
mouse_.showcursor(false);  % hide the mouse cursor from the subject screen

% Hotkey X: The Monkey Logic menu
hotkey('x', 'idle(0); escape_screen(); assignin(''caller'',''continue_'',false);');

% Hotkey S: The protocol settings screen, then the Monkey Logic menu
hotkey('s', 'idle(0); escape_screen(); assignin(''caller'',''continue_'',false); show_config_ui = true;');

show_config_ui = false;

dashboard(1, '');

Settings = TrialRecord.User.Settings;

%% Calculate trial timing

if isfield(TrialRecord.User,'RepeatStimulusOnTrial') && TrialRecord.User.RepeatStimulusOnTrial 
    times = TrialRecord.User.PreviousTrialTimes;
else
    times = generate_times(Settings);% generate times should be changed
    TrialRecord.User.PreviousTrialTimes = times;
end
set_iti(times.InterTrialInterval);

%% Record Trial parameters for later analysis
if Settings.handmap
    if isfield(TrialRecord.User,'tgPos') 
        tgPos = TrialRecord.User.tgPos;
    else
        tgPos = [4,4];
    end
else
    trial_type = TrialRecord.User.trial;

    bhv_variable('TGPosition', trial_type.TGPosition - Settings.Position.Center);

    dashboard(1, sprintf('TG Position = [%.1f %.1f]',trial_type.TGPosition));%TG (%g,%g)', trial_type.TGPosition(1), trial_type.TGPosition(2)));
end

%% Construct graphics


fp_graphic = CircleGraphic(null_);
fp_graphic.Size = Settings.FP.Size * 2.0; % The settings denote a radius rather than diameter
fp_graphic.FaceColor = Settings.FP.Color;
fp_graphic.EdgeColor = fp_graphic.FaceColor;
fp_graphic.Position = Settings.Position.Center;

if Settings.handmap
    tg_graphic = Circle_RF_Mapper(mouse_);
    tg_graphic.Position = tgPos;
    tg_graphic.InfoDisplay = true;
else
    tg_graphic = CircleGraphic(null_);
    tg_graphic.Position = trial_type.TGPosition;
end
tg_graphic.Size = Settings.TG.Size * 2.0;
tg_graphic.FaceColor = Settings.TG.Color;
tg_graphic.EdgeColor = tg_graphic.FaceColor;


%% Eye tracker targets

fp_tgt = SingleTarget(eye_);
fp_tgt.Target = fp_graphic;
fp_tgt.Threshold = Settings.FP.Threshold;

invis_fp_tgt = SingleTarget(eye_);
invis_fp_tgt.Target = Settings.Position.Center;
invis_fp_tgt.Threshold = fp_tgt.Threshold;

tg_tgt = SingleTarget(eye_);
tg_tgt.Target = tg_graphic;
tg_tgt.Threshold = Settings.TG.Threshold;

invis_tg_tgt = SingleTarget(eye_);
invis_tg_tgt.Target = trial_type.TGPosition;
invis_tg_tgt.Threshold = Settings.TG.Threshold;

saccade_start = NotAdapter(invis_fp_tgt);
wh_saccade_start = WaitThenHold(saccade_start);
wh_saccade_start.WaitTime = times.ResponseWindow;
wh_saccade_start.HoldTime = 0;

saccade_end_vgs = NotAdapter(tg_tgt);
wh_saccade_end_vgs = WaitThenHold(saccade_end_vgs);
wh_saccade_end_vgs.WaitTime = 0;
wh_saccade_end_vgs.HoldTime = times.MaximumSaccade;
wh_saccade_vgs = Sequential(wh_saccade_start);
wh_saccade_vgs.add(wh_saccade_end_vgs);

saccade_end_mgs = NotAdapter(invis_tg_tgt);
wh_saccade_end_mgs = WaitThenHold(saccade_end_mgs);
wh_saccade_end_mgs.WaitTime = 0;
wh_saccade_end_mgs.HoldTime = times.MaximumSaccade;
wh_saccade_mgs = Sequential(wh_saccade_start);
wh_saccade_mgs.add(wh_saccade_end_mgs);

%% Behavior codes

bhv_code(1, 'Acquire FP', 2, 'FP hold', 3, 'TG on to FP off', 4, 'Invalid trial', 6, 'Correct response'); % Shared between task types
bhv_code(106, 'Response window', 107, 'TG hold to reward');                      % VGS task events
bhv_code(108, 'TG off to FP Off', 109, 'FP off Response Window', 110, 'TG hold to reward'); % MGS task events
bhv_code(15, 'VGS Task', 16, 'MGS Task');
bhv_code(100, 'Blank screen'); % the end of a task
% bhv_code(204, 'Response prohibited', 205, 'Response window, GP on', 206, 'Response window, GP off', 207, 'TG hold to reward');    % Reaction task events

%% Scene 0: mark the task
if Settings.TaskIsVGS
    eventmarker(15);
else
    eventmarker(16);
end

%% Scene 1: Starting the trial and acquiring focus

wh1 = WaitThenHold(fp_tgt);
wh1.WaitTime = times.AcquireFP;
wh1.HoldTime = 0;

scene1 = create_scene(wh1);

%% Scene 2: Focus has been acquired; maintain it

wh2 = WaitThenHold(fp_tgt);
wh2.WaitTime = 0;
wh2.HoldTime = times.FPHold;

scene2 = create_scene(wh2);

%% Scene 3: Focus has been maintained, target appear
wh3 = WaitThenHold(fp_tgt);
wh3.WaitTime = 0;
if Settings.TaskIsVGS
    wh3.HoldTime = times.TGOnToFPOff;
else
    wh3.HoldTime = times.TGOnToTGOff;
end

ad3 = AllContinue(wh3);
ad3.add(tg_graphic);

scene3 = create_scene(ad3);

%% Scene 4-5 Differ between VGS and MGS
% Memory guided saccade(MGS)
% 4M: TG off, focus point remains, focus must remain on FP
% 5M: FP off, make a saccade within certain time
%
% Visually guided saccade(VGS)
% 4V: FP off; make a saccade

if Settings.TaskIsVGS
    
    % Scence 4V: Focus has been maintained, FP off, make a saccade within certain time
    ad4v = AllContinue(tg_tgt);
    ad4v.add(wh_saccade_vgs);
    scene4v = create_scene(ad4v);

    % Scene 7v: Until the time has elapsed, must not touch outside the region of the target
    scene7_enabled = isstruct(Settings.Timing.TGHoldToReward) || (times.TGHoldToReward > 0);

    if scene7_enabled
        wh7v = WaitThenHold(NotAdapter(tg_tgt));
        wh7v.WaitTime = times.TGHoldToReward; % If using a reaction-dependent timing curve, this will be recalculated
        wh7v.HoldTime = 0;

        ad7v = AllContinue(tg_graphic);
        ad7v.add(wh7v);
        scene7v = create_scene(ad7v);
    end

else

    % Scene 4M: Focus has been maintained, target off
    wh4m = WaitThenHold(fp_tgt);
    wh4m.WaitTime = 0;
    wh4m.HoldTime = times.TGOffToFPOff;
    scene4m = create_scene(wh4m);

    % Scene 5M: Focus has been maintained, FP off, make a saccade within certain time
    ad5m = AllContinue(invis_tg_tgt);
    ad5m.add(wh_saccade_mgs);
    scene5m = create_scene(ad5m);

    % Scene 7M: Until the time has elapsed, must not touch outside the region of the target
    scene7_enabled = isstruct(Settings.Timing.TGHoldToReward) || (times.TGHoldToReward > 0);

    if scene7_enabled
        wh7m = WaitThenHold(NotAdapter(invis_tg_tgt));
        wh7m.WaitTime = times.TGHoldToReward; % If using a reaction-dependent timing curve, this will be recalculated
        wh7m.HoldTime = 0;       

        scene7m = create_scene(wh7m);
    end
end

%

%% Blanking: Since Monkey Logic doesn't change the screen unless directed, a small blank scene is inserted before the ITI

blank_tc = TimeCounter(null_);
blank_tc.Duration = ceil(1000.0 / MLConfig.Screen.RefreshRate); % One frame
blank = create_scene(blank_tc);

%% Logic for progressing through scenes

continue_trial = true;                 % Used to keep track of whether further scenes should be run depending on status of previous ones
response_window_start = 0;             % Used when estimating reaction time in order to apply reaction-dependent timing curves
TrialRecord.User.timeout_duration = 0; % This value will be applied when determining the length of the blank scene

if continue_trial
    dashboard(2, 'Acquiring FP');
    run_scene(scene1, 1);
    if ~wh1.Success
        onInvalidTrial(TrialRecord, 'Failure to acquire focus', 4, 4);
        continue_trial = false;
    end
end

if continue_trial
    dashboard(2, 'FP hold');
    run_scene(scene2, 2);
    if ~wh2.Success
        onInvalidTrial(TrialRecord, 'Failure to maintain focus', 3, 4);
        continue_trial = false;
    end
end

if continue_trial
    dashboard(2, 'TG on');
    run_scene(scene3, 3);
    if ~wh3.Success
        onInvalidTrial(TrialRecord, 'Failure to maintain focus when targets appear', 5, 4);
        continue_trial = false;
    end
end

if Settings.TaskIsVGS

    if continue_trial
        dashboard(2, 'FP off, Response window');
        tg_tgt.Target = tg_graphic;
        response_window_start = run_scene(scene4v, 106);
        % keyboard
        if wh_saccade_start.Success 
            if ~wh_saccade_end_vgs.Success
                rt = wh_saccade_start.AcquiredTime - response_window_start;
                if scene7_enabled
                    wh7.WaitTime = fuzz(Settings.Timing.TGHoldToReward);%, trialtime - response_window_start, Settings.Timing.ResponseWindow);
                else
                    onCorrectTrial(TrialRecord, 'Success', 6);
                    continue_trial = false;
                end
            else 
                onInvalidTrial(TrialRecord, 'Maximum saccade time elapsed without selection', 2, 4);
                continue_trial = false;
            end
        else
            onInvalidTrial(TrialRecord, 'Failure to saccade', 1, 4);
            continue_trial = false;
        end
    end

    if continue_trial
        dashboard(2, 'TG Hold to Reward');
        % tg_tgt.Target = tg_graphic;
        run_scene(scene7v, 107);
        if ~wh7v.Success
            onCorrectTrial(TrialRecord, 'Success', 6);
        else
            onInvalidTrial(TrialRecord, 'Failure to maintain focus during TG hold to reward', 7, 4);
        end
        continue_trial = false;
    end
    
else

    if continue_trial
        dashboard(2, 'TG off');
        run_scene(scene4m, 108);
        if ~wh4m.Success
            onInvalidTrial(TrialRecord, 'Failure to maintain focus when targets disappear', 8, 4);
            continue_trial = false;
        end
    end


    if continue_trial
        dashboard(2, 'FP Off, Response window');
        invis_tg_tgt.Target = trial_type.TGPosition;
        response_window_start = run_scene(scene5m, 109);
        if wh_saccade_start.Success 
            if ~wh_saccade_end_mgs.Success
                rt = wh_saccade_start.AcquiredTime - response_window_start;
                if scene7_enabled
                    wh7.WaitTime = fuzz(Settings.Timing.TGHoldToReward);%, trialtime - response_window_start, Settings.Timing.ResponseWindow);
                else
                    onCorrectTrial(TrialRecord, 'Success', 6);
                    continue_trial = false;
                end
            else 
                onInvalidTrial(TrialRecord, 'Maximum saccade time elapsed without selection', 2, 4);
                continue_trial = false;
            end
        else
            onInvalidTrial(TrialRecord, 'Failure to saccade', 1, 4);
            continue_trial = false;
        end
    end

    if continue_trial
        dashboard(2, 'TG Hold to Reward');
        run_scene(scene7m, 110);
        if ~wh7m.Success
            onCorrectTrial(TrialRecord, 'Success', 6);
        else
            onInvalidTrial(TrialRecord, 'Failure to maintain focus during TG hold to reward', 7, 4);
        end
        continue_trial = false;
    end
end

blank_tc.Duration = max(blank_tc.Duration, TrialRecord.User.timeout_duration);
run_scene(blank, TrialRecord.User.final_eventcode);
idle(ceil(1000.0 / MLConfig.Screen.RefreshRate),[],100); % One frame
trialerror(TrialRecord.User.trialerror); % The argument's value will be zero on success
if Settings.handmap
    TrialRecord.User.tgPos = tg_graphic.Position;
    bhv_variable('TGPosition', tg_graphic.Position);
end

if show_config_ui
    show_settings(TrialRecord, true); %#ok<UNRCH>
end

%% Routines for handling each of the trial outcomes

function onInvalidTrial(TrialRecord, msg, errorcode, eventcode,Settings, tg_graphic)
    dashboard(2, msg);
    
    TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.InvalidTimeout);

    % TrialRecord.User.Stats.addInvalid(TrialRecord.User.trial);

    TrialRecord.User.RepeatStimulusOnTrial = TrialRecord.User.Settings.RepeatStimulusInvalid;
    TrialRecord.User.remove_trial = false;

    bhv_variable('OutcomeCode', -1);
    TrialRecord.User.final_eventcode = eventcode;
    TrialRecord.User.trialerror = errorcode;
end


function onCorrectTrial(TrialRecord, msg, eventcode,Settings, tg_graphic)
    dashboard(2, msg);

    if times.RewardOnSuccess
        goodmonkey(times.RewardDuration, 'NonBlocking', 2);
    end

    % TrialRecord.User.Stats.addCorrect(TrialRecord.User.trial);

    TrialRecord.User.RepeatStimulusOnTrial = false;
    TrialRecord.User.remove_trial = true;

    bhv_variable('OutcomeCode', 1);
    TrialRecord.User.final_eventcode = eventcode;
    TrialRecord.User.trialerror = 0; % Denotes success in MonkeyLogic
    TrialRecord.User.timeout_duration = 0;
end
