function MainUI = settings_ui(Settings)
% If importing settings from an earlier version, these variables may not be initialized yet.

if isfield(Settings, 'RepeatStimulusIncorrect')
    rmfield(Settings, 'RepeatStimulusIncorrect');
end

if ~isfield(Settings, 'BlockOverride')
    Settings.BlockOverride = 0;
end

if ~isfield(Settings,'NewBlock')
    Settings.NewBlock = {struct('x', 3,'y', 3,'TrialCount', 10)};
end
if ~isfield(Settings,'handmap')
    Settings.handmap = 1;
end

if ~isfield(Settings,'angles')
    Settings.angles = [0 45 90 135 180 215 270 315];
end
if ~isfield(Settings,'eccens')
    Settings.eccens = [3.5 5 7 10];
end


% For convenience, some things will be grouped / scaled differently in the UI than in the Settings struct
Settings.Reward.Duration = Settings.Timing.RewardDuration;
Settings.Timing = rmfield(Settings.Timing, 'RewardDuration');
Settings.Reward.Probability = Settings.RewardProbability;
Settings = rmfield(Settings, 'RewardProbability');


MainUI = uifigure('Name', 'Protocol settings', 'Visible', false, 'WindowStyle', 'alwaysontop');
MainUI.Position = [MainUI.Position(1) - 100, MainUI.Position(2) - 100, MainUI.Position(3) + 200, MainUI.Position(4) + 200]; % Just a little bigger than the defaults

main_container = uigridlayout(MainUI, [2, 1]);
main_container.ColumnWidth = {'1x'};
main_container.RowHeight = {'1x', 'fit'};

main_cg = ControlGroup.column(main_container, ...
    {'FP', @visualTargetControl, 'Focus Point (FP)', Settings.FP}, ...
    {'TG', @visualTargetControl, 'Target (TG)', Settings.TG}, ...
    {'Position', @positionControl, 'Position', Settings.Position}, ...
    {'', @header, 'Task Timing'}, ...
    {'', @taskTimeControls, Settings}, ...
    {'Reward', @rewardControl, 'Rewards', Settings.Reward}, ...
    {'', @header, 'Repeat Stimulus'}, ...
    {'RepeatStimulus', @uidropdown, 'Items', {'Never', 'Invalid Trials'}, 'Tag', 'RepeatStimulus'},...
    {'', @header, 'Block Design'}, ...
    {'', @scheduleControl,Settings});

grid = main_cg.Grid;
grid.Padding = [10, 10, 10, 10];
grid.Scrollable = true;


repeat_dd = main_cg.Controls.RepeatStimulus;

if Settings.RepeatStimulusInvalid
    repeat_dd.Value = 'Invalid Trials';
else
    repeat_dd.Value = 'Never';
end
% end

uibutton(main_container, 'Text', 'Apply Settings', 'Tag', 'ApplySettings', 'ButtonPushedFcn', @onDone);
MainUI.Visible = true;

    function grid = buildColumn(parent, varargin)
        if mod(numel(varargin), 2)
            error('Wrong number of arguments to buildColumn; must be in function handle, argument array pairs');
        end

        N = numel(varargin) / 2;
        grouped = cell(1, N);
        for i = 1:N
            args = varargin(2 * i);
            grouped{i} = [{'' varargin{2 * i - 1}} args{:}];
        end

        cg = ControlGroup.column(parent, grouped{:});
        grid = cg.Grid;
    end

% Deprecated
    function grid = labeled(parent, label_text, cons, varargin)
        grid = uigridlayout(parent, [1, 2], ...
            'Padding', [0, 0, 0, 0], ...
            'RowHeight', {'fit'}, ...
            'ColumnWidth', {'fit', 'fit'} ...
            );
        ginsert(grid, 1, 1, @uilabel, 'Text', label_text);
        ctl = ginsert(grid, 1, 2, cons, varargin{:});
        grid.UserData.Control = ctl;
    end

    function ctl = header(parent, header_text)
        ctl = uilabel(parent, 'Text', header_text, 'FontWeight', 'bold');
    end

    function ctl = numberControl(parent, label_text, init_value, varargin)
        ctl = labeled(parent, label_text, @uieditfield, 'numeric', 'Value', init_value, varargin{:});
    end

    function cg = visualTargetControl(parent, title, cfg)
        cg = ControlGroup.fittedGrid(parent, [2 7]);
        cg.Grid.ColumnWidth{7} = '1x';

        cg.addControl('', 1, [1 6], @header, title);
        cg.addToRow(2, 1, ...
            'Color', {'Color', @colorButton, cfg.Color}, ...
            'Radius', {'Size', @uieditfield, 'numeric', 'Value', cfg.Size, 'Limits', [0 inf], 'ValueDisplayFormat', '%g°'}, ...
            'Threshold', {'Threshold', @uieditfield, 'numeric', 'Value', cfg.Threshold, 'Limits', [0 inf], 'ValueDisplayFormat', '%g°'});
    end

    function cg = positionControl(parent, title, cfg)
        cg = ControlGroup.fittedGrid(parent, [2 7]);
        cg.Grid.ColumnWidth{7} = '1x';

        cg.addControl('', 1, [1 6], @header, title);
        cg.addToRow(2, 1, ...
            'Center x', {'Centerx', @uieditfield, 'numeric', 'Value', cfg.Center(1), 'Limits', [-inf inf], 'ValueDisplayFormat', '%g°'},...
            'Center y', {'Centery', @uieditfield, 'numeric', 'Value', cfg.Center(2), 'Limits', [-inf inf], 'ValueDisplayFormat', '%g°'});
    end

    function cg = rewardControl(parent, title, cfg)
        cg = ControlGroup.fittedGrid(parent, [3 4]);
        cg.Grid.ColumnWidth{4} = '1x';
        cg.addControl('', 1, [1 3], @header, title);
        cg.addToRow(2, 1, 'Probability', {'Probability', @percentageControl, cfg.Probability});
        cg.addToRow(3, [1 3], {'Duration', @timeControl, 'Duration', 'RewardDuration', cfg.Duration, true});
    end


    function setTimeStruct(ctl)
        parent = ctl.Parent.Parent;
        parent.UserData.Time = ctl.Value;
    end

    function setTimeField(ctl, field_name)
        parent = ctl.Parent.Parent.Parent;
        parent.UserData.Time.(field_name) = ctl.Value;
    end

    function ctl = fixedTimeControl(parent)
        ctl = ginsert(parent, 1, 3, @numberControl, '', parent.UserData.Time, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeStruct(src));
    end

    function grid = uniformTimeControl(parent)
        grid = uigridlayout(parent, [1, 2]);
        grid.ColumnWidth = {'fit', 'fit'};
        grid.Padding = [0, 0, 0, 0];
        cfg = parent.UserData.Time;
        ginsert(grid, 1, 1, @numberControl, 'Min', cfg.Min, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Min'));
        ginsert(grid, 1, 2, @numberControl, 'Max', cfg.Max, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Max'));
    end

    function grid = exponentialTimeControl(parent)
        grid = uigridlayout(parent, [1, 3]);
        grid.ColumnWidth = {'fit', 'fit'};
        grid.Padding = [0, 0, 0, 0];
        cfg = parent.UserData.Time;
        ginsert(grid, 1, 1, @numberControl, 'Mean', cfg.Mean, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Mean'));
        ginsert(grid, 1, 2, @numberControl, 'Minscale', cfg.Minscale,'Limits', [0 1], 'ValueDisplayFormat', '%g', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Minscale'));
        ginsert(grid, 1, 3, @numberControl, 'Maxscale', cfg.Maxscale,'Limits', [1 inf], 'ValueDisplayFormat', '%g', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Maxscale'));
    end


    function switchTimeControl(ctl, ~)
        parent = ctl.Parent;
        old_time = parent.UserData.Time;
        old_fuzz = parent.UserData.FuzzType;
        if strcmp(old_fuzz, ctl.Value)
            return;
        end

        % When the fuzz type changes, this block does the closest conversion of the parameters
        if strcmp(ctl.Value, 'Fixed')
            if strcmp(old_fuzz, 'Range')
                cfg = (old_time.Min + old_time.Max) / 2;
            elseif strcmp(old_fuzz, 'Exponential')
                cfg = old_time.Mean;
            end
            parent.UserData.Time = cfg;
            ginsert(parent, 1, 3, @fixedTimeControl);
        elseif strcmp(ctl.Value, 'Exponential')
            if strcmp(old_fuzz, 'Range')
                cfg = fuzzed_exponential((old_time.Min + old_time.Max) / 2, 2*old_time.Min/(old_time.Min + old_time.Max),2*old_time.Max/(old_time.Min + old_time.Max));
            elseif strcmp(old_fuzz, 'Fixed')%I think this is typo here
                cfg = fuzzed_exponential(old_time, 1, 1);
            end
            parent.UserData.Time = cfg;
            ginsert(parent, 1, 3, @exponentialTimeControl);
        else % Range
            if strcmp(old_fuzz, 'Exponential')
                cfg = fuzzed_uniform(old_time.Mean *old_time.Minscale, old_time.Mean*old_time.Maxscale);
            elseif strcmp(old_fuzz, 'Fixed')
                cfg = fuzzed_uniform(old_time, old_time);
            end
            parent.UserData.Time = cfg;
            ginsert(parent, 1, 3, @uniformTimeControl);
        end

        parent.UserData.FuzzType = ctl.Value;
    end

    function grid = timeControl(parent, title, tag, cfg, enable_fuzz)
        grid = uigridlayout(parent, [1, 3], ...
            'Padding', [0, 0, 0, 0], ...
            'RowHeight', {'fit'}, ...
            'ColumnWidth', {'fit', 'fit', 'fit'}, ...
            'Tag', tag ...
            );
        grid.UserData.Time = cfg;
        grid.UserData.ControlGroupSetValueFcn = @(src, value) setfield(src.UserData, 'Time', value);
        grid.UserData.ControlGroupValueFcn = @(src) src.UserData.Time;

        items = {'Fixed'};

        if ~(exist('enable_fuzz', 'var') && enable_fuzz)
            grid.ColumnWidth{2} = 0;
            ginsert(grid, 1, 3, @numberControl, 'Time', cfg);
        else
            items = [items, 'Range', 'Exponential'];
        end

        ginsert(grid, 1, 1, @uilabel, 'Text', title);
        dd = ginsert(grid, 1, 2, @uidropdown, 'Items', items, 'ValueChangedFcn', @switchTimeControl);

        if ~isstruct(cfg)
            dd.Value = 'Fixed';
            ginsert(grid, 1, 3, @fixedTimeControl);
        elseif isfield(cfg, 'Exponential') && cfg.Exponential
            dd.Value = 'Exponential';
            ginsert(grid, 1, 3, @exponentialTimeControl);
        else
            dd.Value = 'Range';
            ginsert(grid, 1, 3, @uniformTimeControl);
        end
        grid.UserData.FuzzType = dd.Value;
    end


    function grid = taskTimeControls(parent, cfg)
        grid = buildColumn(parent, ...
            @timeControl, {'Acquire FP', 'AcquireFP', cfg.Timing.AcquireFP}, ...
            @timeControl, {'FP Hold', 'FPHold', cfg.Timing.FPHold, true}, ...
            @timeControl, {'TG On to FP Off', 'TGOnToFPOff', cfg.Timing.TGOnToFPOff, true}, ...
            @timeControl, {'Response Window', 'ResponseWindow', cfg.Timing.ResponseWindow}, ...
            @timeControl, {'Maximum Saccade Time', 'MaximumSaccade', cfg.Timing.MaximumSaccade}, ...
            @timeControl, {'TG Hold to Reward', 'TGHoldToReward', cfg.Timing.TGHoldToReward, true}, ...
            @timeControl, {'Invalid Timeout', 'InvalidTimeout', cfg.Timing.InvalidTimeout, true}, ...
            @timeControl, {'Inter-Trial Time', 'InterTrialInterval', cfg.Timing.InterTrialInterval, true} ...
            );
        grid.Tag = 'Timing';

    end

% function s = summarizeBlock(Block)
%     s = 0;
%     for i = 1:length(Block)
%         s = s + Block{i}.TrialCount;
%     end
%     s = sprintf('%d target locations with a total of %d trials per block', length(Block), s);
% end

    function addRow(src, ~)
        parent = src.Parent;
        parent.UserData.Block{length(parent.UserData.Block) + 1} = struct('x', 3, 'y', 3, 'TrialCount', 10);
        lst = findobj(parent, 'Tag', 'ScheduleList');
        scheduleRow(lst, parent.UserData.Block, length(parent.UserData.Block));
        % summary = findobj(parent, 'Tag', 'BlockSummary');
        % summary.Text = summarizeBlock(parent.UserData.Block);
    end

    function removeRow(src, ~)
        row = src.UserData;
        parent = src.Parent.Parent;
        if length(parent.UserData.Block) == 1
            return;
        end
        parent.UserData.Block(row) = [];
        % summary = findobj(parent, 'Tag', 'BlockSummary');
        % summary.Text = summarizeBlock(parent.UserData.Block);
        old_list = findobj(parent, 'Tag', 'ScheduleList');
        delete(old_list);
        ginsert(parent, 3, [1 2], @scheduleList, parent.UserData.Block);
    end

    function onXChange(src, ~)
        trial_index = src.UserData.TrialIndex;
        parent = src.Parent.Parent.Parent;
        parent.UserData.Block{trial_index}.x = src.Value;
    end

    function onYChange(src, ~)
        trial_index = src.UserData.TrialIndex;
        parent = src.Parent.Parent.Parent;
        parent.UserData.Block{trial_index}.y = src.Value ;
    end

    function onTrialCountChange(src, ~)
        trial_index = src.UserData.TrialIndex;
        parent = src.Parent.Parent.Parent;
        parent.UserData.Block{trial_index}.TrialCount = src.Value;
        % summary = findobj(parent, 'Tag', 'BlockSummary');
        % summary.Text = summarizeBlock(parent.UserData.Block);
    end

    function scheduleRow(grid, block, i)
        grid.RowHeight{i} = 'fit';
        ginsert(grid, i, 1, @numberControl, 'x', block{i}.x, 'Limits', [-inf,inf], 'UserData', struct('TrialIndex', i), 'ValueChangedFcn', @onXChange, 'ValueDisplayFormat', '%g');
        ginsert(grid, i, 2, @numberControl, 'y', block{i}.y, 'Limits', [-inf,inf], 'UserData', struct('TrialIndex', i), 'ValueChangedFcn', @onYChange, 'ValueDisplayFormat', '%g');
        ginsert(grid, i, 3, @numberControl, 'Trial Count', block{i}.TrialCount, 'UserData', struct('TrialIndex', i), 'ValueChangedFcn', @onTrialCountChange);
        ginsert(grid, i, 4, @uibutton, 'Text', 'Remove', 'UserData', i, 'ButtonPushedFcn', @removeRow);
    end

    function grid = scheduleList(parent, block)
        grid = uigridlayout(parent, [length(block), 4], ...
            'Padding', [0, 0, 0, 0], ...
            'ColumnWidth', {'fit', 'fit', 'fit', 'fit'}, ...
            'RowHeight', {'fit'}, ...
            'Tag', 'ScheduleList' ...
            );
        for i = 1:length(block)
            scheduleRow(grid, block, i);
        end
    end

    function overrideChange(src, ~)
        parent = src.Parent;
        parent.UserData.override = src.Value;
        if src.Value
            parent.RowHeight{2} = 'fit';
            parent.RowHeight{3} = 0;
            parent.RowHeight{4} = 0;
            parent.RowHeight{5} = 'fit';
            parent.RowHeight{6} = 'fit';
        else
            parent.RowHeight{2} = 'fit';
            parent.RowHeight{3} = 'fit';
            parent.RowHeight{4} = 'fit';
            parent.RowHeight{5} = 0;
            parent.RowHeight{6} = 0;
        end
    end

    function handmapChange(src, ~)
        parent = src.Parent;
        parent.UserData.handmap = src.Value;
        if src.Value
            parent.RowHeight{2} = 0;
            parent.RowHeight{3} = 0;
            parent.RowHeight{4} = 0;
            parent.RowHeight{5} = 0;
            parent.RowHeight{6} = 0;
        else
            parent.RowHeight{2} = 'fit';
            if parent.UserData.override
                parent.RowHeight{5} = 'fit';
                parent.RowHeight{6} = 'fit';
            else
                parent.RowHeight{3} = 'fit';
                parent.RowHeight{4} = 'fit';
            end
        end
    end

    function textChange(ctl, field_name)
        parent = ctl.Parent;     
        parent.UserData.(field_name) = str2num(ctl.Value);
    end

    function grid = scheduleControl(parent, cfg)
        grid = uigridlayout(parent, [6, 2], ...
            'Padding', [0, 0, 0, 0], ...
            'RowHeight', {'fit','fit', 'fit','fit', 'fit','fit'}, ...
            'ColumnWidth', {'1x', '2x'}, ...
            'Tag', 'Schedule' ...
            );
        grid.UserData.Block = cfg.NewBlock;
        grid.UserData.override = cfg.BlockOverride;
        grid.UserData.handmap = cfg.handmap;
        grid.UserData.angles = cfg.angles;
        grid.UserData.eccens = cfg.eccens;
        ginsert(grid, 1, 1, @uicheckbox, 'Text', 'Handmap Target?', 'Value', cfg.handmap, 'ValueChangedFcn', @handmapChange);
        ginsert(grid, 2, 1, @uicheckbox, 'Text', 'Override default block', 'Value', cfg.BlockOverride, 'ValueChangedFcn', @overrideChange);
        if cfg.handmap
            grid.RowHeight{2} = 0;
            grid.RowHeight{3} = 0;
            grid.RowHeight{4} = 0;
            grid.RowHeight{5} = 0;
            grid.RowHeight{6} = 0;
        else
            grid.RowHeight{2} = 'fit';
            if cfg.BlockOverride
                grid.RowHeight{3} = 0;
                grid.RowHeight{4} = 0;
                grid.RowHeight{5} = 'fit';
                grid.RowHeight{6} = 'fit';
            else
                grid.RowHeight{3} = 'fit';
                grid.RowHeight{4} = 'fit';
                grid.RowHeight{5} = 0;
                grid.RowHeight{6} = 0;
            end
        end
        ginsert(grid, 3, 1, @uilabel, 'Text','Default angles'); 
        ginsert(grid, 3, 2, @uieditfield, 'text', 'Value', num2str(cfg.angles), 'ValueChangedFcn', @(src, ~) textChange(src, 'angles'));       
        ginsert(grid, 4, 1, @uilabel, 'Text','Default eccens'); 
        ginsert(grid, 4, 2, @uieditfield, 'text', 'Value', num2str(cfg.eccens), 'ValueChangedFcn', @(src, ~) textChange(src, 'eccens'));
        ginsert(grid, 5, [1 2], @scheduleList, grid.UserData.Block);
        ginsert(grid, 6, 1, @uibutton, 'Text', 'Add Target Location', 'ButtonPushedFcn', @addRow);
    end

    function onDone(src, ~)
        all_values = main_cg.Value;

        fig = src.Parent.Parent;

        Settings = struct('Position',struct('Center',[all_values.Position.Centerx,all_values.Position.Centery]));
        Settings.handmap = findobj(fig, 'Tag', 'Schedule').UserData.handmap;

        Settings.angles = findobj(fig, 'Tag', 'Schedule').UserData.angles;
        Settings.eccens = findobj(fig, 'Tag', 'Schedule').UserData.eccens;
        Settings.DefaultBlock = {};
        for angle_idx = 1:length(Settings.angles)
            for eccen_idx = 1:length(Settings.eccens)
                x = Settings.eccens(eccen_idx)*sin(Settings.angles(angle_idx)*pi/180);
                y = Settings.eccens(eccen_idx)*cos(Settings.angles(angle_idx)*pi/180);
                Settings.DefaultBlock = [Settings.DefaultBlock,struct('x', round(x,2), 'y', round(y,2), 'TrialCount', 10)];
            end
        end

        Settings.NewBlock = findobj(fig, 'Tag', 'Schedule').UserData.Block;
        Settings.BlockOverride = findobj(fig, 'Tag', 'Schedule').UserData.override;
        if Settings.BlockOverride
            Settings.Block = Settings.NewBlock;
        else
            Settings.Block = Settings.DefaultBlock;
        end
        Settings.FP = all_values.FP;
        Settings.TG = all_values.TG;
        repeat_stim = findobj(fig, 'Tag', 'RepeatStimulus');
        Settings.RepeatStimulusInvalid = strcmp(repeat_stim.Value, 'Invalid Trials') ;

        Settings.RewardProbability = all_values.Reward.Probability;
        times = {'AcquireFP', 'FPHold', 'TGOnToFPOff', 'ResponseWindow', 'MaximumSaccade', 'TGHoldToReward', 'InterTrialInterval', 'InvalidTimeout'};
        for i = 1:length(times)
            Settings.Timing.(times{i}) = findobj(fig, 'Tag', times{i}).UserData.Time;
        end
        Settings.Timing.RewardDuration = all_values.Reward.Duration;


        fig.UserData.Result = Settings;
        uiresume(fig);
    end
end
