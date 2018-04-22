%% unzipArchive: Unzips an archive into a specified directory
%   
% unzipArchive unzips an archive into a folder, either creating a temporary
% folder or unzipping into the current folder. Returns the path of the
% unzipped archive.
%
% P = unzipArchive(Z) unzips the archive in path Z. P is a path that leads 
% to contents of the unzipped archive. This usage is guaranteed to never 
% overwrite any files.
%
% P = unzipArchive(Z, D) unzips the archive at path Z into the folder D,
% where D is an absolute or relative path. If D does not exist, it's
% created. The contents of the archive will be placed directly inside of
% folder D. If D is empty, it's equivalent to calling U = unzipArchive(Z).
% Regardless, the path to the unzipped contents is returned as P.
%
% P = unzipArchive(Z, D, X) does the same as P = unzipArchive(Z, D), except
% it will delete the original Zip Archive if X is true. If it's false, the
% original archive will not be deleted.
%
%%% Remarks
%
% If a destination is given, files and folders whose names conflict will be
% unconditionally deleted.
%
%%% Exceptions
%
% An AUTOGRADER:unzipArchive:invalidArchive exception will be thrown if the
% unzipping process returns an error. The specific reason will be attached
% as a cause. This includes if the destination does not exist, or if the
% given ZIP archive doesn't exist either.
%
%%% Unit Tests
%
%   Z = 'C:\...\archive.zip'; % valid ZIP
%   P = unzipArchive(Z);
%
%   P is a path. cd(P) will put you inside the unzipped contents.
%
%   Z = 'C:\...\archive.zip';
%   D = 'C:\Users\Public\test\'; % valid destination
%   P = unzipArchive(Z, D);
%
%   P is the same as D, where the unzipped contents have been placed
%
%   Z = 'C:\...\archive.zip';
%   D = []; % or D = '';
%   P = unzipArchive(Z, D);
%
%   P is a unique path. cd(P) will put you inside the unzipped contents.
%
%   Z = 'C:\...\archive.zip';
%   D = [];
%   X = true;
%   P = unzipArchive(Z, D, X);
%
%   P is a unique path. cd(P) will put you inside the unzipped contents.
%   Additionally, the archive at Z no longer exists.
%
%   All unzipping errors are caught and returned as an
%   AUTOGRADER:unzipArchive:invalidArchive exception
function outPath = unzipArchive(archivePath, outPath, deleteArchive)
    if exist(archivePath, 'file') ~= 2
        ME = MException('AUTOGRADER:unzipArchive:invalidArchive', ...
            'Archive "%s" not found', archivePath);
        throw(ME);
    end
    
    if nargin < 3
        deleteArchive = false;
    end
    if nargin < 2 || isempty(outPath)
        outPath = tempname;
    end
    outPath(outPath == '/' | outPath == '\') = filesep;
    if outPath(end) == filesep
        outPath(end) = [];
    end
    
    % Out directory shouldn't exist unless conflict
    if exist(outPath, 'dir') == 7
        rmdir(outPath, 's');
    end
    
    [status, ~] = system(['7z x ' archivePath ' -o' outPath]);
    if status ~= 0
        ME = MException('AUTOGRADER:unzipArchive:invalidArchive', ...
            'Error while unzipping "%s" to "%s"', archivePath, outPath);
        throw(ME);
    end
    
    contents = dir(outPath);
    contents(strncmp({contents.name}, '.', 1)) = [];
    if numel(contents) == 1 && contents.isdir
        movefile([outPath filesep contents.name filesep '*'], outPath);
        rmdir([outPath filesep contents.name]);
    end
    
    if deleteArchive
        delete(archivePath);
    end
end