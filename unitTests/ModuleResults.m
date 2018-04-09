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
    methods
        function this = ModuleResults(path)

        end
    end
    methods (Access=public)
        function html = generateHtml(this)

        end
    end
end
