%% File: Represent a file
%
% This class helps in storing and comparing files.
%
%%% Fields
%
% * name: The filename for the file, without extension
%
% * extension: The file extension
%
% * data: One of the following:
%		- MxNx3 uint8 image
%		- Character vector of file data
%		- Cell array for raw Excel output
%
%%% Methods
%
% * equals
%
% * generateFeedback
%
%%% Remarks
%
% The File class represents all files possibly generated by a student's
% (or solution's) code. A File Object can be created by the constructor,
% which receives a path to the file to create.
%
% **Once the File object is created, the original file can safely be
% deleted from disk.** The File class holds all the information needed
% to compare two files internally, so there is actually no link to the
% original file.
%
classdef File < handle
    properties (Access = public)
        name; %will be class char
        extension; %will be class char
        data; %will vary in file type
    end
    properties (Access = public)
        TXT = {'txt', 'm', 'rtf', 'html'};
        EXCEL = {'xls', 'xlsx', 'csv'};
        IMAGES;
    end
    methods
        function val = get.IMAGES(~)
            tmp = imformats;
            val = [tmp.ext];
        end
        function this = File(path)
            %% Constructor: Create a File object from a path
            %
            % Represents a generated file and it's contents
            %
            % this = File(P) where P is a path for a specific file, will
            % generate a new File object with that file's data, name, and
            % extension.
            %
            %%% Remarks
            %
            % This function uses imformats. If you've changed it, it might not
            % work.
            %
            %%% Exceptions
            %
            % An AUTOGRADER:File:ctor:invalidPath exception will be thrown if
            % the given path isn't a valid file.
            %
            % An AUTOGRADER:File:ctor:invalidExtension exception will be thrown
            % if the extension isn't readable.
            %
            %%% Unit Tests
            %
            %   P = 'C:\Users\...\test.txt'; % valid path
            %   this = File(P);
            %
            %   File.name -> 'test'
            %   File.extension -> '.txt'
            %   File.data -> data (a char vector)
            %
            %   P = ''; % invalid path
            %   this = File(P);
            %
            %   threw invalidPath exception
            %
            %   P = 'C:\test.fdasfdsa'; % invalid file extension
            %   this = File(P);
            %
            %   threw invalidExtension exception
            %
            %   P = 'C:\test\e.xls'; % valid file
            %   this = File(P);
            %
            %   this.name -> 'e';
            %   this.extension -> '.xls'
            %   this.data -> cell array of raw output
            %
            %   P = 'C:\test\img.png'; % valid file
            %   this = File(P);
            %
            %   this.name -> 'img'
            %   this.extension -> '.png'
            %   this.data -> uint MxNx3 array
            %
            if nargin == 0
                return;
            end
            
            %Parse the path input into the proper parts
            [~, name, ext] = fileparts(path);
            
            %store info in File
            
            this.name = name;
            this.extension = ext;
            %depending on the ext, extract the information
            %for images, imformats will be used for the potential cases
            %because we are using imformats, we will remove the periods
            %from the variable stored in ext when you use the
            %switch statements
            switch ext(2:end)
                case this.TXT %read data in and create a vertical string vector
                    %In standard practice, using the string class to extract the
                    %contents of a text file would be preferable. Most TAs,
                    %however, would be more comfortable with cell arrays, so
                    %this is the method chosen.
                    %fh = fopen(name);
                    %line = fgetl(fh);
                    %data = {};
                    %while ischar(line)
                    %    data = [data; {line}];
                    %    line = fgetl(fh);
                    %end
                    %fclose(fh);
                    %File.data = data;
                    
                    %The above method is too slow since it iteratively
                    %concatenates; the superior method would be to use
                    %preallocating. However, Matlab makes even
                    %preallocating look lame af in the presence of the
                    %glorious fread function.
                    fid = fopen(name, 'rt');
                    this.data = char(fread(fid)');
                    fclose(fid);
                case this.IMAGES
                    %read in image array and store in File class
                    this.data = imread(name);
                case this.EXCEL
                    [~,~,this.data] = xlsread(name);
            end
        end
    end
    methods (Static)
        function s = SENTINEL()
            persistent name;
            if isempty(name)
                name = [tempname '.lock'];
                fid = fopen(name, 'wt');
                fwrite(fid, 'SENTINEL');
                fclose(fid);
            end
            s = name;
        end
    end
    methods (Access = public)
        function [isEqual] = equals(this, soln)
            %% equals: Determine file equality
            %
            % Checks if this file object is equal to anSOLN (containing same name,
            % extension, and data).
            %
            % [I] = equals(T,S) checks whether this file T is equal to
            % solution S. If T and S have the same name, extension, and data,
            % I is true; otherwise, it's false.
            %
            %%% Remarks
            %
            % The order doesn't actually matter, although it's assumed the
            % solution is given as an input.
            %
            %%% Exceptions
            %
            % This method will not throw an exception
            %
            %%% Unit Tests
            %
            %    Given that F is a valid File instance that is equal to THIS:
            %    [I] = equals(F)
            %
            %	 I -> true;
            %
            %    If B is a valid File instance with one or more fields not equal
            %    to the fields of THIS:
            %	 [I] = equals(B)
            %
            %	 I -> false;
            %
            
            %extract the data from classes, compare name and extension
            isName = strcmp(this.name,soln.name);
            isExt = strcmp(this.extension,soln.extension);
            isData = isequal(this.data,soln.data);
            %output whether all portions are true or not

            isEqual = isName && isExt && isData;
           
                
        end
        function [html] = generateFeedback(this, soln)
            %% generateFeedback: Generate HTML feedback for students
            %
            % Create an HTML page for the student based on the solution File object.
            %
            % [HTML] = generateFeedback(SOLN) creates a feedback file containing
            % information the equality of THIS and SOLN, where THIS and SOLN are both
            % type File. If SOLN is a text file, HTML contains a visdiff() of the two
            % files. If SOLN is an image, the Image Comparison Tool will be used. If
            % SOLN is an Excel file, both files will be compared via their
            % output cell arrays (using xlsread);
            %
            %%% Remarks
            %
            % The HTML generated by this method is used within the Student class to
            % generate the broader Student Feedback file.
            %
            %%% Exceptions
            %
            %
            %
            %%% Unit Tests
            %
            %    Given that F is a valid File instance that is equal to THIS:
            %    [OUT] = generateFeedback(THIS, F)
            %
            %	 OUT will contain HTML describing that THIS and F are equal files.
            %
            %    Given that B is a valid File instance that is not equal to THIS:
            %	 [OUT] = generateFeedback(this, B)
            %
            %	 OUT will contain HTML describing that THIS and B are not the same.
            %
            %below, my code is uncertain as of this moment.
            %Check out what data type is soln
            switch lower(this.extension(2:end))
                case this.TXT
                    studPath = [tempname this.extension];
                    solnPath = [tempname soln.extension];
                    fid = fopen(studPath, 'wt');
                    fwrite(fid, this.data);
                    fclose(fid);
                    fid = fopen(solnPath, 'wt');
                    fwrite(fid, soln.data);
                    fclose(fid);
                    html = visdiff(studPath, solnPath, 'text');
                    html = strrep(html, 'Student File');
                    html = strrep(html, 'Solution File');
                    startInd = strfind(html, '<title>');
                    endInd = strfind(html, '</title>');
                    startInd = startInd(1) + length('<title>');
                    endInd = endInd(1) - 1;
                    html = [html(1:startInd), 'Comparison of Student and Solution Files' html(endInd:end)];
                case this.IMAGES
                    html = '<div class="row image-feedback">';
                    html = [html '<div class="col-md-6 text-center student-image">'];
                    studImg = img2base64(this.data);
                    solnImg = img2base64(soln.data);
                    html = [html '<img class="img-thumbnail rounded img-fluid" src="%s">'];
                    html = [html '</div><div class="col-md-6 text-center soln-image">'];
                    html = [html '<img class="img-thumbnail rounded img-fluid" src="%s">'];
                    html = [html '</div></div>'];
                    html = sprint(html, studImg, solnImg);
                case this.EXCEL
                    html = generateFeedback(this.data, soln.data);
                otherwise
                    html = '<p class="unknown">Unknown File Extension "%s"</p>';
                    html = sprintf(html, this.extension);
            end  
        end
    end
end
%Code Written by: Tobin K Abraham