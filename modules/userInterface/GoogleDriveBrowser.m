%% GoogleDriveBrowser: Graphically Browse your Google Drive
%
% The GoogleDriveBrowser allows the user to graphically browse his or her
% Google Drive - only "My Drive" (root) is used.
classdef GoogleDriveBrowser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure  matlab.ui.Figure
        Select    matlab.ui.control.Button
        Cancel    matlab.ui.control.Button
        Title     matlab.ui.control.Label
        Drive     matlab.ui.container.Tree
    end


    properties (Access = private)
        refreshServer char = 'https://www.googleapis.com/oauth2/v4/token';
        clientId char = '';
        clientSecret char = '';
        grantType char = 'refresh_token';
        driveUrl char = 'https://www.googleapis.com/drive/v2';
        baseApp Autograder;
        refreshToken char;
        accessToken char;
    end

    methods (Access = private)
    
        function folders = getFolders(app, id) % throws!
            opts = weboptions('RequestMethod', 'GET');
            opts.HeaderFields = {'Authorization', ['Bearer ' app.accessToken]};
            
            searchTerm = ['''' id ''' in parents and trashed = false and mimeType = ''application/vnd.google-apps.folder'''];
            folders = webread([app.driveUrl '/files'], 'q', searchTerm, opts);
            names = cell(1, numel(folders.items));
            if isstruct(folders.items)
                folders.items = num2cell(folders.items);
            end
            for n = 1:numel(names)
                names{n} = folders.items{n}.title;
            end
            [~, ind] = sort(names);
            folders = folders.items(ind);
                
        end
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, base)
            app.baseApp = base;
            app.refreshToken = app.baseApp.driveToken;
            app.clientId = app.baseApp.googleClientId;
            app.clientSecret = app.baseApp.googleClientSecret;
            % Exchange refresh token for access token
            app.accessToken = refresh2access(app.refreshToken, app.clientId, app.clientSecret);
            % Get all folders underneath root
            folders = app.getFolders('root');
            % Display root
            root = uitreenode(app.Drive, 'Text', 'My Drive', 'NodeData', 'root');
            % For each one, display it
            for f = 1:numel(folders)
                folder = folders{f};
                fld = uitreenode(root, 'Text', folder.title, 'NodeData', folder.id);
                uitreenode(fld, 'Text', 'Loading...', 'NodeData', -1);
            end
            
        end

        % Button pushed function: Select
        function SelectButtonPushed(app, ~)
            app.baseApp.driveFolderId = app.Drive.SelectedNodes(1).NodeData;
            uiresume(app.UIFigure);
        end

        % Node expanded function: Drive
        function DriveNodeExpanded(app, event)
            node = event.Node;
            app.Drive.Enable = false;
            delete(node.Children);
            id = node.NodeData;
            try
                folders = app.getFolders(id);
            catch
                uialert(app.baseApp.UIFigure, 'Unable to connect to Google Drive', 'Drive Error');
                uiresume(app);
                return;
            end
            for f = 1:numel(folders)
                folder = folders{f};
                fld = uitreenode(node, 'Text', folder.title, 'NodeData', folder.id);
                uitreenode(fld, 'Text', 'Loading...', 'NodeData', -1);
            end
            app.Drive.Enable = true;
        end

        % Button pushed function: Cancel
        function CancelButtonPushed(app, ~)
            uiresume(app.UIFigure);
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Solution Selector';

            % Create Select
            app.Select = uibutton(app.UIFigure, 'push');
            app.Select.ButtonPushedFcn = createCallbackFcn(app, @SelectButtonPushed, true);
            app.Select.Position = [356 30 128 47];
            app.Select.Text = 'Select';

            % Create Cancel
            app.Cancel = uibutton(app.UIFigure, 'push');
            app.Cancel.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.Cancel.Position = [179 30 126 47];
            app.Cancel.Text = 'Cancel';

            % Create Title
            app.Title = uilabel(app.UIFigure);
            app.Title.FontSize = 20;
            app.Title.FontWeight = 'bold';
            app.Title.Position = [18 454 605 27];
            app.Title.Text = 'Please select the grader folder for this homework submission';

            % Create Drive
            app.Drive = uitree(app.UIFigure);
            app.Drive.NodeExpandedFcn = createCallbackFcn(app, @DriveNodeExpanded, true);
            app.Drive.Position = [18 128 605 300];
        end
    end

    methods (Access = public)

        % Construct app
        function app = GoogleDriveBrowser(varargin)

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end