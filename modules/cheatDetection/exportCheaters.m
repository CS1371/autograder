%% exportCheaters: Export cheating students and their data
%
% exportCheaters is used to export all the cheaters to a nice,
% human-readable format.
%
% exportCheaters(S, C, R, P, D, G) will use the student array S, cheater array
% C, score array R, problem name array P, directory path D, and progress bar G to export
% cheater code files to their respective folders.
%
%%% Remarks
%
% For each student, exportCheaters will create a folder for them. For each
% problem that they possibly cheated on, a folder for that problem is
% created. In that folder is their code file and the code files of anyone
% who likely cheated. Each code file is renamed to the id of the student.
%
% A folder is made for every student, regardless of whether or not it is
% likely they cheated. However, their "html" is just a blank page. This
% means that they can be linked to even if they did not cheat.
%
%%% Exceptions
%
% This function will never throw an exception
function exportCheaters(students, cheaters, scores, problems, path, progress)
    if ~isfolder(path)
        mkdir(path);
    end
    
    orig = cd(path);
    sections = unique({students.section});
    for s = 1:numel(sections)
        mkdir(pwd, sections{s});
    end
    mkdir('cheaters');
    progress.Message = 'Preparing to export';
    progress.Value = 0;
    % for each student, get worker
    mask = false(1, numel(students));
    for s = numel(students):-1:1
        sPath = [pwd filesep students(s).id];
        section = students(s).section;
        prettyName = [students(s).name ' (' students(s).id ')'];
        % construct names & paths
        for p = numel(problems):-1:1
            if isempty(cheaters{s}{p})
                names{p} = {};
                paths{p} = {};
                cScores{p} = {};
            else
                names{p} = [{cheaters{s}{p}.name, students(s).name}; {cheaters{s}{p}.id, students(s).id}];
                paths{p} = [cellfun(@(pSet)(pSet(p)), {cheaters{s}{p}.problemPaths}), students(s).problemPaths(p)];
                cScores{p} = scores{s}{p};
            end
        end
        if ~all(cellfun(@isempty, names))
            mask(s) = true;
        end
        workers(s) = parfeval(@exportStudent, 0, sPath, problems, names, paths, cScores, prettyName, section);
        progress.Value = min([progress.Value + 1/numel(students), 1]);
    end
    
    workers([workers.ID] == -1) = [];
    progress.Message = 'Exporting Student Code';
    progress.Indeterminate = 'on';
    % wait for up to 30 seconds; if we complete, good to go! Otherwise,
    % show progress
    
    suspects = students(mask);
    links = cell(size(suspects));
    for s = 1:numel(suspects)
        links{s} = {'<div class="row"><div class="col-12 text-center">', ['<a href="' suspects(s).id '.html">'], ...
            '<code>', [suspects(s).name ' (' suspects(s).id ')'], '</code>', '</a>', '</div></div>'};
    end
    HEADER = {'<!DOCTYPE html>', '<html>', '<head>', ...
            '<meta charset="utf-8">', ...
            '<meta name="viewport" content="width=device-width, initial-scale=1">', ...
            '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css">', ...
            '<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>', ...
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>', ...
            '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/js/bootstrap.min.js"></script>', ...
            '<title>', 'Code Comparison Details', '</title>', ...
            '</head>', '<body>', '<div class="container">', '<h1 class="text-center display-1">', ...
            'Code Comparison', '</h1>', '<div class="container-fluid">'};
    markup = [HEADER links{:} {'</div></div></body></html>'}];
    fid = fopen('index.html', 'wt');
    fwrite(fid, strjoin(markup, newline));
    fclose(fid);
    % create section index.html
    sections = unique({suspects.section});
    for sec = 1:numel(sections)
        % create index.html
        % get links for that section
        sectionMask = strcmp({suspects.section}, sections{sec});
        sectionLinks = links(sectionMask);
        sectionMarkup = [HEADER sectionLinks{:} {'</div></div></body></html>'}];
        fid = fopen(fullfile(pwd, sections{sec}, 'index.html'), 'wt');
        fwrite(fid, strjoin(sectionMarkup, newline));
        fclose(fid);
    end
    isDone = wait(workers, 'finished', 30);
    if ~isDone
        progress.Indeterminate = 'off';
        progress.Value = 0;
        while ~all([workers.Read])
            workers.fetchNext();
            progress.Value = min([progress.Value + 1/numel(workers), 1]);
        end
    end
    cd(orig);
end

function exportStudent(studentPath, problems, names, paths, scores, prettyName, section)
    % for each problem in problems, export the files
    [~, myName, ~] = fileparts(studentPath);

    myPaths = cell(1, numel(problems));
    for p = 1:numel(problems)
        if ~isempty(names{p})
            % get real myName
            myPaths{p} = paths{p}{strcmp(names{p}(2, :), myName)};
            paths{p}(strcmp(names{p}(2, :), myName)) = [];
            names{p}(:, strcmp(names{p}(2, :), myName)) = [];
        end
    end
    % create HTML file
    writeHtml(problems, names, scores, prettyName, myName, section, myPaths, paths);
    
end

function writeHtml(problems, names, scores, myName, myUsername, mySection, myPaths, paths)
    % for each problem, capture it
    didCheat = false;
    problemMarkup = cell(size(problems));
    for p = 1:numel(problems)
        if ~isempty(names{p})
            didCheat = true;
            fid = fopen(myPaths{p}, 'rt');
            myCode = char(fread(fid)');
            fclose(fid);
            try
                myCodeStyled = webwrite('http://hilite.me/api', 'code', myCode, 'lexer', 'matlab', 'style', 'vs', 'divstyles', '');
            catch
                myCode = strrep(myCode, '&', '&amp;');
                myCode = strrep(myCode, '<', '&lt;');
                myCode = strrep(myCode, '>', '&gt;');
                myCodeStyled = ['<pre>' myCode '</pre>'];
            end
            list = cell(1, size(names{p}, 2));
            [~, inds] = sort(scores{p});
            inds = inds(end:-1:1);
            scores{p} = scores{p}(inds);
            paths{p} = paths{p}(inds);
            names{p} = names{p}(:, inds);
            for n = 1:size(names{p}, 2)
                if scores{p}(n) == Inf
                    tmp = {['<a class="text-danger" href="' names{p}{2, n} '.html">'], ...
                        [names{p}{1, n} ' (' names{p}{2, n} ') - Exact Match'], '</a>'};
                else
                    tmp = {['<a href="' names{p}{2, n} '.html">'], ...
                        [names{p}{1, n} ' (' names{p}{2, n} ') - ' sprintf('%0.2f', 100*scores{p}(n)) '% Match'], '</a>'};
                end
                % this won't ever be on a phone, so we don't have to worry
                % about wrapping
                tag = [{'<div class="cheater">', '<button class="show-cheater-comparison btn btn-warning">', ...
                    'Show Code Comparison', '</button>'}, tmp];
                fid = fopen(paths{p}{n}, 'rt');
                code = char(fread(fid)');
                fclose(fid);
                try
                    codeStyled = webwrite('http://hilite.me/api', 'code', code, 'lexer', 'matlab', 'style', 'vs', 'divstyles', '');
                catch
                    code = strrep(code, '&', '&amp;');
                    code = strrep(code, '<', '&lt;');
                    code = strrep(code, '>', '&gt;');
                    codeStyled = ['<pre>' code '</pre>'];
                end
                list{n} = [tag, {'<div class="cheater-comparison d-none">', ...
                    '<div class="row">', '<div class="col-6">', ['<h3 class="text-center">' myName '</h3>'], ...
                    '</div>', '<div class="col-6">', ['<h3 class="text-center">' names{p}{1, n} ' (' names{p}{2, n} ')</h3>'], ...
                    '</div>', '</div>', '<div class="row">', '<div class="col-6">', ...
                    myCodeStyled, '</div>', '<div class="col-6">', ...
                    codeStyled, '</div>', '</div>', '</div>', '<div>'}];
            end
            problemMarkup{p} = [{'<hr />', '<div class="problem-header row"><div class="col-12">', ...
                ['<h2><pre>' problems{p} '</pre></h2></div></div><div class="problem row"><div class="col-12">'], ...
                '<div class="problem-cheaters">'}, list{:}, {'</div>', '</div></div>'}];
        end
    end
    if ~isempty(myName)
        
        problemMarkup = [problemMarkup{:}];
        HEADER = {'<!DOCTYPE html>', '<html lang="en">', '<head>', ...
            '<meta charset="utf-8">', ...
            '<meta name="viewport" content="width=device-width, initial-scale=1">', ...
            '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css">', ...
            '<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>', ...
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>', ...
            '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/js/bootstrap.min.js"></script>', ...
            '<script defer src="https://use.fontawesome.com/releases/v5.0.13/js/all.js"></script>', ...
            '<script>', ...
            '    $(document).ready(function() {', ...
            '        $(".show-cheater-comparison").click(function() {', ...
            '            $(this).next().next().toggleClass("d-none");', ...
            '            if ($(this).next().next().hasClass("d-none")) {', ...
            '                $(this).text("Show Code Comparison");', ...
            '            } else {', ...
            '                $(this).text("Hide Code Comparison");', ...
            '            }', ...
            '        });', ...
            '    });', ...
            '</script>', ...
            '<style>', ...
            '    .show-cheater-comparison {', ...
            '        margin: 2px;', ...
            '    }', ...
            '    .main-page {', ...
            '        margin-left: 2%;', ...
            '        margin-right: 2%;', ...
            '    }', ...
            '    body {', ...
            '        max-width: 95%;', ...
            '    }', ...
            '</style>', ...
            '<title>', ['Code Comparison for ' myName], '</title>', ...
            '<style>', 'code a {color: #e83e8c; font-size: 100%;}', '</style>', '</head>', '<body>', '<div class="container-fluid">', '<h1 class="display-3 text-center">', ...
            ['Code Comparison for ' myName], '</h1>', '</div>', '<div class="container-fluid main-page">'};
        markup = [HEADER problemMarkup {'</div>', '</body>', '</html>'}];
        fid = fopen([myUsername '.html'], 'wt');
        fwrite(fid, strjoin(markup, newline));
        fclose(fid);
        % if we cheated, copy to section folder & cheaters folder
        if didCheat
            fid = fopen([pwd filesep mySection filesep myUsername '.html'], 'wt');
            fwrite(fid, strjoin(markup, ''));
            fclose(fid);
            fid = fopen([pwd filesep 'cheaters' filesep myUsername '.html'], 'wt');
            fwrite(fid, strjoin(markup, ''));
            fclose(fid);
        end
    end
end