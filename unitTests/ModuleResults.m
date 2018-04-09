%% ModuleResults: Run and record all tests for this Module
%
% ModuleResults is responsible for running _all_ the unit tests for this module
%
%%% Fields
%
% * path: The path to this module
% * name: The name of this module
% * passed: Whether or not this module passed inspection
%
%%% Methods
%
% * ModuleResults
% * generateHtml
%
%%% Remarks
%
% This is used by the builder to test an entire module - See UnitResults for more information.

classdef ModuleResults < handle
    properties (Access=public)
        path;
        name;
        passed;
    end
    properties (Access=private)
        unitResults;
    end
    methods
        function this = ModuleResults(path)
        %% Constructor
        %
        % Create a new ModuleResults from the given path
        %
        % this = ModuleResults(P) will use the path in P to create and run all the unit tests for that module.
        %
        %%% Exceptions
        %
        % This method is guaranteed to never throw an exception
            this.path = path;
            [~, this.name, ~] = fileparts(path);

            % Find all units:
            origPath = cd(path);
            % units are directories
            units = dir();
            units(~[units.isdir]) = [];
            units(strncmp({units.name}, '.', 1)) = [];
            for u = numel(units):-1:1
                this.unitResults(u) = UnitResults(fullfile(units(u).folder, units(u).name));
            end
            cd(origPath);
        end
        function passed = get.passed(this)
            passed = all([this.testResults.passed]);
        end
    end
    methods (Access=public)
        function html = generateHtml(this)
        %% generateHtml: Generate HTML feedback for this module
        %
        % Generate the HTML feedback that represents all the unit tests for this module
        %
        % H = this.generateHtml() will create HTML in variable H. This HTML has none of the necessary "boilerplate", such as a title or includes.
        % That behavior is delegated to the caller
        %
        %%% Remarks
        %
        % This is used almost exclusively during building or generating documentation.
        %
        %%% Exceptions
        %
        % This method is guaranteed to never throw an exception
        %

        end
    end
end
