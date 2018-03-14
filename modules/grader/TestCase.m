%% TestCase: A single test for a homework submission
%
% This class defines a complete test case for a specific problem
%
%%% Fields
%
% * |call|: The complete function call 
% (i.e., |[out1, out2] = myFunction(in1, in2);|)
%
% * |initializer|: The complete function call for a function to be run 
% immediately before testing the student's code
%
% * |points|: The points possible for this specific test case
%
% * |inputs|: A structure array where the field names are the names of the
% variables, and the field values are the values of the variables
%
% * |path|: The fully qualified path to the solution code directory
%
% * |supportingFiles|: A string array of complete file paths that will need 
% to be copied to the student's directory
%
% * |outputs|: A structure where the field name is the name of the output, 
% and the field value is the value of the output
%
% * |files|: A |File| array that represents all the files produced as outputs
%
% * |plots|: A |Plot| array that represents the plots generated
%
%%% Methods
%
% * |TestCase(string json)|
%
%%% Remarks
%
% The |TestCase| class defines all the necessary settings and conditions to
% run a single test of a student's function. The |TestCase| class stores
% the instructions for running the test case, and includes the solution's
% outputs for comparison.
%
% The |initializer| is useful if a variable's value cannot be determined 
% until right before the function call. If |initializer| has outputs that will
% be used as inputs when calling the student's function, the names of the
% outputs must match the expected input names in |call| exactly. Such inputs
% that are generated at runtime don't need to appear in the |inputs| field, and
% should be overwritten if they do exist.
% 
% For example, suppose you wanted to populate input |fid| with a file handle.
% In that case, your |initializer| would look like:
%
%   [fid] = fopen('myInput.txt');
%
% Now suppose |fid| is now 3. This will pass in 3 as an input to the function.
%
% The initializer function can also be used to load a MAT-file, from the
% |supportingFiles| that are copied into the student's directory. Again, the
% variable names inside the MAT-file should match the input names in |call|.
%
classdef TestCase < handle
    properties (Access = public)
        call;
        initializer;
        points;
        inputs;
        supportingFiles;
        path;
        outputs;
        files;
        plots;
    end
    methods
        %% Constructor
        %
        % The |TestCase| constructor creates a new |TestCase| from JSON.
        %
        % T = TestCase(JSON) will create a new |TestCase| with all the fields 
        % filled with values from the solution. The |TestCase| expects an actual 
        % JSON string, _not a JSON filename_.
        %
        %%% Remarks
        %
        % The constructor parses the JSON and fills in all the information 
        % gleaned from that. The JSON should be for a specific test case. Since
        % the single |TestCase| only needs the solution value, banned functions
        % don't matter; thus, |TestCase| does not need to know about what 
        % problem it belongs to.
        %
        % Additionally, |TestCase| does _not_ use the same engine as 
        % |gradeProblem| in the |Student| class. This is because we can safely 
        % assume that a solution function will _not_ error or fall in an 
        % infinite loop. Additionally, there are no banned functions to worry 
        % about, so we don't need to account for those.
        %
        % The format for the JSON is rigidly defined. For a more complete 
        % explanation for this definition, you can refer to the documentation. 
        % However, below is an example submission for the |TestCase| JSON:
        %
        %   {
        %       "call": "[out1, out2] = myFun(in1, in2);",
        %       "initializer": "",
        %       "points": 3,
        %       "inputs": {
        %           "in1": 5,
        %           "in2": true
        %       },
        %       "supportingFiles": [
        %           "myFile.txt",
        %           "myInputImage.png"
        %       ]
        %   }
        %
        % Note that white space does _not_ matter in the input JSON.
        %
        % The |initializer| is a special function call. |initializer| specifies
        % a function that is designed to run _the moment before_ the main test 
        % case is run. This is useful for defining an input that can't be 
        % known until runtime. For example, suppose you wanted an open 
        % file handle as an input. This could not be done at compile time, 
        % since many files may be open when the test case is run. There are 
        % some restrictions on |initializer|, however:
        %
        % * It must be a _valid function call_. It cannot be just proper 
        % MATLAB code - only a single function call is allowed
        %
        % * It's outputs must be named _exactly the same_ as any inputs to 
        % the function.
        %
        % * It can reference any valid function, but variable _inputs_ 
        % to the |initializer| are not allowed.
        %
        % See above for an example of how to use the initializer. 
        % If the initializer is not found, or is left blank, then it is assumed
        % that no initialization is required.
        %
        % As for the |inputs| array, it's values _must_ be literals. You cannot 
        % use arbitrary MATLAB code as the value. To execute arbitrary MATLAB 
        % code, see the remarks for the |initializer|.
        %
        % The caller does _not_ need to worry about "cleaning up" any open 
        % resources (such as files or figures). Since the autograder will 
        % already handle closing these resources, cleanup is the responsibility
        % of |TestCase|, not the writer of the JSON.
        %
        % Additionally, the name of the supporting function can be anything. 
        % But best practice is for it to be named something "guaranteed" to be
        % unique; as such, suffixing the initializer function name with '__'
        % is usually a good idea.
        %
        %%% Exceptions
        %
        % The constructor throws the |AUTOGRADER:TESTCASE:CTOR:PARSEERROR| if
        % there are problems parsing the input JSON. This exception should not
        % be consumed, because this means the |TestCase| is incomplete. It also
        % throws this error if |call| or |initializer| has a syntax error.
        %
        % The constructor throws the |AUTOGRADER:TESTCASE:CTOR:BADSOLUTION| if
        % the solution errors. This should never happen, as long as the 
        % solution files won't error for the given inputs. This error will also 
        % be thrown if the initializer errors when running the solution.
        %
        %%% Unit Tests
        %
        % Assume JSON that looks like the example given above.
        % 
        %   J = '...' % Valid JSON;
        %   T = TestCase(J);
        %
        %   T isa |TestCase|
        %   T.call -> "[out1, out2] = myFun(in1, in2);"
        %   T.initializer -> [];
        %   T.points -> 3;
        %   T.inputs -> struct('in1', 5, 'in2', true);
        %   T.supportingFiles -> ["myFile.txt", "myInputImage.png"];
        % 
        % Note that the following would be filled _after_ running the solution. 
        % This is still done in the constructor. For this example, assume the 
        % function created one image file and one text file. For the purposes 
        % of documenting |TestCase|, we will not explore the contents of 
        % those files - that will be covered in |File|.
        %
        %   T.outputs -> struct('out1', 2, 'out2', 'Hello, World!');
        %   T.files -> File[2]
        %
        % Now suppose the JSON in |J| looks like this:
        %
        %   {
        %       "call": "[out1, out2] = myFun(in1, in2);",
        %       "initializer": "in2 = supportFunction__",
        %       "points": 3,
        %       "inputs": {
        %           "in1": 5
        %       },
        %       "supportingFiles": [
        %           "myFile.txt",
        %           "myInputImage.png",
        %           "supportFunction__.m"
        %       ]
        %   }
        %
        % Note the |initializer| is set. Suppose the following is 
        % found in "supportFunction__.m":
        %
        %   function out = supportFunction__()
        %       out = fopen('myFile.txt', 'r');
        %   end
        %
        % Now we call the function:
        %
        %   T = TestCase(J);
        %
        %   T isa |TestCase|
        %   T.call -> "[out1, out2] = myFun(in1, in2);"
        %   T.initializer -> "[in1] = supportFunction__();";
        %   T.points -> 3;
        %   T.inputs -> struct('in1', 5);
        %   T.supportingFiles -> ["myFile.txt", "myInputImage.png", "supportFunction__.m"];
        %
        % The following are filled in after everything is run. 
        % Note that for this case, the in2 is calculated _immediately_
        % before the function is run.
        %
        %   T.outputs -> struct('out1', 1, 'out2', false);
        %   T.files -> File[2];
        %   T.plots -> Plot[1];
        %
        % Assume J is empty or invalid JSON:
        %   T = TestCase(J);
        %
        %   The constructor threw exception 
        %   AUTOGRADER:TESTCASE:CTOR:PARSEERROR
        %
        % Assume J is valid JSON, but the solution code errors.
        %
        % Running the constructor:
        %   T = TestCase(J);
        % 
        %   The constructor threw exception
        %   AUTOGRADER:TESTCASE:CTOR:BADSOLUTION
        function this = TestCase(json)
            try
                % Parse JSON to get struct with fields |call|,
                % |initializer|, |points|, |inputs|, |supportingFiles|
                data = parseJson(json);
                % Copy values from struct to TestCase. Do one-by-one
                % instead of iterating in case fields are wrong/missing.
                % If a field is missing, exception is caught and
                % re-thrown as a parse error.
                this.call = data.call;
                this.initializer = data.initializer;
                this.points = data.points;
                this.inputs = data.inputs;
                this.supportingFiles = data.supportingFiles;
            catch
                throw(MException('AUTOGRADER:TESTCASE:CTOR:PARSEERROR', ...
                    'Problem parsing JSON'));
            end
            
            % Engine can throw parse exceptions for bad |call| or
            % |initializer|, and bad solution exception. Don't catch,
            % let it propagate instead
            engine.runFunction(this);
        end
    end
end
