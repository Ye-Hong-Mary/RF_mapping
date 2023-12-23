function test_session_stats()
    stats = SessionStats();
    
    t1.Left = true;
    t1.Coherence = 0.98;

    t2.Left = false;
    t2.Coherence = 0.98;

    t3.Left = true;
    t3.Coherence = 0.5;

    t4.Left = false;
    t4.Coherence = 0.5;

    stats.addCorrect(t1);
    stats.addIncorrect(t2);
    stats.addCorrect(t1);
    stats.addIncorrect(t2);
    stats.addCorrect(t1);
    stats.addInvalid(t4);
    stats.addCorrect(t3);
    stats.addIncorrect(t4);

    assert(stats.All.Correct == 4);
    assert(stats.All.Incorrect == 3);
    assert(stats.All.Invalid == 1);
    assert(stats.All.Total == 8);
    assert(stats.All.Valid == 7);
    assert(stats.All.Accuracy == 4 / 7);
    assert(stats.All.ValidRate == 7 / 8);

    assert(stats.ByDirection.Left.Accuracy == 1.0);
    assert(stats.ByDirection.Right.Accuracy == 0.0);
    assert(stats.byCoherence(0.5).ValidRate == 2 / 3);
end
