%% uploadToServer: Upload the student's submission files to the Server
%
% uploadToServer is responsible for uploading files to the CS 1371 Server
%
% uploadToServer(T, N, B, R, S, C) will upload the files for homework name N,
% using canvas token T. It will also update the progress bar B, and use any
% additional solution resources in the Resources supporting files object R.
% Finally, it will also upload student information (i.e., "names.json") and
% section information for canvas course C.
%
%%% Remarks
%
% This method is used to upload homework files to the CS 1371 website, so
% that the students can view regrades. As such, there should be NO FERPA
% data involved.
%
% N (the name) must be of the following format:
%
%   homework<NUM>[_resubmission].
%
% For example, homework 3 original would look like: homework03, and
% homework 11 resubmission would look like: homework11_resubmission.
%
%%% Exceptions
%
% This method, like all other networking methods, will throw an
% AUTOGRADER:networking:connectionError exception if interrupted.
%
%%% Unit Tests
%
%   T = 'Valid Token';
%   B = uiprogressdlg;
%   N = 'homework01';
%   uploadToServer(T, N, B);
%
%   Homework files are correctly uploaded
function uploadToServer(token, hwName, progress, resources)
    progress.Message = 'Uploading Homework Data to Server';
    progress.Value = 0;
    progress.Indeterminate = 'on';

    % we have parpool; just query canvas for TAs & Teachers, get sections
    % and GT Usernames, engage
    
    
    % Get name, id
    % No SFTP; just POST with data and path
    % get HW num
    num = hwName(hwName >= '0' & hwName <= '9');
    % Upload solutions
    solnFolder = [pwd filesep 'Solutions'];
    mkdir(hwName);
    newOGName = [pwd filesep hwName filesep 'hw' num 'Rubric.json'];
    newResubName = [pwd filesep hwName filesep 'hw' num 'Rubric_resub.json'];
    copyfile(solnFolder, hwName);
    % rename rubrics and upload
    % PROBLEM. We only have submission / resubmission.
    % we can't upload both!
    % Good news - only have to upload one
    if ~contains(hwName, 'resubmission')
        name = 'Supporting.zip';
        movefile(fullfile(pwd, hwName, 'rubric.json'), newOGName);
    else
        name = 'Supporting_Resub.zip';
        movefile(fullfile(pwd, hwName, 'rubric.json'), newResubName);
    end
    
    % Files to upload:
    %   Rubric.json
    %   Rubric_resub.json
    %   Supporting.zip
    %   Solution Files
    solns = dir([pwd filesep hwName filesep 'Solutions' filesep '*.m']);
    files = struct('path', cell(1, 2+numel(solns)), 'data', '');
    
    if ~contains(hwName, 'resubmission')
        [~, tmpName, ext] = fileparts(newOGName);
        files(1).path = ['regrades/rubrics/' tmpName ext];
        files(1).data = getData(newOGName);
    else
        [~, tmpName, ext] = fileparts(newResubName);
        files(1).path = ['regrades/rubrics/' tmpName ext];
        files(1).data = getData(newResubName);
    end

    zip([pwd filesep hwName filesep name], ...
        [pwd filesep hwName filesep 'SupportingFiles' filesep '*']);
    files(2).path = ['regrades/solutions/Homework' num '/' name];
    files(2).data = getData([pwd filesep hwName filesep name]);
    for n = 1:numel(solns)
        files(n+2).path = ['regrades/solutions/Homework' num '/' solns(n).name];
        files(n+2).data = getData([solns(n).folder filesep solns(n).name]);
    end
    offset = numel(files);
    % for each resource, get base bath by deleting
    % https://cs1371.gatech.edu/
    
    otherFiles = [resources.files];
    for n = numel(otherFiles):-1:1
        files(offset + n).path = strrep(otherFiles(n).dataURI, 'https://cs1371.gatech.edu/', '');
        files(offset + n).data = ...
            getData([pwd filesep hwName filesep 'SupportingFiles' filesep otherFiles(n).name]);
    end
    
    opts = weboptions;
    opts.ContentType = 'json';
    opts.RequestMethod = 'post';
    json = struct('token', token, 'files', {num2cell(files)});
    webwrite('https://cs1371.gatech.edu/uploader.php', json, opts);
    [~] = rmdir([pwd filesep hwName], 's');
end

function data = getData(path)
    fid = fopen(path, 'rb');
    base = matlab.net.base64encode(fread(fid));
    fclose(fid);
    data = ['data:application/octet-stream;base64,' base];
end