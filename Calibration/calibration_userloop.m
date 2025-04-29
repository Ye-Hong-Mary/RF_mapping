function [C,timingfile,userdefined_trialholder] = calibration_userloop(MLConfig,TrialRecord)

C = [];
timingfile = 'eye_calib.m';
userdefined_trialholder = '';

persistent RunTime;
if isempty(RunTime)

    rng('shuffle');
    TrialRecord.User.BlockNumber = 0; %% NEED THIS
    RunTime = get_function_handle(embed_timingfile(MLConfig,timingfile,userdefined_trialholder));
    return;
end

timingfile = RunTime;