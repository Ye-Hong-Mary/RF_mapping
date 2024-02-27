%
% VGS_RFmapping.m
% VGS with random locations or inRF/outRF locations
% Mary Ye Hong
%

if ~exist('eye_','var'), error('This demo requires eye signal input. Please set it up or try the simulation mode.'); end

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

trial_type = TrialRecord.User.trial;

bhv_variable('TGPosition', trial_type.TGPosition);

dashboard(2, sprintf('TG (%g,%g)', trial_type.TGPosition(1), trial_type.TGPosition(2)));

% stats = TrialRecord.User.Stats;
% dashboard(3, sprintf('Left Accuracy: %g%% Right Accuracy: %g%% Total Accuracy: %g%%', 100 * stats.ByDirection.Left.Accuracy, 100 * stats.ByDirection.Right.Accuracy, 100 * stats.All.Accuracy));

% [recent_total,recent_L,recent_R] = stats.recentHistory(recent_trlnum);
% dashboard(4, sprintf('Last %d, Left Accuracy: %g%% Right Accuracy: %g%% Total Accuracy: %g%%  ', recent_trlnum, 100 * recent_L.Accuracy, 100 * recent_R.Accuracy, 100 * recent_total.Accuracy));


%% Construct graphics


fp_graphic = CircleGraphic(null_);
fp_graphic.Size = Settings.FP.Size * 2.0; % The settings denote a radius rather than diameter
fp_graphic.FaceColor = Settings.FP.Color;
fp_graphic.EdgeColor = fp_graphic.FaceColor;
fp_graphic.Position = Settings.Position.Center;

tg_graphic = CircleGraphic(null_);
tg_graphic.Size = Settings.TG.Size * 2.0;
tg_graphic.FaceColor = Settings.TG.Color;
tg_graphic.EdgeColor = tg_graphic.FaceColor;
tg_graphic.Position = trial_type.TGPosition;


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


saccade_start = NotAdapter(invis_fp_tgt);
wh_saccade_start = WaitThenHold(saccade_start);
wh_saccade_start.WaitTime = times.ResponseWindow;
wh_saccade_start.HoldTime = 0;

saccade_end = NotAdapter(tg_tgt);
wh_saccade_end = WaitThenHold(saccade_end);
wh_saccade_end.WaitTime = 0;
wh_saccade_end.HoldTime = times.MaximumSaccade;

wh_saccade = Sequential(wh_saccade_start);
wh_saccade.add(wh_saccade_end);

%% Behavior codes

bhv_code(1, 'Acquire FP', 2, 'FP hold', 3, 'TG on to FP off', 4, 'Invalid trial', 6, 'Correct response'); % Shared between task types
bhv_code(106, 'Response window', 107, 'TG hold to reward');                      % Delay task events
bhv_code(100, 'Blank screen'); % the end of a task
% bhv_code(204, 'Response prohibited', 205, 'Response window, GP on', 206, 'Response window, GP off', 207, 'TG hold to reward');    % Reaction task events

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

%% Scene 3: Focus has been maintained, targets appear
% Q: Should this be part of the reaction task?

wh3 = WaitThenHold(fp_tgt);
wh3.WaitTime = 0;
wh3.HoldTime = times.TGOnToFPOff;

ad3 = AllContinue(wh3);
ad3.add(tg_graphic);

scene3 = create_scene(ad3);

%% Scene 4: Focus has been maintained long enough, so focus point off; make a saccade

    ad4 = AllContinue(tg_tgt);

    ad4.add(wh_saccade);

    scene4 = create_scene(ad4);


%% Scene 7: Until the time has elapsed, must not touch outside the region of the target

scene7_enabled = isstruct(Settings.Timing.TGHoldToReward) || (times.TGHoldToReward > 0);

if scene7_enabled
    wh7 = WaitThenHold(NotAdapter(tg_tgt));
    wh7.WaitTime = times.TGHoldToReward; % If using a reaction-dependent timing curve, this will be recalculated
    wh7.HoldTime = 0;

    ad7 = AllContinue(tg_graphic);
    ad7.add(wh7);
    scene7 = create_scene(ad7);
end

%% Blanking: Since Monkey Logic doesn't change the screen unless directed, a small blank scene is inserted before the ITI

blank_tc = TimeCounter(null_);
blank_tc.Duration = ceil(1000.0 / MLConfig.Screen.RefreshRate); % One frame
blank = create_scene(blank_tc);

%% Logic for progressing through scenes

continue_trial = true;                 % Used to keep track of whether further scenes should be run depending on status of previous ones
response_window_start = 0;             % Used when estimating reaction time in order to apply reaction-dependent timing curves
TrialRecord.User.timeout_duration = 0; % This value will be applied when determining the length of the blank scene

if continue_trial
    dashboard(1, 'Acquiring FP');
    run_scene(scene1, 1);
    if ~wh1.Success
        onInvalidTrial(TrialRecord, 'Failure to acquire focus', 4, 4);
        continue_trial = false;
    end
end

if continue_trial
    dashboard(1, 'FP hold');
    run_scene(scene2, 2);
    if ~wh2.Success
        onInvalidTrial(TrialRecord, 'Failure to maintain focus', 3, 4);
        continue_trial = false;
    end
end

if continue_trial
    dashboard(1, 'TG on to FP off');
    run_scene(scene3, 3);
    if ~wh3.Success
        onInvalidTrial(TrialRecord, 'Failure to maintain focus when targets appear', 5, 4);
        continue_trial = false;
    end
end


    if continue_trial
        dashboard(1, 'Response window');
        response_window_start = run_scene(scene4, 106);
        
        if wh_saccade_start.Success 
            if ~wh_saccade_end.Success
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
        dashboard(1, 'TG Hold to Reward');
        run_scene(scene7, 107);
        if ~wh7.Success
            onCorrectTrial(TrialRecord, 'Success', 6);
        else
            onInvalidTrial(TrialRecord, 'Failure to maintain focus during TG hold to reward', 7, 4);
        end
        continue_trial = false;
    end


blank_tc.Duration = max(blank_tc.Duration, TrialRecord.User.timeout_duration);
run_scene(blank, TrialRecord.User.final_eventcode);
idle(ceil(1000.0 / MLConfig.Screen.RefreshRate),[],100); % One frame
trialerror(TrialRecord.User.trialerror); % The argument's value will be zero on success

if show_config_ui
    show_settings(TrialRecord, true); %#ok<UNRCH>
end

%% Routines for handling each of the trial outcomes

function onInvalidTrial(TrialRecord, msg, errorcode, eventcode)
    dashboard(1, msg);
    
    TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.InvalidTimeout);

    % TrialRecord.User.Stats.addInvalid(TrialRecord.User.trial);

    TrialRecord.User.RepeatStimulusOnTrial = TrialRecord.User.Settings.RepeatStimulusInvalid;
    TrialRecord.User.remove_trial = false;

    bhv_variable('OutcomeCode', -1);
    TrialRecord.User.final_eventcode = eventcode;
    TrialRecord.User.trialerror = errorcode;
end


function onCorrectTrial(TrialRecord, msg, eventcode)
    dashboard(1, msg);
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
