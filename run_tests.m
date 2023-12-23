function run_tests()
% RUN_TESTS Runs a number of checks on subsystems of the Protocols package.
% If successful, it will simply disp that the tests passed; otherwise,
% you will see errors in the Command Window.

oldpath = path();
path(path(oldpath, 'UI'), 'tests');

test_scheduler();
test_session_stats();

runUIFrameworkTests();
test_settings_ui_return();

path(oldpath);
disp('All tests passed');

end
