function MainUI = settings_ui(Settings)
    % If importing settings from an earlier version, these variables may not be initialized yet.

    
    % if ~isfield(Settings.Timing, 'IncorrectTimeout')
    %     Settings.Timing.IncorrectTimeout = 0;
    % end
    % if ~isfield(Settings.Timing, 'InvalidTimeout')
    %     Settings.Timing.InvalidTimeout = 0;
    % end

    % if ~isfield(Settings.Timing, 'MaximumSaccade')
    %     Settings.Timing.MaximumSaccade = 1000;
    % end
    if isfield(Settings, 'RepeatStimulusIncorrect')
        rmfield(Settings, 'RepeatStimulusIncorrect');
    end

    if ~isfield(Settings, 'BlockOverride')
        Settings.BlockOverride = 0;
    end

    if ~isfield(Settings,'DefaultBlock')
        Settings.DefaultBlock = Settings.Block;
    end

    if ~isfield(Settings,'NewBlock')
        Settings.NewBlock = {struct('x', 3,'y', 3,'TrialCount', 10)};
    end

    % Timingfields = fieldnames(Settings.Timing);
    % for fieldNum = 1:length(Timingfields)
    %     if isstruct(Settings.Timing.(Timingfields{fieldNum})) & isfield(Settings.Timing.(Timingfields{fieldNum}), 'Gaussian')
    %         Settings.Timing.(Timingfields{fieldNum}).Exponential = Settings.Timing.(Timingfields{fieldNum}).Gaussian;  
    %         if Settings.Timing.(Timingfields{fieldNum}).Gaussian & isfield(Settings.Timing.(Timingfields{fieldNum}), 'Stdev') & isfield(Settings.Timing.(Timingfields{fieldNum}), 'Cutoff')
    %             Settings.Timing.(Timingfields{fieldNum}) = rmfield(Settings.Timing.(Timingfields{fieldNum}), 'Stdev');
    %             Settings.Timing.(Timingfields{fieldNum}) = rmfield(Settings.Timing.(Timingfields{fieldNum}), 'Cutoff');
    %             Settings.Timing.(Timingfields{fieldNum}).Minscale = 0.8;
    %             Settings.Timing.(Timingfields{fieldNum}).Maxscale = 2;
    %         end
    %         Settings.Timing.(Timingfields{fieldNum}) = rmfield(Settings.Timing.(Timingfields{fieldNum}), 'Gaussian');
    %     end
    % end

    % For convenience, some things will be grouped / scaled differently in the UI than in the Settings struct
    Settings.Reward.Duration = Settings.Timing.RewardDuration
    Settings.Timing = rmfield(Settings.Timing, 'RewardDuration');
    Settings.Reward.Probability = Settings.RewardProbability;
    Settings = rmfield(Settings, 'RewardProbability');
    % if isfield(Settings.Timing, 'TimeoutInvalid')
    %     Settings = rmfield(Settings, 'TimeoutInvalid');
    % end
    % if isfield(Settings.Timing, 'TimeoutIncorrect')
    %     Settings = rmfield(Settings, 'TimeoutIncorrect');
    % end

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

    % timeout_dd = main_cg.Controls.TimeoutType;
    % if Settings.TimeoutIncorrect
    %     if Settings.TimeoutInvalid
    %         timeout_dd.Value = 'All Errors';
    %     else
    %         timeout_dd.Value = 'Incorrect Responses';
    %     end
    % else
    %     if Settings.TimeoutInvalid
    %         timeout_dd.Value = 'Invalid Trials';
    %     else
    %         timeout_dd.Value = 'Never';
    %     end
    % end

    repeat_dd = main_cg.Controls.RepeatStimulus;
    % if Settings.RepeatStimulusIncorrect
    %     if Settings.RepeatStimulusInvalid
    %         repeat_dd.Value = 'All Errors';
    %     else
    %         repeat_dd.Value = 'Incorrect Responses';
    %     end
    % else
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
        % cg.addLabel('Enabled', 3, 1);
        % if isfield(cfg, 'Enabled')
        %     cg.addControl('Enabled', 3, 2, @uicheckbox, 'Text', '', 'Value', cfg.Enabled);
        % else
        %     cg.Grid.RowHeight{3} = 0; % A sneaky way of ensuring the controls are aligned even when no enablement is there
        % end
    end

    % function cg = glassPatternControl(parent, title, cfg)
    %     cg = ControlGroup.fittedGrid(parent, [4 7]);
    %     cg.Grid.ColumnWidth{7} = '1x';

    %     cg.addControl('', 1, [1 6], @header, title);
    %     cg.addToRow(2, 1, ...
    %         'Color', {'Color', @colorButton, cfg.Color}, ...
    %         'Dot Size', {'DotSize', @uieditfield, 'numeric', 'Value', cfg.DotSize, 'Limits', [0 inf], 'ValueDisplayFormat', '%d px', 'RoundFractionalValues', 'on'}, ...
    %         'Pair Spacing', {'Spacing', @uieditfield, 'numeric', 'Value', cfg.Spacing, 'Limits', [0 inf], 'ValueDisplayFormat', '%d px', 'RoundFractionalValues', 'on'});
    %     cg.addToRow(3, 3, ...
    %         'Diameter', {'Diameter', @uieditfield, 'numeric', 'Value', cfg.Diameter, 'Limits', [1 inf], 'ValueDisplayFormat', '%d px', 'RoundFractionalValues', 'on'}, ...
    %         'Number of Dots', {'DotCount', @uieditfield, 'numeric', 'Value', cfg.DotCount, 'Limits', [0 inf], 'RoundFractionalValues', 'on'});

    %     % This is a little hack to ensure the columns line up with the
    %     % visual target control's controls
    %     cg.addLabel('Enabled', 4, 1);
    %     cg.Grid.RowHeight{4} = 0;
    % end

    function cg = positionControl(parent, title, cfg)
        cg = ControlGroup.fittedGrid(parent, [2 7]);
        cg.Grid.ColumnWidth{7} = '1x';

        cg.addControl('', 1, [1 6], @header, title);
        cg.addToRow(2, 1, ...
            'Center x', {'Centerx', @uieditfield, 'numeric', 'Value', cfg.Center(1), 'Limits', [-inf inf], 'ValueDisplayFormat', '%g°'},...
            'Center y', {'Centery', @uieditfield, 'numeric', 'Value', cfg.Center(2), 'Limits', [-inf inf], 'ValueDisplayFormat', '%g°'});
        % cg.addToRow(3, 1, ...
        %   'Center y', {'Centery', @uieditfield, 'numeric', 'Value', cfg.Center(2), 'Limits', [-inf inf], 'ValueDisplayFormat', '%g°'});
        % cg.addLabel('Flipped', 4, 1);
        % cg.Grid.RowHeight{4} = 0;
    end

    function cg = rewardControl(parent, title, cfg)
        cg = ControlGroup.fittedGrid(parent, [3 4]);
        cg.Grid.ColumnWidth{4} = '1x';
        cg.addControl('', 1, [1 3], @header, title);
        cg.addToRow(2, 1, 'Probability', {'Probability', @percentageControl, cfg.Probability});
        cg.addToRow(3, [1 3], {'Duration', @timeControl, 'Duration', 'RewardDuration', cfg.Duration, true});
    end

    % function editCurve(src)
    %     grid = src.Parent;
    %     parent = grid.Parent;
    %     response_window = findobj(MainUI, 'Tag', 'ResponseWindow').UserData.Time;
    %     parent.UserData.Time = show_reactioncurve_settings(parent.UserData.CurveName, response_window, parent.UserData.Time);
    %     ginsert(grid, 1, 1, @numberControl, 'Min', parent.UserData.Time.Min, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Min'));
    %     ginsert(grid, 1, 2, @numberControl, 'Max', parent.UserData.Time.Max, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Max'));
    % end

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

    % function grid = reactionCurveControl(parent)
    %     grid = uigridlayout(parent, [1, 3]);
    %     grid.ColumnWidth = {'fit', 'fit'};
    %     grid.Padding = [0, 0, 0, 0];
    %     cfg = parent.UserData.Time;
    %     ginsert(grid, 1, 1, @numberControl, 'Min', cfg.Min, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Min'));
    %     ginsert(grid, 1, 2, @numberControl, 'Max', cfg.Max, 'ValueDisplayFormat', '%d ms', 'ValueChangedFcn', @(src, ~) setTimeField(src, 'Max'));
    %     ginsert(grid, 1, 3, @uibutton, 'Text', 'Edit Curve', 'ButtonPushedFcn', @(src, ~) editCurve(src));
    % end

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
            % else % Curve
            %     cfg = fuzz(old_time, 0.5, 1.0);
            end
            parent.UserData.Time = cfg;
            ginsert(parent, 1, 3, @fixedTimeControl);
        elseif strcmp(ctl.Value, 'Exponential')
            if strcmp(old_fuzz, 'Range')
                cfg = fuzzed_exponential((old_time.Min + old_time.Max) / 2, 2*old_time.Min/(old_time.Min + old_time.Max),2*old_time.Max/(old_time.Min + old_time.Max));
            elseif strcmp(old_fuzz, 'Fixed')%I think this is typo here
                cfg = fuzzed_exponential(old_time, 1, 1);
            % else % Curve
            %     cfg = fuzzed_exponential((old_time.Min + old_time.Max) / 2, 2*old_time.Min/(old_time.Min + old_time.Max),2*old_time.Max/(old_time.Min + old_time.Max));
            end
            parent.UserData.Time = cfg;
            ginsert(parent, 1, 3, @exponentialTimeControl);
        % elseif strcmp(ctl.Value, 'Reaction-Dependent')
        %     if strcmp(old_fuzz, 'Range')
        %         cfg = fuzzed_curve(old_time.Min, old_time.Max);
        %     elseif strcmp(old_fuzz, 'Exponential')
        %         cfg = fuzzed_curve(old_time.Mean *old_time.Minscale, old_time.Mean*old_time.Maxscale);
        %     else % Fixed
        %         cfg = fuzzed_curve(max(0, old_time - 1), old_time + 1);
        %     end
        %     parent.UserData.Time = cfg;
        %     ginsert(parent, 1, 3, @reactionCurveControl);
        else % Range
            if strcmp(old_fuzz, 'Exponential')
                cfg = fuzzed_uniform(old_time.Mean *old_time.Minscale, old_time.Mean*old_time.Maxscale);
            elseif strcmp(old_fuzz, 'Fixed')
                cfg = fuzzed_uniform(old_time, old_time);
            % else % Curve
            %     cfg = fuzzed_uniform(old_time.Min, old_time.Max);
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
        % grid.UserData.CurveName = title;
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

        % if exist('enable_curve', 'var') && enable_curve
        %     items = [items, 'Reaction-Dependent'];
        % end

        ginsert(grid, 1, 1, @uilabel, 'Text', title);
        dd = ginsert(grid, 1, 2, @uidropdown, 'Items', items, 'ValueChangedFcn', @switchTimeControl);

        if ~isstruct(cfg)
            dd.Value = 'Fixed';
            ginsert(grid, 1, 3, @fixedTimeControl);
        % elseif isfield(cfg, 'Curve') && cfg.Curve
        %     dd.Value = 'Reaction-Dependent';
        %     ginsert(grid, 1, 3, @reactionCurveControl);
        elseif isfield(cfg, 'Exponential') && cfg.Exponential
            dd.Value = 'Exponential';
            ginsert(grid, 1, 3, @exponentialTimeControl);
        else
            dd.Value = 'Range';
            ginsert(grid, 1, 3, @uniformTimeControl);
        end
        grid.UserData.FuzzType = dd.Value;
    end

    % function onTaskType(src, ~)
    %     parent = src.Parent;
    %     parent.UserData.TaskIsDelay = strcmp(src.Value, 'Delay');
    %     if parent.UserData.TaskIsDelay
    %         parent.RowHeight{6} = 'fit';
    %         parent.RowHeight{7} = 0;
    %         parent.RowHeight{9} = 0;
    %     else
    %         parent.RowHeight{6} = 0;
    %         parent.RowHeight{7} = 'fit';
    %         parent.RowHeight{9} = 'fit';
    %     end
    % end

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
        % grid.UserData.TaskIsDelay = cfg.TaskIsDelay;
        grid.Tag = 'Timing';

        % dd = findobj(grid, 'Tag', 'TaskType');
        % if cfg.TaskIsDelay
        %     dd.Value = 'Delay';
        % else
        %     dd.Value = 'Reaction';
        % end
        % onTaskType(dd);
    end

    function s = summarizeBlock(Block)
        s = 0;
        for i = 1:length(Block)
            s = s + Block{i}.TrialCount;
        end
        s = sprintf('%d target locations with a total of %d trials per block', length(Block), s);
    end

    function addRow(src, ~)
        parent = src.Parent;
        parent.UserData.Block{length(parent.UserData.Block) + 1} = struct('x', 3, 'y', 3, 'TrialCount', 10);
        lst = findobj(parent, 'Tag', 'ScheduleList');
        scheduleRow(lst, parent.UserData.Block, length(parent.UserData.Block));
        summary = findobj(parent, 'Tag', 'BlockSummary');
        summary.Text = summarizeBlock(parent.UserData.Block);
    end

    function removeRow(src, ~)
        row = src.UserData;
        parent = src.Parent.Parent;
        if length(parent.UserData.Block) == 1
            return;
        end
        parent.UserData.Block(row) = [];
        summary = findobj(parent, 'Tag', 'BlockSummary');
        summary.Text = summarizeBlock(parent.UserData.Block);
        old_list = findobj(parent, 'Tag', 'ScheduleList');
        delete(old_list);
        ginsert(parent, 2, [1 2], @scheduleList, parent.UserData.Block);
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
        summary = findobj(parent, 'Tag', 'BlockSummary');
        summary.Text = summarizeBlock(parent.UserData.Block);
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

    function grid = scheduleControl(parent, cfg)
        grid = uigridlayout(parent, [4, 2], ...
            'Padding', [0, 0, 0, 0], ...
            'RowHeight', {'fit', 'fit', 'fit'}, ...
            'ColumnWidth', {'fit', '1x'}, ...
            'Tag', 'Schedule' ...
        );
        grid.UserData.Block = cfg.NewBlock;
        ginsert(grid, 1, 1, @uilabel, 'Text', 'Block Override');
        override = ginsert(grid, 1, 2, @uicheckbox, 'Text', '', 'Value', cfg.BlockOverride);
        grid.UserData.override = override.Value;
        ginsert(grid, 2, [1 2], @uilabel, 'Text', summarizeBlock(grid.UserData.Block),  'Tag', 'BlockSummary');
        ginsert(grid, 3, [1 2], @scheduleList, grid.UserData.Block);
        ginsert(grid, 4, 1, @uibutton, 'Text', 'Add Target Location', 'ButtonPushedFcn', @addRow);
    end

    function onDone(src, ~)
        all_values = main_cg.Value;

        fig = src.Parent.Parent;
        DefaultBlock = Settings.DefaultBlock;

        Settings = struct('Position',struct('Center',[all_values.Position.Centerx,all_values.Position.Centery]));
        Settings.DefaultBlock = DefaultBlock;
        % keyboard
        Settings.NewBlock = findobj(fig, 'Tag', 'Schedule').UserData.Block;
        Settings.BlockOverride = 1;%findobj(fig, 'Tag', 'Schedule').UserData.override;
        if Settings.BlockOverride
            Settings.Block = Settings.NewBlock; 
        else
            Settings.Block = Settings.DefaultBlock;
        end
        % Settings.Position.Target = [all_values.Position.Targetx,all_values.Position.Targety];
        % Settings.Position.Right = [all_values.Position.Rightx,all_values.Position.Righty];
        % Settings.Position = struct('Center',[all_values.Position.Centerx,all_values.Position.Centery]);
        % Settings.Position.Flipped = all_values.Position.Flipped;
        Settings.FP = all_values.FP;
        Settings.TG = all_values.TG;
        % Settings.DIS = all_values.DIS;
        % Settings.GP = all_values.GP;

        % timeout = findobj(fig, 'Tag', 'TimeoutType');
        % Settings.TimeoutInvalid = (strcmp(timeout.Value, 'Invalid Trials') || strcmp(timeout.Value, 'All Errors'));
        % Settings.TimeoutIncorrect = (strcmp(timeout.Value, 'Incorrect Responses') || strcmp(timeout.Value, 'All Errors'));
        repeat_stim = findobj(fig, 'Tag', 'RepeatStimulus');
        Settings.RepeatStimulusInvalid = strcmp(repeat_stim.Value, 'Invalid Trials') ;
        % Settings.RepeatStimulusIncorrect = (strcmp(repeat_stim.Value, 'Incorrect Responses') || strcmp(repeat_stim.Value, 'All Errors'));

        Settings.RewardProbability = all_values.Reward.Probability;

        % timing = findobj(fig, 'Tag', 'Timing');
        % tasktype_dd = findobj(timing, 'Tag', 'TaskType');
        % Settings.TaskIsDelay = strcmp(tasktype_dd.Value, 'Delay');

        times = {'AcquireFP', 'FPHold', 'TGOnToFPOff', 'ResponseWindow', 'MaximumSaccade', 'TGHoldToReward', 'InterTrialInterval', 'InvalidTimeout'};
        for i = 1:length(times)
            Settings.Timing.(times{i}) = findobj(fig, 'Tag', times{i}).UserData.Time;
        end
        Settings.Timing.RewardDuration = all_values.Reward.Duration;

        % Settings.Blok = findobj(fig, 'Tag', 'Schedule').UserData.Block;

        fig.UserData.Result = Settings;
        uiresume(fig);
    end
end
