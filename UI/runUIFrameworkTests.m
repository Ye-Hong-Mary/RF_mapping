function runUIFrameworkTests()
% Test the UI framework used for Protocols

fig = uifigure('Visible', false);

grid = uigridlayout(fig, [3, 3]);

% Construct empty control group
cg = ControlGroup(grid);
assert(isequal(cg.Grid, grid));

% Construct various builtin UI components

ef = cg.addControl('EditField', 1, 1, @uieditfield, 'numeric', 'Value', 1);
sl = cg.addControl('Slider', 1, 2, @uislider, 'Limits', [1 3], 'Value', 2.0);
assert(ef.Value == 1);
assert(ef.UserData.ControlGroup == cg);
assert(sl.Value == 2.0);
assert(sl.UserData.ControlGroup == cg);

% Set and retrieve value structs

expected = struct('EditField', 1, 'Slider', 2.0);
assert(isequal(cg.Value, expected));

expected.EditField = 3;
expected.Slider = 1.5;
cg.Value = expected;

assert(ef.Value == 3);
assert(sl.Value == 1.5);

% Nest ControlGroups from row and column constructions

row = cg.addControl('Row', 2, [1 2], @ControlGroup.row, {'RowValue', @uieditfield, 'numeric', 'Value', 3});
assert(isequal(class(row), 'matlab.ui.container.GridLayout'));

expected.Row.RowValue = 3;
assert(isequal(cg.Value, expected));

% Add a color button to a column

col = cg.addControl('Column', [1 3], 3, @ControlGroup.column, {'ColumnColor', @colorButton, [0.5 0.5 0.5]});
assert(isequal(class(col), 'matlab.ui.container.GridLayout'));

expected.Column.ColumnColor = [0.5 0.5 0.5];
assert(isequal(cg.Value, expected));

% Test the percentage control

p = cg.addControl('Percentage', 1, 4, @percentageControl, 0.75);
assert(p.Value == 75);

p.Value = 62.5;
expected.Percentage = 0.625;
assert(isequal(cg.Value, expected));

% Try out passthrough ControlGroups

cg = ControlGroup.column(fig, ...
    {'SomeValue', {{'Value', @uieditfield, 'numeric', 'Value', 2.5}}});
assert(cg.Controls.SomeValue.Controls.Value.Value == 2.5);
cfg = cg.Value;
assert(cfg.SomeValue, 2.5);
cfg.SomeValue = 3.0;
cg.Value = cfg;
assert(cg.Controls.SomeValue.Controls.Value.Value == 3.0);

cg = ControlGroup.row(fig, ...
    {'SomeValue', {{'Value', @uieditfield, 'numeric', 'Value', 2.5}}});
assert(cg.Value.SomeValue, 2.5);

% Clean up

delete(fig);
disp('UI tests successful');

end