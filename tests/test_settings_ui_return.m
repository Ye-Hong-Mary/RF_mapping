function test_settings_ui_return()

params = default_params();
default_desc = describe(params);

fig = settings_ui(params);
fig.Visible = false;
btn = findobj(fig, 'Tag', 'ApplySettings');
btn.ButtonPushedFcn(btn, []);

result_desc = describe(fig.UserData.Result);
delete(fig);

% These were never assigned in the UI

assert(isequal(default_desc, result_desc));

    function desc = describe(s)
        if ~isstruct(s)
            desc = [];
            return;
        end

        names = fieldnames(s);
        for i = 1:length(names)
            desc.(names{i}) = describe(s.(names{i}));
        end
    end

end