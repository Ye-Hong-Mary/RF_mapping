function ctl = percentageControl(parent, init_value)

ctl = uieditfield(parent, 'numeric', ...
    'Limits', [0 100], ...
    'ValueDisplayFormat', '%g%%');

ctl.UserData.ControlGroupValueFcn = @(src) src.Value * 0.01;
ctl.UserData.ControlGroupSetValueFcn = @setScalar;

if exist('init_value', 'var')
    setScalar(ctl, init_value);
end

    function setScalar(dst, value)
        dst.Value = value * 100;
    end

end