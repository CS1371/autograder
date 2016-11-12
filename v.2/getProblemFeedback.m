%% getProblemFeedback Grades the given student's function outputs
%
%   student = getProblemFeedback(problem, student, problemNumber)
%
%   Inputs:
%       problem (struct)
%           - structure representing a homework problem and contains
%           details regarding the test cases
%       student (struct)
%           - structure representing a student
%       problemNumber (double)
%           - the number of the problem
%
%   Output:
%       student (struct)
%           - the updated structure with the results and grades for the
%           test cases
%
%   Description:
%       Gets feedback for a student for a single problem
function student = getProblemFeedback(problem, student, problemNumber)

    settings = getSettings();

    student.feedback = sprintf('%s<p><strong>Problem Score:</strong> %.2f/%.2f</p>', student.feedback, student.problems(problemNumber).grade, problem.points);

    for ndxTestCase = 1:length(problem.testCases)
        testCase = problem.testCases(ndxTestCase);

        % concatenate test case number
        student.feedback = sprintf('%s<h3>Test Case %d</h3>', student.feedback, ndxTestCase);

        % concatenate test case
        student.feedback = sprintf('%s<pre>load(''%s'');<br/>%s<br/></pre>', student.feedback, problem.matFile, testCase.call);

        % only run if there is a feedback submission
        if ~student.problems(problemNumber).fileExists
            student.feedback = sprintf('%s<p>ERROR: File does not exist %s</p>', student.feedback, settings.images.RED_CROSS);
        else
            % if there is an error
            if ~isempty(student.problems(problemNumber).testCases(ndxTestCase).output.errors)
                ME = student.problems(problemNumber).testCases(ndxTestCase).output.errors;
                student.feedback = sprintf('%s<p>ERROR: %s %s</p>', student.feedback, getProblemErrorMessage(ME, problem.name), settings.images.RED_CROSS);
            else
                for ndxVariable = 1:length(testCase.outputVariables)

                    pointsReceived = student.problems(problemNumber).testCases(ndxTestCase).pointsPerOutput(ndxVariable);
                    pointsOutOf = testCase.pointsPerOutput(ndxVariable);

                    message = student.problems(problemNumber).testCases(ndxTestCase).output.messages{ndxVariable};
                    outputVariable = testCase.outputVariables{ndxVariable};

                    if pointsReceived == pointsOutOf
                        %concatenate variable
                        student.feedback = sprintf('%s<pre style="display:inline">%s</pre><p style="display:inline">: PASS (%.2f points) %s</p><br/>', student.feedback, outputVariable, pointsReceived, settings.images.GRN_CHECK);
                    else
                        %concatenate variable
                        student.feedback = sprintf('%s<pre style="display:inline">%s</pre><p style="display:inline">: FAIL - %s %s</p><br/>', student.feedback, outputVariable, message, settings.images.RED_CROSS);

                        % open table
                        student.feedback = sprintf('%s<table style="padding-left:20px;table-layout:fixed;width:100%%">', student.feedback);

                        % concatenate function value
                        student.feedback = sprintf('%s<tr><td style="vertical-align:top;width:50px"><p>Function Value</p></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, visualizeValue(student.problems(problemNumber).testCases(ndxTestCase).output.variables{ndxVariable}));

                        % concatenate solution value
                        student.feedback = sprintf('%s<tr><td style="vertical-align:top;width:50px"><p>Solution Value</p></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, visualizeValue(testCase.output.variables{ndxVariable}));

                        % close table
                        student.feedback = sprintf('%s</table>', student.feedback);
                    end
                end

                % if there are output files
                if ~isempty(testCase.output.files)
                    
                    studentFiles = student.problems(problemNumber).testCases(ndxTestCase).output.files;
                    studentMessages = student.problems(problemNumber).testCases(ndxTestCase).output.messages;
                    
                    for ndxFile = 1:length(testCase.output.files)
                        file = testCase.output.files(ndxFile);
                        
                        ndx = ndxFile + length(testCase.outputVariables);
                        
                        pointsReceived = student.problems(problemNumber).testCases(ndxTestCase).pointsPerOutput(ndx);
                        pointsOutOf = testCase.pointsPerOutput(ndx);

                        % if student has output files with the given name
                        if ~isempty(studentFiles) && any(strcmp({studentFiles.name},file.name))
                            
                            message = studentMessages{ndx};
                            
                            if pointsReceived == pointsOutOf
                                %concatenate variable
                                student.feedback = sprintf('%s<pre style="display:inline">%s</pre><p style="display:inline">: PASS (%.2f points) %s</p><br/>', student.feedback, file.name, pointsReceived, settings.images.GRN_CHECK);
                            else
                                % This is my rendition of having a visual
                                % comparison of the text files. It simply
                                % utilizes MATLAB's visdiff() function and
                                % puts the html in as the field
                                % "Difference". 
                                
                                    % We find the visdiff:
                                strHTML = visdiff(file.name, studentFiles(strcmp({studentFiles.name},file.name)).name);
                                    % then, instead of 'concatenate
                                    % function file value', we do this:
                                student.feedback = sprintf('%s<tr><td></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, strHTML);
                                %concatenate filename
                                student.feedback = sprintf('%s<pre style="display:inline">%s</pre><p style="display:inline">: FAIL - %s %s</p><br/>', student.feedback, file.name, message, settings.images.RED_CROSS);

                                % open table
                                student.feedback = sprintf('%s<table style="padding-left:20px;table-layout:fixed;width:100%%">', student.feedback);
                                student.feedback = sprintf('%s<tr><td></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, strHTML);
                                % concatenate function file value
                                %student.feedback = sprintf('%s<tr><td style="vertical-align:top;width:50px"><p>Function Value</p></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, visualizeValue(studentFiles(strcmp({studentFiles.name},file.name)).value));

                                % concatenate solution file value
                                %student.feedback = sprintf('%s<tr><td style="vertical-align:top;width:50px"><p>Solution Value</p></td><td style="padding-left:10px;word-wrap:break-word">%s</td></tr>', student.feedback, visualizeValue(file.value));

                                % close table
                                student.feedback = sprintf('%s</table>', student.feedback);
                            end
                        else
                            student.feedback = sprintf('%s<pre style="display:inline">%s</pre><p style="display:inline">: FAIL - FILE DOES NOT EXIST %s</p><br/>', student.feedback, file.name, settings.images.RED_CROSS);
                        end
                    end
                end
            end

            %concatenate test case score
            student.feedback = sprintf('%s<p><em>Test Case Score:</em> %.2f/%.2f</p>', student.feedback, student.problems(problemNumber).testCases(ndxTestCase).grade, testCase.points);
        end
    end
end

function error_message = getProblemErrorMessage(ME, problem_name)
    fields = fieldnames(ME);
    if any(strcmp(fields, 'cause')) && ~isempty(ME.cause)
        ME = ME.cause{1};
        error_message = getProblemErrorMessage(ME, problem_name);
    else
        error_message = sprintf('%s', ME.message);
        if ~isempty(ME.stack)
            line_number = -1;
            for ndx = 1:length(ME.stack)
                if strcmp(ME.stack(ndx).name, problem_name)
                    line_number = ME.stack(ndx).line;
                end
            end
            if line_number > -1
                error_message = sprintf('"%s" in %s at line %d', ME.message, problem_name, line_number);
            end
        end
    end
end