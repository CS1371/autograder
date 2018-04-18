% Valid Feedback
%
%   Assume F is a valid Feedback with a valid TestCase
%   F = Feedback(...);
%   engine(F);
%
%   F now has files, outputs, etc. filled in correctly
function [passed, msg] = test()
    p = [pwd filesep 'feedback'];
    info.call = '[out] = helloWorld(in);';
    info.initializer = '';
    info.points = 3;
    info.banned = {};
    info.supportingFiles = {'vars.mat'};
    T = TestCase(info, p);
    F = Feedback(T, p);
    try
        F2 = engine(F);
        % output should be input (1)
        if ~isfield(F2.outputs, 'out')
            passed = false;
            msg = 'Output field "out" not created';
            return;
        elseif ~isequal(F2.outputs.out, 'hello.txt')
            passed = false;
            msg = 'Output not correctly set; expected 1';
            return;
        else
            passed = true;
            msg = 'Output correctly created';
        end 
    catch e
        passed = false;
        msg = sprintf('Expected success; got exception %s', e.identifier);
    end
end
