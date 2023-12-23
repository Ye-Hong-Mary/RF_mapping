function next_scheduled_block(TrialRecord)
    TrialRecord.User.BlockNumber = TrialRecord.User.BlockNumber + 1;
    TrialRecord.NextBlock = TrialRecord.User.BlockNumber;
    TrialRecord.User.RepeatStimulusOnTrial = false;
end
