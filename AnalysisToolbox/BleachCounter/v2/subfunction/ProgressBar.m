classdef ProgressBar < handle
    % Description:
    %   progressbar() provides an indication of the progress of some task using
    % graphics and text. Calling progressbar repeatedly will update the figure and
    % automatically estimate the amount of time remaining.
    %   This implementation of progressbar is intended to be extremely simple to use
    % while providing a high quality user experience.
    %
    % Features:
    %   - Can add progressbar to existing m-files with a single line of code.
    %   - Supports multiple bars in one figure to show progress of nested loops.
    %   - Optional labels on bars.
    %   - Figure closes automatically when task is complete.
    %   - Only one figure can exist so old figures don't clutter the desktop.
    %   - Remaining time estimate is accurate even if the figure gets closed.
    %   - Minimal execution time. Won't slow down code.
    %   - Randomized color. When a programmer gets bored...
    %
    % Example Function Calls For Single Bar Usage:
    %   progressbar               % Initialize/reset
    %   progressbar(0)            % Initialize/reset
    %   progressbar('Label')      % Initialize/reset and label the bar
    %   progressbar(0.5)          % Update
    %   progressbar(1)            % Close
    %
    % Example Function Calls For Multi Bar Usage:
    %   progressbar(0, 0)         % Initialize/reset two bars
    %   progressbar('A', '')      % Initialize/reset two bars with one label
    %   progressbar('', 'B')      % Initialize/reset two bars with one label
    %   progressbar('A', 'B')     % Initialize/reset two bars with two labels
    %   progressbar(0.3)          % Update 1st bar
    %   progressbar(0.3, [])      % Update 1st bar
    %   progressbar([], 0.3)      % Update 2nd bar
    %   progressbar(0.7, 0.9)     % Update both bars
    %   progressbar(1)            % Close
    %   progressbar(1, [])        % Close
    %   progressbar(1, 0.4)       % Close
    %
    % Notes:
    %   For best results, call progressbar with all zero (or all string) inputs
    % before any processing. This sets the proper starting time reference to
    % calculate time remaining.
    %   Bar color is choosen randomly when the figure is created or reset. Clicking
    % the bar will cause a random color change.
    %
    % Demos:
    %     % Single bar
    %     m = 500;
    %     progressbar % Init single bar
    %     for i = 1:m
    %       pause(0.01) % Do something important
    %       progressbar(i/m) % Update progress bar
    %     end
    %
    %     % Simple multi bar (update one bar at a time)
    %     m = 4;
    %     n = 3;
    %     p = 100;
    %     progressbar(0,0,0) % Init 3 bars
    %     for i = 1:m
    %         progressbar([],0) % Reset 2nd bar
    %         for j = 1:n
    %             progressbar([],[],0) % Reset 3rd bar
    %             for k = 1:p
    %                 pause(0.01) % Do something important
    %                 progressbar([],[],k/p) % Update 3rd bar
    %             end
    %             progressbar([],j/n) % Update 2nd bar
    %         end
    %         progressbar(i/m) % Update 1st bar
    %     end
    %
    %     % Fancy multi bar (use labels and update all bars at once)
    %     m = 4;
    %     n = 3;
    %     p = 100;
    %     progressbar('Monte Carlo Trials','Simulation','Component') % Init 3 bars
    %     for i = 1:m
    %         for j = 1:n
    %             for k = 1:p
    %                 pause(0.01) % Do something important
    %                 % Update all bars
    %                 frac3 = k/p;
    %                 frac2 = ((j-1) + frac3) / n;
    %                 frac1 = ((i-1) + frac2) / m;
    %                 progressbar(frac1, frac2, frac3)
    %             end
    %         end
    %     end
    %
    % Author:
    %   Steve Hoelzer
    %
    % Revisions:
    % 2002-Feb-27   Created function
    % 2002-Mar-19   Updated title text order
    % 2002-Apr-11   Use floor instead of round for percentdone
    % 2002-Jun-06   Updated for speed using patch (Thanks to waitbar.m)
    % 2002-Jun-19   Choose random patch color when a new figure is created
    % 2002-Jun-24   Click on bar or axes to choose new random color
    % 2002-Jun-27   Calc time left, reset progress bar when fractiondone == 0
    % 2002-Jun-28   Remove extraText var, add position var
    % 2002-Jul-18   fractiondone input is optional
    % 2002-Jul-19   Allow position to specify screen coordinates
    % 2002-Jul-22   Clear vars used in color change callback routine
    % 2002-Jul-29   Position input is always specified in pixels
    % 2002-Sep-09   Change order of title bar text
    % 2003-Jun-13   Change 'min' to 'm' because of built in function 'min'
    % 2003-Sep-08   Use callback for changing color instead of string
    % 2003-Sep-10   Use persistent vars for speed, modify titlebarstr
    % 2003-Sep-25   Correct titlebarstr for 0% case
    % 2003-Nov-25   Clear all persistent vars when percentdone = 100
    % 2004-Jan-22   Cleaner reset process, don't create figure if percentdone = 100
    % 2004-Jan-27   Handle incorrect position input
    % 2004-Feb-16   Minimum time interval between updates
    % 2004-Apr-01   Cleaner process of enforcing minimum time interval
    % 2004-Oct-08   Seperate function for timeleftstr, expand to include days
    % 2004-Oct-20   Efficient if-else structure for sec2timestr
    % 2006-Sep-11   Width is a multiple of height (don't stretch on widescreens)
    % 2010-Sep-21   Major overhaul to support multiple bars and add labels
    % 12/06/09(CPR) Implemented as Class. Support for multiple parallel Bars.
    
    properties(Hidden,Transient)
        hFig
        hAx
        hPatch
        hText
        hLabel
        
        StartTime
        FractionDone
        ProcessClock
        LastUpdate
        
        NumBars
        
        objLoop
        LoopValue
        
        IsInterruptable
        InterruptProcess = 0;
    end %properties
    
    events
        UpdateProgressbar
    end
    
    methods
        function this = ProgressBar(barInfo,varargin)
            %input validation
            objInputParser = inputParser;
            addParamValue(objInputParser,...
                'IsInterruptable', false, @(x)islogical(x));
            parse(objInputParser,varargin{:});
            inputs = objInputParser.Results;
            
            this.IsInterruptable = inputs.IsInterruptable;
            
            % Define figure size and axes padding for the single bar case
            height = 0.1; %CPR 12/06/07
            width = height * 8;
            hpad = 0.02;
            vpad = 0.25;
            
            % Figure out how many bars to draw
            this.NumBars = numel(barInfo);
            
            % Adjust figure size and axes padding for number of bars
            heightfactor = (1 - vpad) * this.NumBars + vpad;
            height = height * heightfactor;
            vpad = vpad / heightfactor;
            
            % Initialize progress bar figure
            left = (1 - width) / 2;
            bottom = (1 - height) / 2;
            this.hFig = figure(...
                'Units', 'normalized',...
                'Position', [left bottom width height],...
                'NumberTitle', 'off',...
                'Resize', 'off',...
                'DockControls', 'off',...
                'ToolBar', 'none',...
                'MenuBar', 'none' ,...
                'IntegerHandle', 'off',...
                'CloseRequestFcn', @(src,evnt)break_process(this));
            
            % Initialize axes, patch, and text for each bar
            left = hpad;
            width = 1 - 2*hpad;
            vpadtotal = vpad * (this.NumBars + 1);
            height = (1 - vpadtotal) / this.NumBars;
            for ndx = 1:this.NumBars
                % Create axes, patch, and text
                bottom = vpad + (vpad + height) * (this.NumBars - ndx);
                this.hAx(ndx) = axes( ...
                    'Position', [left bottom width height], ...
                    'XLim', [0 1], ...
                    'YLim', [0 1], ...
                    'Box', 'on', ...
                    'ytick', [], ...
                    'xtick', [] );
                this.hPatch(ndx) = patch( ...
                    'XData', [0 0 0 0], ...
                    'YData', [0 0 1 1],...
                    'FaceColor', [1 0.5 0.5]);
                this.hText(ndx) = text(0.99, 0.5, '', ...
                    'HorizontalAlignment', 'Right', ...
                    'FontUnits', 'Normalized', ...
                    'FontSize', 0.7 );
                this.hLabel(ndx) = text(0.01, 0.5, '', ...
                    'HorizontalAlignment', 'Left', ...
                    'FontUnits', 'Normalized', ...
                    'FontSize', 0.7 );
                if ischar(barInfo{ndx})
                    set(this.hLabel(ndx), 'String', barInfo{ndx})
                    barInfo{ndx} = 0;
                end
                
                % Set starting time reference
                this.StartTime(ndx,:) = clock;
            end
            % Set time of last update to ensure a redraw
            this.LastUpdate = clock - 1;
            
            update_progressbar(this,barInfo)
        end
        
        function update_progressbar(this,barInfo)
            %bring progressbar to front
%             figure(this.hFig)
            
            % Process inputs and update state of progdata
            for ndx = 1:this.NumBars
                if ~isempty(barInfo{ndx})
                    this.FractionDone(ndx) = barInfo{ndx};
                    this.ProcessClock(ndx,:) = clock;
                end
            end
            
            % Enforce a minimum time interval between graphics updates
            myclock = clock;
            if abs(myclock(6) - this.LastUpdate(6)) < 0.01 % Could use etime() but this is faster
                return
            end
            
            % Update progress patch
            for ndx = 1:this.NumBars
                set(this.hPatch(ndx), 'XData', ...
                    [0, this.FractionDone(ndx), this.FractionDone(ndx), 0])
            end
            
            % Update progress text if there is more than one bar
            if this.NumBars > 1
                for ndx = 1:this.NumBars
                    set(this.hText(ndx), 'String', ...
                        sprintf('%1d%%', floor(100*this.FractionDone(ndx))))
                end
            end
            
            % Update progress figure title bar
            if this.FractionDone(1) > 0
                runtime = etime(this.ProcessClock(1,:), this.StartTime(1,:));
                timeleft = runtime / this.FractionDone(1) - runtime;
                timeleftstr = ProgressBar.sec2timestr(timeleft);
                titlebarstr = sprintf('%2d%%    %s remaining', ...
                    floor(100*this.FractionDone(1)), timeleftstr);
            else
                titlebarstr = ' 0%';
            end
            set(this.hFig, 'Name', titlebarstr)
            
            % Force redraw to show changes
            drawnow
            
            % Record time of this update
            this.LastUpdate = clock;
        end
        
        function start_loop(this,delay)
            this.LoopValue = 0;
            this.objLoop = timer('TimerFcn',...
                @(src,evnt)update_loop(this), 'Period', delay,...
                'ExecutionMode','fixedDelay','BusyMode','queue');
            start(this.objLoop)
        end %fun
        function update_loop(this)
            if this.LoopValue >= 1
                this.LoopValue = 0;
            else
                this.LoopValue = this.LoopValue + 0.01;
            end %if
            
            update_progressbar(this,{this.LoopValue})
            %             set(this.hFig,'Title','')
        end %fun
        function stopp_loop(this)
            stop(this.objLoop)
            delete(this.objLoop)
        end %fun
        
        function break_process(this)
            if this.IsInterruptable
                answer = questdlg('Are you sure to interrupt the current process?',...
                    '','Yes','No','No');
                if strcmp(answer,'Yes')
                    this.InterruptProcess = 1;
                end %if
            else
                waitfor(warndlg('Process interruption not supported','','modal'))
            end %if
        end %fun
        function interruptProcess = check_for_process_interruption(this)
            interruptProcess = this.InterruptProcess;
        end %fun
        
        function close_progressbar(this)
            delete(this.hFig)
        end %fun
    end %methods
    
    methods(Static)
        function timestr = sec2timestr(sec)
            % Convert a time measurement from seconds into a human readable string.
            
            % Convert seconds to other units
            w = floor(sec/604800); % Weeks
            sec = sec - w*604800;
            d = floor(sec/86400); % Days
            sec = sec - d*86400;
            h = floor(sec/3600); % Hours
            sec = sec - h*3600;
            m = floor(sec/60); % Minutes
            sec = sec - m*60;
            s = floor(sec); % Seconds
            
            % Create time string
            if w > 0
                if w > 9
                    timestr = sprintf('%d week', w);
                else
                    timestr = sprintf('%d week, %d day', w, d);
                end
            elseif d > 0
                if d > 9
                    timestr = sprintf('%d day', d);
                else
                    timestr = sprintf('%d day, %d hr', d, h);
                end
            elseif h > 0
                if h > 9
                    timestr = sprintf('%d hr', h);
                else
                    timestr = sprintf('%d hr, %d min', h, m);
                end
            elseif m > 0
                if m > 9
                    timestr = sprintf('%d min', m);
                else
                    timestr = sprintf('%d min, %d sec', m, s);
                end
            else
                timestr = sprintf('%d sec', s);
            end
        end
    end %methods
end %classdef