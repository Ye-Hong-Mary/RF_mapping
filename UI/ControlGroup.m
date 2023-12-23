% CONTROLGROUP A handle type for grouping related uifigure-based controls
%
% Provides a Value property for getting/setting a struct across the group
% Each control lives in the Controls struct under the same name as its
% corresponding value in the Value struct
%
% Each control can also provide a ControlGroupValueFcn and
% ControlGroupSetValueFcn in its UserData struct; otherwise its Value
% property will be used when getting/setting the Value of this group.

classdef ControlGroup < handle
    properties
        Grid;
        Controls;
    end

    methods
        function obj = ControlGroup(grid, varargin)
            % CONTROLGROUP The constructor, which takes similar arguments to the setup function
            % See also SETUP

            obj = obj@handle();

            if exist('grid', 'var')
                obj.setup(grid, varargin{:});
            end
        end

        function setup(obj, grid, varargin)
            % SETUP Construct the group's controls
            %   Arguments:
            %     grid A uigridlayout to use as the parent for all controls
            %     varargin Some number of cell arrays each expanded to
            %              match the arguments of addControl
            %
            % See also ADDCONTROL

            obj.Grid = grid;
            obj.Controls = [];
            for i = 1:length(varargin)
                obj.addControl(varargin{i}{:});
            end
        end

        function lbl = addLabel(obj, text, r, c, varargin)
            % ADDLABEL A convenience function that creates a uilabel at the specified grid location
            %   Arguments:
            %     text     The char to display in the uilabel
            %     r, c     The destination row and column for the uilabel
            %     varargin Any other properties to set on the uilabel
            %   Note: Labels constructed in this way do not show up in Controls

            arguments
                obj (1, 1) ControlGroup
                text char
                r {mustBeInteger, mustBeNonnegative}
                c {mustBeInteger, mustBeNonnegative}
            end

            arguments (Repeating)
                varargin
            end

            lbl = uilabel(obj.Grid, 'Text', text, varargin{:});
            lbl.Layout.Row = r;
            lbl.Layout.Column = c;
        end

        function ctl = addControl(obj, name, r, c, cons, varargin)
            % ADDCONTROL Add a control to the group and to its grid layout
            %   Arguments:
            %     name     An identifier to use within Value and Controls for this control (empty: does not show up in Value or Controls)
            %     r, c     The destination row and column for the control
            %     cons     A function handle to the control's constructor
            %     varargin Any other properties to set while constructing the control
            %   Note: Named Controls must use struct UserData, so that UserData.ControlGroup can be set.

            arguments
                obj (1, 1) ControlGroup
                name
                r {mustBeInteger, mustBeNonnegative}
                c {mustBeInteger, mustBeNonnegative}
                cons (1, 1) {mustBeUnderlyingType(cons, 'function_handle')}
            end

            arguments (Repeating)
                varargin
            end

            ctl = cons(obj.Grid, varargin{:});

            if ~isempty(name)
                obj.Controls.(name) = ctl;
            end

            if isa(ctl, 'ControlGroup')
                ctl = ctl.Grid;
            end

            ctl.Layout.Row = r;
            ctl.Layout.Column = c;

            if ~isempty(name)
                ctl.UserData.ControlGroup = obj;
            end
        end

        function addToRow(obj, r, c, varargin)
            % ADDTOROW Add a series of controls to a grid row
            %   Arguments:
            %     r The row index all controls will share
            %     c The column index to begin from
            %     varargin Some number of specifications
            %
            %   Specifications can be:
            %     false (which leaves the column unmodified)
            %     true  (which sets ColumnWidth 1x)
            %     char  (which adds a uilabel to the grid, but not the group)
            %     cell  ({name, cons, args} for a constructor,
            %            or {name, cell} for a nested ControlGroup column)

            arguments
                obj (1, 1) ControlGroup
                r {mustBeInteger, mustBeNonnegative}
                c {mustBeInteger, mustBeNonnegative}
            end

            arguments (Repeating)
                varargin
            end

            for i=1:length(varargin)
                j = c + i - 1;
                spec = varargin{i};
                if isempty(spec)
                    continue;
                elseif islogical(spec)
                    if spec
                        obj.Grid.ColumnWidth{j} = '1x';
                    end
                elseif ischar(spec)
                    obj.addLabel(spec, r, j);
                elseif iscell(spec)
                    name = spec{1};
                    cons = spec{2};
                    if iscell(cons)
                        obj.addControl(name, r, j, @ControlGroup.column, cons{:});
                    else
                        obj.addControl(name, r, j, cons, spec{3:length(spec)});
                    end
                else
                    error("Invalid specification to ControlGroup.addToRow");
                end
            end
        end

        function addToColumn(obj, r, c, varargin)
            % ADDTOCOLUMN Add a series of controls to a grid column
            %   Arguments:
            %     r The row index to begin from
            %     c The column index all controls will share
            %     varargin Some number of specifications
            %
            %   Specifications can be:
            %     false (which leaves the row unmodified)
            %     true  (which sets RowHeight 1x)
            %     char  (which adds a uilabel to the grid, but not the group)
            %     cell  ({name, cons, args} for a constructor,
            %            or {name, cell} for a nested ControlGroup row)

            arguments
                obj (1, 1) ControlGroup
                r {mustBeInteger, mustBeNonnegative}
                c {mustBeInteger, mustBeNonnegative}
            end

            arguments (Repeating)
                varargin
            end

            for i=1:length(varargin)
                j = r + i - 1;
                spec = varargin{i};
                if isempty(spec)
                    continue;
                elseif islogical(spec)
                    if spec
                        obj.Grid.ColumnWidth{j} = '1x';
                    end
                elseif ischar(spec)
                    obj.addLabel(spec, j, c);
                elseif iscell(spec)
                    name = spec{1};
                    cons = spec{2};
                    if iscell(cons)
                        obj.addControl(name, j, c, @ControlGroup.row, cons{:});
                    else
                        obj.addControl(name, j, c, cons, spec{3:length(spec)});
                    end
                else
                    error("Invalid specification to ControlGroup.addToColumn");
                end
            end
        end

    end

    methods (Static)
        function obj = fittedGrid(parent, sz, varargin)
            % FITTEDGRID Create a grid when the control group is created;
            % The created grid will have Padding set to [0 0 0 0] and all
            % rows and columns sized to 'fit'.
            %   Arguments:
            %     parent   A UI parent for the new grid to use
            %     sz       Dimensions for the grid
            %     varargin Additional properties to forward to the uigridlayout constructor

            arguments
                parent (1, 1)
                sz (1, 2) {mustBeInteger, mustBeNonnegative}
            end

            arguments (Repeating)
                varargin
            end

            obj = ControlGroup(uigridlayout(parent, sz, 'Padding', [0 0 0 0], varargin{:}));

            for c = 1:sz(2)
                obj.Grid.ColumnWidth{c} = 'fit';
            end

            for r = 1:sz(1)
                obj.Grid.RowHeight{r} = 'fit';
            end
        end

        function obj = row(parent, varargin)
            % ROW Create a row of controls, and the grid that holds them
            %   Arguments:
            %     parent     A UI parent for the new grid to use
            %     varargin   Some number of specifications (as in addToRow)
            %
            % See also: ADDTOROW

            arguments
                parent (1, 1)
            end
            arguments (Repeating)
                varargin
            end

            N = length(varargin);
            obj = ControlGroup.fittedGrid(parent, [1 N]);
            obj.addToRow(1, 1, varargin{:});
        end

        function obj = column(parent, varargin)
            % COLUMN Create a column of controls, and the grid that holds them
            %   Arguments:
            %     parent     A UI parent for the new grid to use
            %     varargin   Some number of specifications (as in addToColumn)
            %
            % See also: ADDTOCOLUMN

            arguments
                parent (1, 1)
            end
            arguments (Repeating)
                varargin
            end

            N = length(varargin);
            obj = ControlGroup.fittedGrid(parent, [N 1]);
            obj.addToColumn(1, 1, varargin{:});
        end
    end

    properties (Dependent)
        Value;
    end

    methods
        function set.Value(obj, value)
            if ~isstruct(value)
                if ~isfield(obj.Controls, 'Value')
                    error('No such name in ControlGroup: Value');
                end
                ControlGroup.setControlValue(obj.Controls.Value, value);
                return;
            end

            names = fieldnames(value);
            for i = 1:length(names)
                name = names{i};
                if ~isfield(obj.Controls, name)
                    error('No such name in ControlGroup: %s', name);
                end

                ctl = obj.Controls.(name);
                ControlGroup.setControlValue(ctl, value.(name));
            end
        end

        function value = get.Value(obj)
            value = struct();
            names = fieldnames(obj.Controls);
            for i = 1:length(names)
                name = names{i};
                value.(name) = ControlGroup.controlValue(obj.Controls.(name));
            end

            if length(names) == 1 && isequal(name, 'Value')
                value = value.(name);
            end
        end
    end

    methods (Static, Access = private)
        function setControlValue(ctl, value)
            if isprop(ctl, 'UserData') && isstruct(ctl.UserData) && isfield(ctl.UserData, 'ControlGroupSetValueFcn')
                ctl.UserData.ControlGroupSetValueFcn(ctl, value);
            else
                ctl.Value = value;
            end
        end

        function value = controlValue(ctl)
            if isprop(ctl, 'UserData') && isstruct(ctl.UserData) && isfield(ctl.UserData, 'ControlGroupValueFcn')
                value = ctl.UserData.ControlGroupValueFcn(ctl);
            elseif isprop(ctl, 'Value')
                value = ctl.Value;
            else
                value = [];
            end
        end
    end
end
