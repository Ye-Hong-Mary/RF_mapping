function test_scheduler()
    
block1 = struct('LeftBias', 0.5, 'Coherence', 1, 'TrialCount', 1);
block2 = struct('LeftBias', 0.5, 'Coherence', 0.5, 'TrialCount', 1);

sch = create_schedule({block1, block2});
assert(sch.Remaining == 2);

t = get_trial(sch);
assert(isstruct(t));

c = t.Coherence;
sch = remove_trial(sch, t);

t = get_trial(sch);
assert(isstruct(t));

c = c + t.Coherence;
sch = remove_trial(sch, t);

assert(sch.Remaining == 0);
assert(c == 1.5);

end
