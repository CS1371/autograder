%% engine: Main Engine of the Autograder
%
% The engine function serves as the primary runner of code.
%
% engine(T) runs the code specified by the TestCase T, and assigns the
% outputs, files, and plots to the corresponding fields in T.
%
% engine(F) runs the code specified by the TestCase found in Feedback F,
% and assigns the outputs, files, and plots to the corresponding fields 
% in F. This does NOT grade the code, just runs it.
%
%%% Remarks
%
% The engine function is the primary grading mechanism used within the
% the autograder. It provides a "sandboxed" environment for running code,
% and protects against student errors and timeouts.
%
% Timeouts are handled using a parallel pool of workers. In essence, a 
% student's code is limited to a certain runtime, 30 seconds by default.
% To change this value, you should edit the TIMEOUT field of the STudent
% class.
%
% Errors in the code itself are handled differently, depending on whether 
% a TestCase or a Feedback was passed in.
%
% If a TestCase was received, the error is propogated; this is because a 
% solution error is usually a fatal error.
%
% If a Feedback was received, the error is caught and assigned to the 
% exception field of the Feedback.
%
%%% Exceptions
%
% An AUTOGRADER:ENGINE:INVALIDRUNNABLE exception is thrown if the input is in an 
% invalid state.
%
% An AUTOGRADER:ENGINE:BADSOLUTION exception is thrown if the input is a solution
% AND that solution errors. The original exception is added to the 
% causes array of the MException.
%
% A TIMEOUT exception will never be thrown, but will be assigned to the 
% Feedback's exception field instead, should the code timeout.
%%% Unit Tests
%
%   % Assume T is a valid TestCase that does NOT error.
%   T = TestCase(...);
%   engine(T);
%
%   T now has files, outputs, etc. filled in correctly
%
%   % Assume T is a valid TestCase that errors
%   T = TestCase(...);
%   engine(T);
%
%   Threw exception BADSOLUTION, with the original error 
%   in causes.
%
%   % Assume T has not been correctly initialized
%   T;
%   engine(T);
%
%   Threw exception INVALIDRUNNABLE
%
%   % Assume F is a valid Feedback with a valid TestCase
%   F = Feedback(...);
%   engine(F);
%
%   F now has files, outputs, etc. filled in correctly
%
%   % Assume F is a valid Feedback that errors
%   F = Feedback(...);
%   engine(F);
%
%   F will have no fields filled in except for points (0) and exception, 
%   which will be the exception raised by the student code.
%
%   % Assume F is a valid Feedback that goes into an infinite loop
%   F = Feedback(...);
%   engine(F);
%
%   F will have no fields filled in except for points (0) and exception,
%   which will be the TIMEOUT exception.
%
%   % Assume F is an invalid Feedback;
%   F;
%   engine(F);
%
%   Threw exception INVALIDRUNNABLE   
%
function engine(runnable)

    % For banned functions, we'll need to use static checking, instead of 
    % overwriting it in the directory. This is because some functions
    % (like length) are extremely necessary for MATLAB to even function
    % correctly. I would recommend the following:
    %
    %   calls = getcallinfo('FunctionName.m');
    %   calls = [calls.calls];
    %   calls = [calls.fcnCalls];
    %   calls = [calls.names];
    %
    %   Now, calls is cell array of called functions. For each function which 
    %   isn't built in, we could walk them recursively, checking for use of the
    %   banned function. Personally, I think that's overkill. This cell array
    %   represents all functions called by any function inside the FunctionName.m
    %   file.

    % This code is divided up into three sections:
    % 
    %   1. Setup
    %   2. Running
    %   3. Cleanup
    %
    % Setup sets up the initial call. It cleans up the workspace, 
    % sets up the supporting Files.
    %
    % Running defines all late-bound variables and runs the function itself,
    % on a parallel worker. This is done to protect against timeouts. The Feedback
    % or TestCase object is populated here - EVEN IF there is a timeout exception.
    % However, if the TestCase times out, engine should rethrow the timeout error.
    %
    % *NOTE*: Late-bound variables (defined via the initializer) are defined immediately
    % before a function is run. As such, the produced error could be from an initializer.
    % However, this does not cause problems with students, since this error happens 
    % during solution code as well.
    %
    % Cleanup cleans up the directory to make it look "pristine" - or at least as it 
    % did before. It deletes all files mentioned in the runnable's outputs, and closes 
    % all plots.

    %% Setup
    if isa(runnable, 'TestCase')
        tCase = runnable;
    else
        tCase = runnable.testCase;
    end

    % Copy over supporting files
    supportingFiles = tCase.supportingFiles;
    loadFiles = tCase.loadFiles;
    [inNames, outNames, func] = parseFunction(tCase.call);

    allCalls = getcallinfo([func2str(func) '.m']);
    calls = [allCalls.calls];
    calls = [calls.fcnCalls];
    calls = [calls.names];

    % Test for recursion. If any function calls itself, good to go.
    isRecur = false;
    for i = 1:numel(allCalls)
        call = allCalls(i);
        if ~exist(call.name, 'builtin') && any(strcmp(call.name, call.calls.innerCalls.names))
            isRecur = true;
            break;
        end
    end
    if isa(runnable, 'Feedback')
        runnable.isRecursive = isRecur;
    end

    bannedFunctions = tCase.banned;
    for i = 1:numel(bannedFunctions)
        if any(strcmpi(calls, bannedFunctions{i}))
            if isa(runnable, 'TestCase')
                throw(MException('AUTOGRADER:ENGINE:BADSOLUTION', 'Solution uses banned functions'));
            else
                runnable.exception = MException('AUTOGRADER:ENGINE:BANNED', 'File used banned function %s.', bannedFunctions{i});
                return;
            end
        end
    end

    for i = 1:numel(supportingFiles)
        copyfile(supportingFiles{i});
        [~, supportingFiles{i}, ext] = fileparts(supportingFiles{i});
        supportingFiles{i} = [supportingFiles{i}, ext];
    end
    % Record starting point
    beforeSnap = dir();
    beforeSnap = {beforeSnap.name};
    beforeSnap(strncmp(beforeSnap, '.', 1)) = [];

    % See how long it takes to load data. Add that time to TIMEOUT
    tic;
    for i = 1:numel(tCase.loadFiles)
        % throw away result
        S = load(tCase.loadFiles{i});
    end
    timeToLoad = toc;
    clear('S');
    %% Running
    % Create a new job for the parallel pool
    test = parfeval(@runCase, 0, runnable);

    % Wait until it's finished, up to 30 seconds
    isTimeout = ~wait(test, 'finished', Student.TIMEOUT + timeToLoad);
    
    % Delete the job
    if isTimeout
        cancel(test);
    end
    delete(test);

    % Populate files, plots
    afterSnap = dir();
    afterSnap = {afterSnap.name};
    afterSnap(strncmp(afterSnap, '.', 1)) = [];
    
    addedFiles = sort(setdiff(afterSnap, beforeSnap));

    populateFiles(runnable, addedFiles);
    populatePlots(runnable);

    %% Cleanup
    % Delete all files mentioned in the files field
    for i = 1:numel(runnable.files)
        % Delete file with name of File
        delete([runnable.files(i).name runnable.files(i).extension]);
    end
    
    % Delete all files that were marked as supporting files
    for i = 1:numel(supportingFiles)
        delete(supportingFiles{i});
    end
    for i = 1:numel(loadFiles)
        delete(loadFiles{i});
    end

    % Close all figures with visible handles?
    figs = findobj(0, 'type', 'figure');
    delete(figs);
    
    % If timeout and TestCase, throw error
    if isa(runnable, 'TestCase') && isTimeout
        throw(MException('MATLAB:TIMEOUT', 'Solution Code Timed Out'));
    end
end

function populateFiles(runnable, addedFiles)
    % Get last file first to prealloc array
    files(numel(addedFiles)) = File([pwd() filesep() addedFiles{end}]);
    % Iterate over all files (including last one again) so that _soln
    % can be removed if necessary
    for i = 1:numel(addedFiles)
        files(i) = File([pwd() filesep() addedFiles{i}]);
        if isa(runnable, 'TestCase')
            % Remove _soln from name
            files(i).name = strrep(files(i).name, '_soln', '');
        end
    end

    runnable.files = files;
end

function populatePlots(runnable)
    % Get all handles; since the Position is captured, that can be used 
    % for the subplot checking
    pHandles = findobj(0, 'type', 'axes');
    plots(numel(pHandles)) = Plot(pHandles(end));
    for i = 1:(numel(pHandles) - 1)
        plots(i) = Plot(pHandles(i));
    end

    runnable.plots = plots;
end


function runCase(runnable)
    % Setup workspace
    timeout = Timeout();
    % is this supposed to be here?  -->     cleanup();
    cleaner = onCleanup(@() cleanup(runnable, timeout));

    if isa(runnable, 'TestCase')
        tCase = runnable;
    else
        tCase = runnable.testCase;
    end
    if ~isempty(tCase.initializer)
        % Append initializer call to end of varDefs
        % Make sure suppressed!
        if tCase.initializer(end) ~= ';'
            tCase.initializer = [tCase.initializer ';'];
        end
        init = tCase.initializer;
    else
        init = '';
    end
    
    % Parse the call
    [inNames, outNames, func] = parseFunction(tCase.call);
    outs = cell(size(outNames));
    % run the function
    [outs{:}] = runner(func, init, inNames, tCase.loadFiles);

    % Populate outputs
    % outNames is in order of argument. For each outName, apply corresponding
    % value
    for i = 1:numel(outs)
        runnable.outs.(outNames{i}) = outs{i};
    end
    timeout.isTimeout = false;
end

function varargout = runner(func____, init____, ins, loads____)
    
    % Create statement that becomes cell array of all inputs.
    % No input sanitization here because all input names have already
    % been checked.
    inCell____ = ['{' strjoin(ins, ',') '}'];
    % varargout becomes cell array of the size of number of args requested
    varargout = cell(size(nargout));
    % Load MAT files
    cellfun(@load, loads____);
    % Run initializer, if any
    if ~isempty(init____)
        eval(init____);
    end
    % Create true cell array of inputs to use in func
    ins____ = eval(inCell____);
    % Run func
    [varargout{:}] = func____(ins____{:});
end

function defs = buildVariableDefs(tCase)
    % Run any initializers

end

function [ins, outs, func] = parseFunction(call)

    % For inputs, look for starting paren. If not found, no inputs
    ins = regexp(call, '(?<=\()([^)]+)(?=\))', 'match');
    if ~isempty(ins)
        ins = ins{1};
        ins = strsplit(ins, ',');
    end

    % For outputs, look for an equal sign. No equal sign, no outputs
    if ~contains(call, '=')
        outs = {};
    else
        % if no bracket found, only one output. Grab accordingly
        if ~contains(call, ']')
            outs = regexp(call, '[^\=]*')
        else
            % We have brackets; find in between and engage
            outs = regexp(call, '(?<=\[)([^\]]+)(?=\])', 'match');
            if ~isempty(outs)
                outs = outs{1};
                outs = strsplit(outs, {', ', ',', ' '});
            end
        end
    end

    % For function name, strip everything before possible =, everything
    % after possible (.
    if contains(call, '=')
        ind = strfind(call, '=');
        call(1:ind) = '';
    end
    if contains(call, '(')
        ind = strfind(call, '(');
        call(ind:end) = '';
    end
    func = str2func(call);        

end

function cleanup(runnable, isTimeout)
    % check if runnable is TestCase or Feedback
    fclose('all');
    
    if isa(runnable, 'Feedback')
        if timeout.isTimeout
            runnable.exception = MException('TIMEOUT');
            return;
        end
    else
        if timeout.isTimeout
            e = MException('TIMEOUT');
            throw(e);
        end
    end
end