if ~exist('eye_','var'), error('This demo requires eye signal input. Please set it up or try the simulation mode.'); end
if ~exist('mouse_','var'), error('This demo requires the mouse input. Please enable it in the main menu or try the simulation mode.'); end

hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');

dashboard(1,'Fixate on center point',[0 1 0]);
dashboard(2,'Press ''x'' to quit');

nstim = 10;  % we will draw 10 stimuli
sz = ones(nstim,2) + 4 * repmat(rand(nstim,1),1,2);  % 1-5 degrees
color = [163 73 164; 63 72 204; 0 162 232; 34 177 76; 255 242 0; 255 127 39; 237 28 36];  % 7 preset colors
c = color(ceil(7*rand(nstim,1)),:);  % 10-by-3 matrix
scrsize = Screen.SubjectScreenFullSize / Screen.PixelsPerDegree;  % screen size in degrees
position = repmat(2.5,nstim,2) + repmat(scrsize-5,nstim,1).*rand(nstim,2) - repmat(scrsize/2,nstim,1);  % [0 0] is the screen center

% editable
fp_size = 0.2;
fp_color = [1,1,1];
fp_position = [0,0]; % not editable for now
fp_threshold = 2;
fp_acq = 2000;
fp_hold = 500; % set to fixed value for now
iti_time = 1200;
invalid_timeout = 1000;
editable('fp_size','fp_threshold','fp_acq','fp_hold','iti_time','invalid_timeout');
editable('-color', 'fp_color');


%% create scene

fp_graphic = CircleGraphic(null_);
fp_graphic.Size = fp_size; % The settings denote a radius rather than diameter
fp_graphic.FaceColor = fp_color;
fp_graphic.EdgeColor = fp_graphic.FaceColor;
fp_graphic.Position = fp_position;

fp_tgt = SingleTarget(eye_);
fp_tgt.Target = fp_graphic;
fp_tgt.Threshold = fp_threshold;

img = ImageGraphic(null_);
img.List = {'test.png',[position(2,:)],[],sz(2,:)*100,360 * rand};

set_iti(iti_time);
blank_tc = TimeCounter(null_);
blank_tc.Duration = ceil(1000.0 / MLConfig.Screen.RefreshRate); % One frame
blank = create_scene(blank_tc);

bhv_code(1, 'Acquire FP', 2, 'FP hold', 3, 'Invalid trial', 4, 'Success');
%% Scene 1: Starting the trial and acquiring focus

wh1 = WaitThenHold(fp_tgt);
wh1.WaitTime = fp_acq;
wh1.HoldTime = 0;

ad1 = AllContinue(wh1);
ad1.add(img);

scene1 = create_scene(ad1);

%% Scene 2: Focus has been acquired; maintain it

wh2 = WaitThenHold(fp_tgt);
wh2.WaitTime = 0;
wh2.HoldTime = fp_hold;

ad2 = AllContinue(wh2);
ad2.add(img);

scene2 = create_scene(ad2);


%% Running the task
continue_trial = true;   

if continue_trial
    dashboard(3, 'Acquiring FP');
    run_scene(scene1, 1);
    if ~wh1.Success
        dashboard(3, 'Failure to acquire focus');
        TrialRecord.User.trialerror = 1;
        TrialRecord.User.final_eventcode = 3;
        TrialRecord.User.timeout_duration = invalid_timeout;
        continue_trial = false;
    end
end

if continue_trial
    dashboard(3, 'FP hold');
    run_scene(scene2, 2);
    if ~wh2.Success
        dashboard(3, 'Failure to maintain focus');
        TrialRecord.User.trialerror = 2;
        TrialRecord.User.final_eventcode = 3;
        TrialRecord.User.timeout_duration = invalid_timeout;
    else
        dashboard(3, 'Success');
        TrialRecord.User.trialerror = 0;
        TrialRecord.User.final_eventcode = 4;
        TrialRecord.User.timeout_duration = 0;
        goodmonkey(1000, 'NonBlocking', 2);
    end
    continue_trial = false;
end


blank_tc.Duration = max(blank_tc.Duration, TrialRecord.User.timeout_duration);
run_scene(blank, TrialRecord.User.final_eventcode);
idle(ceil(1000.0 / MLConfig.Screen.RefreshRate)); % One frame
trialerror(TrialRecord.User.trialerror);
