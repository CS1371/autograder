%% generateFeedback: Generate HTML feedback for primitives
%
% |generateFeedback| makes presentation-ready HTML that depicts how the 
% student's primitive result compares to the solution's primitive result.
%
% HTML = generateFeedback(STUD, SOLN) will generate HTML encoded feedback, 
% given the student's result and the solution's result. Both must be given, 
% but empty is a valid input for either.
%
%%% Remarks
%
% generateFeedback deals only with "primitive" values. This means 
% the type of the given values must be one of the following:
%
% * |double|
%
% * |single|
%
% * |uint8|, |uint16|, |uint32|, |uint64|
%
% * |int8|, |int16|, |int32|, |int64|
%
% * |char|
%
% * |string|
%
% * |cell|
%
% * |struct|
%
% * |logical|
%
% Note that |NaN| is considered equal to |NaN|; ie, |NaN == NaN = true|.
% This is different from isequal, and instead follows isequaln.
%
% |generateFeedback| first checks each value's class. If they differ,
% a |DIFF_CLASS| is returned. Otherwise, |generateFeedback| checks to see
% if they are |isequaln|. If they are, |PASSING| is returned. The class
% types are checked for before equality because isequaln(double(1),uint8(1))
% returns true. Next, |generateFeedback| checks if the two inputs differ in
% size. If so, |DIFF_DIM| is returned. If not, |generateFeedback| then checks
% if the inputs are non-scalar (excluding char row vectors), and if so,
% recursively calls itself on the elements within the arrays. Otherwise,
% depending on the class and the guidelines below, a visualization of the
% difference between the given arguments is returned. The return value will
% always have the check mark (|PASSING|) or the red x (|INCORRECT|).
%
% `visualize` means the whole thing is printed out. So a visualized array
% means we actually print out the whole array.
% 
% Unless noted, following items only apply to primitives, where a primitive
% is any data type except cell or struct.
% 
% * Strings or character vectors are always visualized as long as they are
% less than 1,000 elements long.
% * Vectors of primitives less than 50 elements are always visualized.
% * Scalar primitives are always visualized.
% * 2 dimensional arrays of primitives with less than 20 rows and less than
% 20 columns are visualized.
% * 3 or more dimensional arrays are not visualized.
% * Scalar structures with less than 15 fields, with primitive values in
% all fields, are visualized.
% * Structure arrays where the only difference is one of the structures is
% visualized (if rule above is met). The only visualization is for the
% single structure, and the index of that structure is noted.
% * Structure arrays where there is more than one different structure are
% not visualized.
% * Scalar cell arrays with less than 50 cells, and primitives inside
% each cell, are visualized.
% * Cell arrays with less than 5 rows and less than 5 columns, and
% primitives inside each cell, are visualized.
% * Any case not covered here isn't visualized.
%
% Any case that is not visualized is instead `differenced`.
% differencing means you take the first 5 differences between the two
% variables, and visualize them. Then, you write that there were n-5 more
% differences, where n is the total number of differences.
%
%%% Exceptions
%
% generateFeedback is guaranteed to never throw an exception, 
% as long as two arguments are given.
%
%%% Unit Tests
%
%   S = [];
%   P = [];
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<span class="fas fa-check"></span>'
%
%   S = NaN;
%   P = NaN;
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<span class="fas fa-check"></span>'
%
%   S = 1;
%   P = S;
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<span class="fas fa-check"></span>'
%
%   S = 'Hello world';
%   P = 1;
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> char class expected; double class given.</p>'
%
%   S = uint8(1);
%   P = double(1);
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> uint8 class expected; double class given.</p>'
%
%   S = 1;
%   P = 2;
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> 1 expected; 2 given.</p>'
%
%   S = "Hello World"
%   P = "Goodbye World"
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> "Hello World" expected; "Goodbye World" given.</p>'
%
%   S = true;
%   P = false;
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> true expected; false given.</p>'
%
%   S = [1 2 3];
%   P = [1; 2; 3];
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> Dimension Mismatch: Expected 1x3; 3x1 given.</p>'
%
%   S = {1, 2, 3};
%   P = {1, 3, 2};
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> At index (1x2): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 2 expected; 3 given.</p></div></p>
%            <p><span class="fas fa-times"></span> At index (1x3): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 3 expected; 2 given.</p></div></p>'
%
%   S = [1, 2, 3];
%   P = [1, 3, 2];
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> At index (1x2): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 2 expected; 3 given.</p></div></p>
%            <p><span class="fas fa-times"></span> At index (1x3): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 3 expected; 2 given.</p></div></p>'
%
%   S = struct('hello', 1, 'world', {1, 2, 3});
%   P = struct('hello', 2, 'world', {3, 2, 1});
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> At index (1x1): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> In field "hello": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 1 expected; 2 given.</p></div></p><p><span class="fas fa-times"></span> In field "world": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 1 expected; 3 given.</p></div></p></div></p>
%            <p><span class="fas fa-times"></span> At index (1x2): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> In field "hello": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 1 expected; 2 given.</p></div></p></div></p>
%            <p><span class="fas fa-times"></span> At index (1x3): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> In field "hello": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 1 expected; 2 given.</p></div></p><p><span class="fas fa-times"></span> In field "world": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 3 expected; 1 given.</p></div></p></div></p>'
%
%   S = struct('a', 1, 'b', 0);
%   P = struct('a', 2, 'c', 10);
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> a,b fields expected; a,c fields given.</p>'
%
%   S = {1, struct('a',1)};
%   P = {{1}, struct('a',2)};
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span> At index (1x1): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> double class expected; cell class given.</p></div></p>
%            <p><span class="fas fa-times"></span> At index (1x2): <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> In field "a": <div style="margin-left: 10px;"><p><span class="fas fa-times"></span> 1 expected; 2 given.</p></div></p></div></p>'
%
%   S is a handle
%   P is a different handle
%   HTML = generateFeedback(P, S);
%
%   HTML -> '<p><span class="fas fa-times"></span>(Disp of S)<br>expected;<br>(Disp of P)<br>given.</p>'
%
% Note that there are a variety of constants, which are listed below:
%
% * |PASSING = '<span class="fas fa-check></span>'|
% * |INCORRECT = '<span class="fas fa-times"></span>'|
% * |DIFF_CLASS =  
% ['<p>' INCORRECT ' %s class expected; %s class given.</p>']|
% * |DIFF_DIM = 
% ['<p>' INCORRECT ' Dimension Mismatch: %s expected; %s given.</p>']|
% * |DIFF_NUM_VALUE = 
% ['<p>' INCORRECT ' %g expected; %g given.</p>']|
% * |DIFF_STR_VALUE = 
% ['<p>' INCORRECT ' "%s" expected; "%s" given.</p>']|
% * |DIFF_BOOL_VALUE = 
% ['<p>' INCORRECT ' %s expected; %s given.</p>']|
% * |DIFF_MISC_VALUE = 
% ['<p>' INCORRECT ' %s<br>expected;<br>%s<br>given.</p>']|
% * |DIFF_ARR_VALUE = 
% ['<p>' INCORRECT ' At index (%s): %s</p>']|
% * |DIFF_STC_VALUE = 
% ['<p>' INCORRECT ' In field "%s"; %s</p>']|
% * |DIFF_STC_FIELD =
% ['<p>' INCORRECT ' %s fields expected; %s fields given.</p>']|
% * |INDENT_BLOCK = '<div style="margin-left: 10px;">%s</div>'|
% Each of these constants has flags for inserting the correct value and
% the received value.

function htmlFeedback = generateFeedback(stud, soln)
    PASSING = '<span class="fas fa-check></span>';
    INCORRECT = '<span class="fas fa-times"></span>';
    DIFF_CLASS = ['<p>' INCORRECT ' %s class expected; %s class given.</p>'];
    DIFF_DIM = ['<p>' INCORRECT ' Dimension Mismatch: %s expected; %s given.</p>'];
    TABLE = ['<p>' INCORRECT ' Value Incorrect:</p><div class="row"><div class="col-md-6"><p>Expected:</p>%s</div><div class="col-md-6"><p>Given:</p>%s</div></div>'];
    DIFF_VALUE = '<p>%s expected; %s given.</p>';
    DIFF_ARR_VALUE = '<p>At index (%s): %s</p>';
    DIFF_STC_VALUE = '<p>In field "%s": %s</p>';
    DIFF_STC_FIELD = '<p>%s fields expected; %s fields given.</p>';
    INDENT_BLOCK = '<div style="margin-left: 10px;">%s</div>';
    
    % check if different class
    if ~isequal(class(soln), class(stud))
        htmlFeedback = sprintf(DIFF_CLASS, class(soln), class(stud));
        return
    end
        
    % check if equal
    % do after class check because isequaln(uint8(1),double(1)) is true
    if isequaln(soln, stud)
        htmlFeedback = PASSING;
        return
    end
        
    % check if same size
    if ~isequal(size(soln), size(stud))
        solnSize = strrep(num2str(size(soln)), '  ', 'x');
        studSize = strrep(num2str(size(stud)), '  ', 'x');
        htmlFeedback = sprintf(DIFF_DIM, solnSize, studSize);
        return
    end
        
    % check if char vector/string and meets visualization rule
    if ischar(stud) && ismatrix(stud) && all(size(stud) <= [1 1000]) ...
        || isstring(stud) && numel(strlength(stud)) == 1 && strlength(stud) <= 1000
        htmlFeedback = sprintf(TABLE, visualizePrimitive(soln), visualizePrimitive(stud));
        return
    end
    
    % check if is a scalar primitive
    if isscalar(stud) && isprimitive(stud)
        htmlFeedback = sprintf(TABLE, visualizePrimitive(soln), visualizePrimitive(stud));
        return
    end
    
    % check if is a structure
    if isstruct(stud)
        solnFields = fieldnames(soln);
        studFields = fieldnames(stud);
        % if different fields
        if ~isequal(sort(solnFields), sort(studFields))
            htmlFeedback = sprintf(DIFF_STC_FIELD, strjoin(solnFields, ','), ...
                strjoin(studFields, ','));
            return
        end
        % indexes (linearized) of different structures in struct array
        diffs = [];
        for i = 1:numel(stud)
            if ~isequal(stud(i), soln(i))
                diffs = [diffs i];
            end
        end
        % if only one difference
        if length(diffs) == 1
            % check if all fields' values are primitives
            allPrimitives = true;
            for field = solnFields
                studValIsPrimitive = isPrim(stud.(field));
                solnValIsPrimitive = isPrim(soln.(field));
                if ~studValIsPrimitive || ~solnValIsPrimitive
                    allPrimitives = false;
                end
            end
            % if visualizable
            if allPrimitives && numel(studFields) <= 15
                htmlFeedback = sprintf(TABLE, visualizeStruct(soln), visualizeStruct(stud));
                if ~isscalar(stud)
                    htmlFeedback = sprintf(DIFF_ARR_VALUE, linear2Subscript(diffs, size(stud)), htmlFeedback);
                end
                return
            end
        end
        % TODO: difference it
        return
    end
        
%     if numel(stud) > 1
%         htmlFeedback = [];
%         % iterate over indices, call generateFeedback recursively to find
%         % differences at each position
%         % use linear indexing because number of dimensions is unknown;
%         % subscripts are reconstructed from index below
%         for i = 1:numel(stud)
%             stud_inner = stud(i);
%             soln_inner = soln(i);
%             feedback_inner = generateFeedback(stud_inner, soln_inner);
%             % if found a difference
%             if ~isequal(feedback_inner, PASSING)
%                 % cell array to store subscript indices for each dimension,
%                 % so that we can get all of ind2sub's vararg outputs
%                 % without knowing number of dimensions beforehand
%                 idx = cell(1,ndims(stud));
%                 [idx{:}] = ind2sub(size(stud),i);
%                 % convert indices to x separated string
%                 idx = strrep(num2str(cell2mat(idx)), '  ', 'x');
%                 % indent feedback_inner for improved readability
%                 feedback_inner = sprintf(INDENT_BLOCK, feedback_inner);
%                 % add to htmlFeedback
%                 msg = sprintf(DIFF_ARR_VALUE, idx, feedback_inner);
%                 if isempty(htmlFeedback)
%                     htmlFeedback = msg;
%                 else
%                     htmlFeedback = [htmlFeedback msg];
%                 end
%             end
%         end
        
    % case we didn't account for -> fallback message
    else
        htmlFeedback = sprintf(TABLE, ...
            matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(soln), ...
            matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(stud));
    end
    
    %% Generate string visualization of a primitive
    function str = visualizePrimitive(val)
        if ischar(val) && ismatrix(val) && all(size(val) <= [1 1000]) ...
            || isstring(val) && numel(strlength(val)) == 1 && strlength(val) <= 1000
            str = strcat('"', soln, '"');
        elseif isfloat(val) || isinteger(val)
            str = sprintf('%g', val);
        elseif islogical(val)
            bools = {'false', 'true'};
            str = bools{soln+1};
        end
    end

    %% Generate string/HTML visualization of an array
    function HTML = visualizeArray(val, isCell)
        
    end

    %% Generate string/HTML visualization of a structure
    function HTML = visualizeStruct(val)
        fields = sort(fieldnames);
        lines = cell(1, length(fields));
        for i = 1:length(fields)
            lines{i} = [fields{i} ': ' visualizePrimitive(val.(fields{i}))];
        end
        HTML = sprintf(['<p>struct with fields:</p>' INDENT_BLOCK], strjoin(lines, '<br>'));
    end

    %% Convert linearized index to subscript indices
    function linear2Subscript(linearIndx, arr)
        idx = cell(1, ndims(arr));
        [idx{:}] = ind2sub(size(arr), linearIndx);
        % convert indices to x separated string
        idx = strrep(num2str(cell2mat(idx)), '  ', 'x');
    end

    %% Check if value is a primitive
    function isPrim = isPrimitive(val)
        isPrim = isfloat(val) || isinteger(val) || ischar(val) ...
                    || isstring(val) || islogical(val);
    end

    %% 'Difference' the student and solution values
    function findDifference(stud, soln)
        % check if different class
        if ~isequal(class(soln), class(stud))
            htmlFeedback = sprintf(DIFF_CLASS, class(soln), class(stud));

        % check if equal
        % do after class check because isequaln(uint8(1),double(1)) is true
        elseif isequaln(soln, stud)
            htmlFeedback = PASSING;

        % check if same size
        elseif ~isequal(size(soln), size(stud))
            solnSize = strrep(num2str(size(soln)), '  ', 'x');
            studSize = strrep(num2str(size(stud)), '  ', 'x');
            htmlFeedback = sprintf(DIFF_DIM, solnSize, studSize);

        % check if not scalar (but excluding row vector of chars, i.e. strings)
        % if so, compare elements in the vector/array individually
        % because visual diff code for primitives expects scalars (apart from
        % row vectors of chars, which are easy to display)
        elseif numel(stud) > 1 && ...
            ~(ischar(stud) && ndims(stud) == 2 && size(stud, 1) == 1)
            htmlFeedback = [];
            % iterate over indices, call generateFeedback recursively to find
            % differences at each position
            % use linear indexing because number of dimensions is unknown;
            % subscripts are reconstructed from index below
            for i = 1:numel(stud)
                stud_inner = stud(i);
                soln_inner = soln(i);
                feedback_inner = generateFeedback(stud_inner, soln_inner);
                % if found a difference
                if ~isequal(feedback_inner, PASSING)
                    % cell array to store subscript indices for each dimension,
                    % so that we can get all of ind2sub's vararg outputs
                    % without knowing number of dimensions beforehand
                    idx = cell(1,ndims(stud));
                    [idx{:}] = ind2sub(size(stud),i);
                    % convert indices to x separated string
                    idx = strrep(num2str(cell2mat(idx)), '  ', 'x');
                    % indent feedback_inner for improved readability
                    feedback_inner = sprintf(INDENT_BLOCK, feedback_inner);
                    % add to htmlFeedback
                    msg = sprintf(DIFF_ARR_VALUE, idx, feedback_inner);
                    if isempty(htmlFeedback)
                        htmlFeedback = msg;
                    else
                        htmlFeedback = [htmlFeedback msg];
                    end
                end
            end

        % class-specific visual diffs
        elseif isfloat(stud) || isinteger(stud)
            htmlFeedback = sprintf(DIFF_NUM_VALUE, soln, stud);

        elseif ischar(stud) || isstring(stud)
            htmlFeedback = sprintf(DIFF_STR_VALUE, soln, stud);

        elseif isstruct(stud)
            % check if both structs have same fields
            solnFields = fieldnames(soln);
            studFields = fieldnames(stud);
            if ~isequal(sort(solnFields), sort(studFields))
                htmlFeedback = sprintf(DIFF_STC_FIELD, strjoin(solnFields, ','), ...
                    strjoin(studFields, ','));
            else
                htmlFeedback = [];
                % iterate over fields, call generateFeedback recursively on
                % values to find differences, even if nested
                for i = 1:length(studFields)
                    field = studFields{i};
                    stud_inner = stud.(field);
                    soln_inner = soln.(field);
                    feedback_inner = generateFeedback(stud_inner, soln_inner);
                    % if found a difference
                    if ~isequal(feedback_inner, PASSING)
                        % indent feedback_inner for improved readability
                        feedback_inner = sprintf(INDENT_BLOCK, feedback_inner);
                        % add to htmlFeedback
                        msg = sprintf(DIFF_STC_VALUE, field, feedback_inner);
                        if isempty(htmlFeedback)
                            htmlFeedback = msg;
                        else
                            htmlFeedback = [htmlFeedback msg];
                        end
                    end
                end
            end

        elseif iscell(stud)
            htmlFeedback = generateFeedback(stud{1}, soln{1});

        elseif islogical(stud)
            bools = {'false', 'true'};
            htmlFeedback = sprintf(DIFF_BOOL_VALUE, bools{soln+1}, bools{stud+1});

        % case we didn't account for -> fallback message
        else
            htmlFeedback = sprintf(DIFF_MISC_VALUE, ...
                matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(soln), ...
                matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(stud));
        end
    end
end