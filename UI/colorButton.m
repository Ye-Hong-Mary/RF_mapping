function ctl = colorButton(parent, init_color)
% COLORBUTTON Construct a button that shows a color selection UI on press
%   Arguments:
%     parent     The UI component to use as a parent
%     init_color A unit-valued [R G B] triplet for the initial color state

arguments
    parent (1, 1)
    init_color (1, 3) {mustBeNonnegative}
end

ctl = uibutton(parent);

ctl.UserData.Color = init_color;

ctl.Text = '';
refreshIcon(ctl);

ctl.ButtonPushedFcn = @onPress;
ctl.UserData.ControlGroupSetValueFcn = @(dst, value) setfield(dst.UserData, 'Color', value);
ctl.UserData.ControlGroupValueFcn = @(src) src.UserData.Color;

    function onPress(src, ~)
        src.UserData.Color = uisetcolor(src.UserData.Color, 'Select a color');
        focus(src); % MATLAB2023a has a weird focus bug when using modals
        refreshIcon(src);
    end

    function refreshIcon(btn)
        color = btn.UserData.Color;
        icon = zeros([64, 64, 3]);
        for ch = 1:3
            icon(:, :, ch) = color(ch);
        end
        btn.Icon = icon;
    end
end