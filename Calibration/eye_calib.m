if ~exist('eye_','var'), error('This demo requires eye signal input. Please set it up or try the simulation mode.'); end


hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');

dashboard(3,'Press ''x'' to quit');

% editable
fp_size = 0.2;
fp_color = [1,1,1];
fp_eccen = 4;
fp_threshold = 2;
fp_acq = 2000;
fp_hold = 500; % set to fixed value for now
iti_time = 1200;
invalid_timeout = 1000;
repeat_invalid = 1;
editable('fp_size','fp_threshold','fp_eccen','fp_acq','fp_hold','iti_time','invalid_timeout','repeat_invalid');
editable('-color', 'fp_color');


%%
Block = {[0,0],[-fp_eccen,0],[fp_eccen,0],[0,fp_eccen],[0,-fp_eccen]}; % center,left,right,up,down

if isfield(TrialRecord.User, 'state') && TrialRecord.User.remove_trial
    TrialRecord.User.state.Remaining = TrialRecord.User.state.Remaining - 1;    
    schedule_index = find(cellfun(@(x) isequal(x,TrialRecord.User.PreviousPosition),Block));    
    TrialRecord.User.state.TypeRemaining(schedule_index) = TrialRecord.User.state.TypeRemaining(schedule_index) - 1;        

end

if ~isfield(TrialRecord.User, 'state') || (TrialRecord.User.state.Remaining <= 0)
    TrialRecord.User.state = struct();
    TrialRecord.User.state.Remaining = 4 * size(Block,2);
    TrialRecord.User.state.TrialTypes = Block; 
    TrialRecord.User.state.TypeRemaining = repmat([4],size(Block,2),1);

    TrialRecord.User.BlockNumber = TrialRecord.User.BlockNumber + 1;
    TrialRecord.NextBlock = TrialRecord.User.BlockNumber;
    TrialRecord.User.RepeatStimulusOnTrial = false;
end

if isfield(TrialRecord.User,'RepeatStimulusOnTrial') && TrialRecord.User.RepeatStimulusOnTrial
    fp_position = TrialRecord.User.PreviousPosition;
else
    fp_position = get_trial(TrialRecord.User.state);
end

bhv_variable('FixPosition', fp_position);
eventmarker(fp_position(1) + 100); % x in deg [80-120]
eventmarker(fp_position(2) + 50); % y in deg [30-70]
dashboard(2, sprintf('Fixation at (%g,%g)', fp_position(1), fp_position(2)));
TrialRecord.User.PreviousPosition = fp_position;

%% create scene
fp_graphic = CircleGraphic(null_);
fp_graphic.Size = fp_size; % The settings denote a radius rather than diameter
fp_graphic.FaceColor = fp_color;
fp_graphic.EdgeColor = fp_graphic.FaceColor;
fp_graphic.Position = fp_position;

fp_tgt = SingleTarget(eye_);
fp_tgt.Target = fp_graphic;
fp_tgt.Threshold = fp_threshold;


set_iti(iti_time);
blank_tc = TimeCounter(null_);
blank_tc.Duration = ceil(1000.0 / MLConfig.Screen.RefreshRate); % One frame
blank = create_scene(blank_tc);

bhv_code(1, 'Acquire FP', 2, 'FP hold', 3, 'Invalid trial', 4, 'Success');
bhv_code(10,'blank scene');



%% Scene 1: Starting the trial and acquiring focus

wh1 = WaitThenHold(fp_tgt);
wh1.WaitTime = fp_acq;
wh1.HoldTime = 0;

scene1 = create_scene(wh1);

%% Scene 2: Focus has been acquired; maintain it

wh2 = WaitThenHold(fp_tgt);
wh2.WaitTime = 0;
wh2.HoldTime = fp_hold;

scene2 = create_scene(wh2);


%% Running the task
continue_trial = true;

if continue_trial
    dashboard(1, 'Acquiring FP');
    run_scene(scene1, 1);
    if ~wh1.Success
        onInvalidTrial(TrialRecord, 'Failure to acquire focus', 1, 3);
        continue_trial = false;
    end
end

if continue_trial
    dashboard(1, 'FP hold');
    run_scene(scene2, 2);
    if ~wh2.Success
        onInvalidTrial(TrialRecord, 'Failure to maintain focus', 2, 3);
    else
        onCorrectTrial(TrialRecord, 'Success', 4);
    end
    continue_trial = false;
end


blank_tc.Duration = max(blank_tc.Duration, TrialRecord.User.timeout_duration);
run_scene(blank, TrialRecord.User.final_eventcode);
idle(ceil(1000.0 / MLConfig.Screen.RefreshRate),[],10); % One frame
trialerror(TrialRecord.User.trialerror);

%% Routines for handling each of the trial outcomes

function onInvalidTrial(TrialRecord, msg, errorcode, eventcode)

dashboard(1, msg);
TrialRecord.User.timeout_duration = invalid_timeout;
TrialRecord.User.RepeatStimulusOnTrial = repeat_invalid;
TrialRecord.User.remove_trial = false;
TrialRecord.User.final_eventcode = eventcode;
TrialRecord.User.trialerror = errorcode;

end

function onCorrectTrial(TrialRecord, msg, eventcode)

dashboard(1, msg);
goodmonkey(1000, 'NonBlocking', 2);
TrialRecord.User.RepeatStimulusOnTrial = false;
TrialRecord.User.remove_trial = true;
TrialRecord.User.final_eventcode = eventcode;
TrialRecord.User.trialerror = 0; % Denotes success in MonkeyLogic
TrialRecord.User.timeout_duration = 0;

end
