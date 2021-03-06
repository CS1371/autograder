%% TestResults: Run test case and record results
%
% TestResults class is responsible for running a single test case.
%
%%% Fields
%
% * path: The path to this test's directory
% * name: The name of this test
% * passed: Whether or not this test passed
% * message: Optional message for this test case
% * method: The method this test applies to (optional)
%
%%% Methods
%
% * TestResults
% * generateHtml
%
%%% Remarks
%
% This class represents the results of a single Unit Test - not all tests for that unit.
%
classdef TestResults < handle
    properties (Access=public)
        path;
        name;
        passed;
        message;
        method;
    end
    properties (Constant)
        PASSING_MARK = '<i class="fas fa-check"></i>';
        FAILING_MARK = '<i class="fas fa-times"></i>';
    end
    methods
        function this = TestResults(path)
        %% Constructor
        %
        % Run a given single test
        %
        % this = TestResults(P) will use the path in P to create a TestResults. The path should lead to
        % that folder's specific unit test (the single test).
        %
        %%% Remarks
        %
        % This constructor creates a single test case from the given path - it does not generate a test case
        %
        %%% Exceptions
        %
        % This function is guaranteed to never throw an exception

            % Need to account for noargs constructor call - otherwise
            % error when preallocating a vector of TestResults
            if nargin ~= 1
                return
            end

            % create temporary directory
            workDir = tempname;
            mkdir(workDir);
            
            origPath = cd(path);
            function clean(p, d)
                cd(p);
                [~] = rmdir(d, 's');
            end
            cleaner = onCleanup(@()(clean(origPath, workDir)));
            % copy over everything in the PATH directory
            copyfile([pwd filesep '*'], workDir);
            files = dir('**/*.m');
            % for each file, get it's dbstatus, and then do the replacement
            for f = 1:numel(files)
                file = files(f);
                try
                    status = dbstatus([file.folder filesep file.name], '-completenames');
                catch
                    status = [];
                end
                relativeFolder = [workDir strrep(file.folder, path, '')];
                for i = 1:numel(status)
                    status(i).file = [relativeFolder filesep file.name];
                    status(i).name = regexprep(status(i).name, '^[^>]*', [relativeFolder filesep file.name]);
                    dbstop(status(i));
                end
            end
            
            % change name
            % copy over any FILES in parent
            files = dir('../*.m');
            files([files.isdir]) = [];
            for f = 1:numel(files)
                try
                    status = dbstatus([files(f).folder filesep files(f).name], '-completenames');
                catch
                    status = [];
                end
                copyfile([files(f).folder filesep files(f).name], workDir);
                for i = 1:numel(status)
                    status(i).file = [workDir filesep files(f).name];
                    status(i).name = regexprep(status(i).name, '^[^>]*', [workDir filesep files(f).name]);
                    dbstop(status(i));
                end
            end
            

            this.path = path;
            [~, this.name, ~] = fileparts(path);
            % classes begin with a capital letter. So if two folders up is a class, this is a method
            [~, className, ~] = fileparts(fileparts(path));
            % if capital letter, class:
            if className(1) >= 'A' && className(1) <= 'Z'
                % class, all tests are methods. If no _, then constructor
                if contains(this.name, '_')
                    [this.method, this.name] = strtok(this.name, '_');
                    this.name = this.name(2:end);
                else
                    this.method = 'Constructor';
                end
            else
                this.method = '';
            end

            cd(workDir);

            % we know test.m will exist
            try
                [this.passed, this.message] = test();
            catch e
                this.passed = false;
                this.message = sprintf('<span class="test-error">Test threw exception %s: %s', ...
                    e.identifier, e.message);
            end
            close('all', 'force');
            fclose('all');
        end
    end
    methods (Access=public)
        %% generateHtml: Create HTML feedback for this test
        %
        % Create HTML feedback
        %
        % H = generateHtml(this) will use this to create the HTML in H. It will be a row with the results.
        % this HTML is _not_ suitable for presentation - it is the "bare-bones"
        %
        %%% Remarks
        %
        % This is used to generate the overall test results. It is unlikely to be used outside of this role
        %
        %%% Exceptions
        %
        % This function is guaranteed to never throw an exception
        function html = generateHtml(this)
            html = {'<div class="row result">', '<div class="col-12">'};
            if this.passed
                html = [html {'<h4 class="test-name">', '<code>', this.PASSING_MARK, this.name, '</code>', '</h4>'}];
            else
                html = [html {'<h4 class="test-name">', '<code>', this.FAILING_MARK, this.name, '</code>', '</h4>'}];
            end
            html = [html {'<div class="test-message">', '<p>', this.message, '</p>', '</div>', '</div>', '</div>'}];
            html = strjoin(html, newline);
        end
    end
end