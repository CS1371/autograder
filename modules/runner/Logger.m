%% Logger: Event Logger for the Autograder
%
% The purpose of the Logger is to keep a record of events as they happen.
%
%%% Fields
%
% RECORD_FORMAT: The format for a record; a constant
%
%%% Methods
%
% initialize
%
% log
%
% delete (overriden)
%
%%% Remarks
%
% The Logger class is a static class - it is designed to never be
% instantiated. This allows for any function to call on a logger, even if
% it was not given access to it.
%
% Normally, this is avoided, but for loggers, anything and everything
% should be able to log - passing the Logger back and forth would be
% inefficient, especially considering there will never be a time where two
% separate loggers are needed.
%
classdef Logger < handle
    properties (Constant)
        RECORD_FORMAT char = '%s: %s logged event: %s';
    end
    properties (Access=private)
        fid = -1;
    end
    methods
        function this = Logger(path)
        %% Constructor: Initialize the logger for logging
        %
        % This will create and open a file for logging.
        %
        % Logger() will create a log file for logging. This file
        % will be called autograder.log extension and will be in the
        % current directory. If autograder.log already exists, then it is
        % overwritten.
        %
        % Logger(P) will create a log file in the path P. If P is a
        % folder, then the log file will be called autograder.log. If P is
        % a filename, if the file already exists, it will be deleted and
        % overwritten.
        %
        %%% Remarks
        %
        % This will initialize the logger and open a file handle to
        % it.
        %
        % File closing is automatically handled via the destructor - once
        % the instantiation is out of scope and deleted, the destructor
        % will close the file.
        %
        %%% Exceptions
        %
        % An AUTOGRADER:Logger:fileIO exception will be thrown if the file
        % could not be created.
        %
        %%% Unit Tests
        %
        %   Logger();
        %
        %   Log file created in the current folder
        %
        %   P = 'C:\Users\...\';
        %   Logger(P);
        %
        %   Log file autograder.log created in path P.
        %
        %   P = 'C:\Users\...\myOwnLog.log';
        %   Logger(P);
        %
        %   Log file myOwnLog.log created in path P.
        %
        %   P = '';
        %   Logger(P);
        %
        %   Threw fileIO exception.
        end
        
        function delete(this)
        %% delete: Handle deletion of the logger
        %
        % This method overrides the normal delete functionality
        %
        % delete(L) closes the file and deletes the logger
            if this.fid == -1
                return;
            else
                fclose(this.fid);
            end
        end
    end
    methods (Static, Access=public)
        function log(message, file)
        %% log: Log an event as a record in the log file
        %
        % The log method is used to log specific events in the log file.
        %
        % log(M) will log message M in the log file. This message includes
        % the writer (caller) and the timestamp.
        %
        %%% Remarks
        %
        % This method will log an event according to the constant
        % RECORD_FORMAT, which looks like this:
        %
        % <TIMESTAMP>: <CALLER> logged event: <MESSAGE>
        %
        %%% Exceptions
        %
        % An AUTOGRADER:Logger:notInitialized exception will be thrown if
        % the logger hasn't been properly initialized.
        %
        %%% Unit Tests
        %
        %   Logger.log('Hello, World');
        %
        %   Log: TIMESTAMP: caller logged event: Hello, World
        %
        %   Logger.log('Not Initialized');
        %
        %   Threw notInitialized exception
        end
    end
end