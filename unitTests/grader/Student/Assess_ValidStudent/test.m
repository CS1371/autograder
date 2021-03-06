%% Assess: Assessing a valid Student
%
% This student (and the solution) have all the possible outputs; a normal
% output, a File, and a Plot. The output will be incorrect, but the points
% should still work out

function [passed, msg] = test()
    % Create TestCases
    progress.CancelRequested = false;
    cd('Solutions');
    solutions = generateSolutions(false, progress);
    cd('..');
    recs = Resources;
    recs.BasePath = 'https://my/url';
    recs.Problems = solutions;
    % Create our valid student
    
    S = Student([pwd filesep 'tuser3'], 'Test User', '000000', recs);
    
    % Assess
    try
        S.assess();
    catch e
        passed = false;
        msg = sprintf('Expected success; got %s - "%s"', e.identifier, e.message);
        return;
    end
    % grade should be 2/3 of total
    if round(1.20 * S.Grade, 2) ~= 15.2
        passed = false;
        msg = sprintf('Expected %0.2f points; got %0.2f points', ...
            15.2, ...
            round(1.20 * S.Grade, 2));
        return;
    elseif ~isfile([S.path filesep 'feedback.html'])
        passed = false;
        msg = 'Expected feedback; got none';
        return;
    else
        passed = true;
        msg = '';
    end
end