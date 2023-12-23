function show_settings(TrialRecord, advance_block)
    persistent fig;
    
    if isempty(fig) || ~isvalid(fig)
        oldpath = path();
        path(oldpath, 'UI');
        fig = settings_ui(TrialRecord.User.Settings);
    else
        fig.Visible = true;
    end

    uiwait(fig);
    if isvalid(fig)
        Settings = fig.UserData.Result;

        save('protocol_settings.mat', 'Settings');
        TrialRecord.User.Settings = Settings;
        fig.Visible = false;

        if exist('advance_block', 'var') && advance_block
            TrialRecord.User.state.Remaining = 0; % Trigger replacement on next userloop
        end
    end
end
