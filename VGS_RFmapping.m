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
% if trial_type.Left
%     trial_direction = 'Left';
%     signed_coherence = -signed_coherence;
% else
%     trial_direction = 'Right';
% end
% recent_trlnum = 20;

bhv_variable('TG Position', trial_type.TGPosition);

dashboard(2, sprintf('TG (%g%,%g%)', trial_type.TGPosition(1), trial_type.TGPosition(2)));

% stats = TrialRecord.User.Stats;
% dashboard(3, sprintf('Left Accuracy: %g%% Right Accuracy: %g%% Total Accuracy: %g%%', 100 * stats.ByDirection.Left.Accuracy, 100 * stats.ByDirection.Right.Accuracy, 100 * stats.All.Accuracy));

% [recent_total,recent_L,recent_R] = stats.recentHistory(recent_trlnum);
% dashboard(4, sprintf('Last %d, Left Accuracy: %g%% Right Accuracy: %g%% Total Accuracy: %g%%  ', recent_trlnum, 100 * recent_L.Accuracy, 100 * recent_R.Accuracy, 100 * recent_total.Accuracy));


% Block_params = [TrialRecord.User.Settings.Block{:}];
% Coherence_all = unique([Block_params.Coherence]);
% Coh_cmd = [];
% for coh = 1:length(Coherence_all)
%     Coh_cmd = [Coh_cmd, sprintf(' Coh %g%%: %g%% ',Coherence_all(coh) * 100, 100 * stats.byCoherence(Coherence_all(coh)).Accuracy)];
% end
% dashboard(5, ['Accuracy by coherence, ',Coh_cmd]);

% dashboard(6, sprintf('Valid Count: %d Total Trials: %d Valid Rate: %g%% Last %g Valid: %g%%', stats.All.Valid, stats.All.Total, 100 * stats.All.ValidRate, recent_trlnum, 100*stats.recentHistory(recent_trlnum).ValidRate));


%% Construct graphics

% glass_pattern = SingleTarget(null_);
% glass_pattern.Target = 1; % Returned by userloop at this index

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

% if Settings.DIS.Enabled
%     dis_graphic = CircleGraphic(null_);
%     dis_graphic.Size = Settings.DIS.Size * 2.0;
%     dis_graphic.FaceColor = Settings.DIS.Color;
%     dis_graphic.EdgeColor = dis_graphic.FaceColor;
% end
% if Settings.Position.Flipped
%     if TrialRecord.User.trial.Left
%         tg_graphic.Position = Settings.Position.Right;
%         dis_graphic.Position = Settings.Position.Left;
%     else
%         tg_graphic.Position = Settings.Position.Left;
%         dis_graphic.Position = Settings.Position.Right;
%     end
% else
%     if TrialRecord.User.trial.Left
%         tg_graphic.Position = Settings.Position.Left;
%         dis_graphic.Position = Settings.Position.Right;
%     else
%         tg_graphic.Position = Settings.Position.Right;
%         dis_graphic.Position = Settings.Position.Left;
%     end
% end

% endpt_graphics = GraphicContainer(null_);
% endpt_graphics.add(tg_graphic);
% if Settings.DIS.Enabled
%     endpt_graphics.add(dis_graphic);
% end

% allpt_graphics = GraphicContainer(endpt_graphics);
% allpt_graphics.add(fp_graphic);

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

% if Settings.DIS.Enabled
%     dis_tgt = SingleTarget(eye_);
%     dis_tgt.Target = dis_graphic;
%     dis_tgt.Threshold = Settings.DIS.Threshold;
% end

saccade_start = NotAdapter(invis_fp_tgt);
wh_saccade_start = WaitThenHold(saccade_start);
wh_saccade_start.WaitTime = times.ResponseWindow;
wh_saccade_start.HoldTime = 0;

% saccade_end = NotAdapter(tg_tgt);
wh_saccade_end = WaitThenHold(tg_tgt);
wh_saccade_end.WaitTime = times.MaximumSaccade;
wh_saccade_end.HoldTime = 0;

wh_saccade = Sequential(wh_saccade_start);
wh_saccade.add(wh_saccade_end);

%% Behavior codes

bhv_code(1, 'Acquire FP', 2, 'FP hold', 3, 'TG on to FP off', 4, 'Invalid trial', 6, 'Correct response'); % Shared between task types
bhv_code(106, 'Response window', 107, 'TG hold to reward');                      % Delay task events
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

%% Scenes 4
%


% if Settings.TaskIsDelay
    %% Scene 4D: Focus has been maintained, glass pattern starts

    % wh4d = WaitThenHold(fp_tgt);
    % wh4d.WaitTime = 0;
    % wh4d.HoldTime = times.GPOnToGPOff;

    % ad4d = AllContinue(wh4d);
    % ad4d.add(glass_pattern);
    % ad4d.add(tg_graphics);

    % scene4d = create_scene(ad4d);

    % %% Scene 5D: Focus has been maintained, glass pattern off (but focus point remains)

    % wh5d = WaitThenHold(fp_tgt);
    % wh5d.WaitTime = 0;
    % wh5d.HoldTime = times.GPOffToFPOff;

    % ad5d = AllContinue(wh5d);
    % ad5d.add(endpt_graphics);

    % scene5d = create_scene(ad5d);

    %% Scene 6D: Focus has been maintained long enough, so focus point off; make a saccade

    % wh4_tg = WaitThenHold(tg_tgt);
    % wh4_tg.WaitTime = times.ResponseWindow;
    % wh4_tg.HoldTime = 0;
    ad4 = AllContinue(tg_tgt);

    % if Settings.DIS.Enabled
    %     wh6d_dis = WaitThenHold(dis_tgt);
    %     wh6d_dis.WaitTime = wh6d_tg.WaitTime;
    %     wh6d_dis.HoldTime = 0;
    %     ad6d.add(wh6d_dis);
    % end

    ad4.add(wh_saccade);

    scene4 = create_scene(ad4);
% else
%     %% Scene 4R: Glass pattern appears and focus point disappears, but it is too soon to saccade

%     wh4r = WaitThenHold(invis_fp_tgt);
%     wh4r.WaitTime = 0;
%     wh4r.HoldTime = times.MinimumReactionTime;

%     ad4r = AllContinue(wh4r);
%     ad4r.add(glass_pattern);
%     ad4r.add(endpt_graphics);

%     scene4r = create_scene(ad4r);

%     %% Scene 5R: Focus point is still gone, and glass pattern is still present, but saccading to the target is allowed

%     wh5r_tg = WaitThenHold(tg_tgt);
%     wh5r_tg.WaitTime = times.GPOnToGPOff - times.MinimumReactionTime;
%     wh5r_tg.HoldTime = 0;
%     ad5r = AllContinue(wh5r_tg);

%     if Settings.DIS.Enabled
%         wh5r_dis = WaitThenHold(dis_tgt);
%         wh5r_dis.WaitTime = wh5r_tg.WaitTime;
%         wh5r_dis.HoldTime = 0;
%         ad5r.add(wh5r_dis);
%     end

%     ad5r.add(glass_pattern);
%     ad5r.add(wh_saccade);

%     scene5r = create_scene(ad5r);

%     %% Scene 6R: Glass pattern disappears, and it is still possible to saccade to the target

%     wh6r_tg = WaitThenHold(tg_tgt);
%     wh6r_tg.WaitTime = times.ResponseWindow - times.GPOnToGPOff;
%     wh6r_tg.HoldTime = 0;
%     ad6r = AllContinue(wh6r_tg);
%     ad6r.add(wh_saccade);

%     if Settings.DIS.Enabled
%         wh6r_dis = WaitThenHold(dis_tgt);
%         wh6r_dis.WaitTime = wh6r_tg.WaitTime;
%         wh6r_dis.HoldTime = 0;
%         ad6r.add(wh6r_dis);
%     end

%     scene6r = create_scene(ad6r);
% end

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

% if Settings.TaskIsDelay
    % if continue_trial
    %     dashboard(1, 'GP on to GP off');
    %     run_scene(scene4d, 104);
    %     if ~wh4d.Success
    %         onInvalidTrial(TrialRecord, 'Failure to maintain focus when glass pattern appears', 5, 4);
    %         continue_trial = false;
    %     end
    % end

    % if continue_trial
    %     dashboard(1, 'GP off to FP off');
    %     run_scene(scene5d, 105);
    %     if ~wh5d.Success
    %         onInvalidTrial(TrialRecord, 'Failure to maintain focus when glass pattern disappears', 5, 4);
    %         continue_trial = false;
    %     end
    % end

    if continue_trial
        dashboard(1, 'Response window');
        response_window_start = run_scene(scene4, 106);
        
        if wh_saccade_start.Success 
            if wh_saccade_end.Success
            % rt = wh4_tg.AcquiredTime - response_window_start;
                if scene7_enabled
                    wh7.WaitTime = fuzz(Settings.Timing.TGHoldToReward);%, trialtime - response_window_start, Settings.Timing.ResponseWindow);
                else
                    onCorrectTrial(TrialRecord, 'Success', 6);
                    continue_trial = false;
                end
            else 
                onInvalidTrial(TrialRecord, 'Maximum saccade time elapsed without selection', 2, 4);
                continue_trial = false;
        % elseif Settings.DIS.Enabled && wh6d_dis.Success
        %     rt = wh6d_dis.AcquiredTime - response_window_start;
        %     onIncorrectTrial(TrialRecord, 'Selected distractor instead of target', 6, 5);
        %     continue_trial = false;
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
% else % Reaction tasks
%     continue_to_scene7 = false; % Used to route from 5R or 6R to 7 when delay to reward is enabled

%     if continue_trial
%         dashboard(1, 'Minimum reaction time');
%         response_window_start = run_scene(scene4r, 204);
%         if ~wh4r.Success
%             onInvalidTrial(TrialRecord, 'Failure to wait the minimum reaction time', 5, 4);
%             continue_trial = false;
%         end
%     end

%     if continue_trial
%         dashboard(1, 'Response window (GP on)');
%         run_scene(scene5r, 205);
%         if wh5r_tg.Success
%             rt = wh5r_tg.AcquiredTime - response_window_start;
%             if scene7_enabled
%                 wh7.WaitTime = fuzz(Settings.Timing.TGHoldToReward, trialtime - response_window_start, Settings.Timing.ResponseWindow);
%                 continue_to_scene7 = true;
%             else
%                 onCorrectTrial(TrialRecord, 'Success', 6);
%                 continue_trial = false;
%             end
%         elseif wh_saccade_end.Success
%             onInvalidTrial(TrialRecord, 'Maximum saccade time elapsed without selection', 2, 4);
%             continue_trial = false;
%         elseif Settings.DIS.Enabled && wh5r_dis.Success
%             rt = wh5r_dis.AcquiredTime - response_window_start;
%             onIncorrectTrial(TrialRecord, 'Selected distractor instead of target', 6, 5);
%             continue_trial = false;
%         end
%     end

%     if continue_trial && ~continue_to_scene7 % This logic skips the scene if the TG is already acquired
%         if wh_saccade_start.Success
%             % This adjusts the saccade timing so that if a saccade starts in
%             % Scene 5, they don't get extra saccade time when the scene
%             % boundary occurs
%             wh_saccade_end.HoldTime = wh_saccade_end.HoldTime - (trialtime - wh_saccade_end.AcquiredTime);
%             wh_saccade = wh_saccade_end;
%         end

%         dashboard(1, 'Response window (GP off)');
%         run_scene(scene6r, 206);
%         if wh6r_tg.Success
%             rt = wh6r_tg.AcquiredTime - response_window_start;
%             if scene7_enabled
%                 wh7.WaitTime = fuzz(Settings.Timing.TGHoldToReward, trialtime - response_window_start, Settings.Timing.ResponseWindow);
%             else
%                 onCorrectTrial(TrialRecord, 'Success', 6);
%                 continue_trial = false;
%             end
%         elseif wh_saccade_end.Success
%             onInvalidTrial(TrialRecord, 'Maximum saccade time elapsed without selection', 2, 4);
%             continue_trial = false;
%         elseif Settings.DIS.Enabled && wh6r_dis.Success
%             rt = wh6r_dis.AcquiredTime - response_window_start;
%             onIncorrectTrial(TrialRecord, 'Selected distractor instead of target', 6, 5);
%             continue_trial = false;
%         else
%             onInvalidTrial(TrialRecord, 'Failure to saccade to target or distractor', 1, 4);
%             continue_trial = false;
%         end
%     end

%     if continue_trial
%         dashboard(1, 'TG Hold to Reward');
%         run_scene(scene7, 207);
%         if ~wh7.Success
%             onCorrectTrial(TrialRecord, 'Success', 6);
%         else
%             onInvalidTrial(TrialRecord, 'Failure to maintain focus during TG hold to reward', 7, 4);
%         end
%         continue_trial = false;
%     end
% end

blank_tc.Duration = max(blank_tc.Duration, TrialRecord.User.timeout_duration);
run_scene(blank, TrialRecord.User.final_eventcode);
idle(ceil(1000.0 / MLConfig.Screen.RefreshRate)); % One frame
trialerror(TrialRecord.User.trialerror); % The argument's value will be zero on success

if show_config_ui
    show_settings(TrialRecord, true); %#ok<UNRCH>
end

%% Routines for handling each of the trial outcomes

function onInvalidTrial(TrialRecord, msg, errorcode, eventcode)
    dashboard(1, msg);

    % if TrialRecord.User.Settings.TimeoutInvalid
        % if response_window_start > 0
        %     TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.InvalidTimeout, trialtime - response_window_start, TrialRecord.User.Settings.Timing.ResponseWindow);
        % else
            TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.InvalidTimeout);
        % end
    % end

    % TrialRecord.User.Stats.addInvalid(TrialRecord.User.trial);

    TrialRecord.User.RepeatStimulusOnTrial = TrialRecord.User.Settings.RepeatStimulusInvalid;
    TrialRecord.User.remove_trial = false;

    bhv_variable('OutcomeCode', -1);
    TrialRecord.User.final_eventcode = eventcode;
    TrialRecord.User.trialerror = errorcode;
end

% function onIncorrectTrial(TrialRecord, msg, errorcode, eventcode)
%     dashboard(1, msg);

%     % if TrialRecord.User.Settings.TimeoutIncorrect
%         if response_window_start > 0
%             TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.IncorrectTimeout, trialtime - response_window_start, TrialRecord.User.Settings.Timing.ResponseWindow);
%         else
%             TrialRecord.User.timeout_duration = fuzz(TrialRecord.User.Settings.Timing.IncorrectTimeout);
%         end
%     % end

%     TrialRecord.User.Stats.addIncorrect(TrialRecord.User.trial);

%     TrialRecord.User.RepeatStimulusOnTrial = TrialRecord.User.Settings.RepeatStimulusIncorrect;
%     TrialRecord.User.remove_trial = ~TrialRecord.User.RepeatStimulusOnTrial;

%     bhv_variable('OutcomeCode', 0);
%     TrialRecord.User.final_eventcode = eventcode;
%     TrialRecord.User.trialerror = errorcode;
% end

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
