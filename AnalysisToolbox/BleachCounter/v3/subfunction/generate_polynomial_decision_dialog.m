function output = generate_polynomial_decision_dialog(title,string,option,varargin)
UI = struct(...
    'Margin',30,... %[px]
    'ButtonBarHeight', 100,... %[px]
    'ButtonWidth', 200,...
    'ButtonHeight', 50,...
     'IconSize',100,... %[px]
    'FontUnits','points',...
    'FontName','FixedWidth',...
    'FontAngle','normal',...
    'FontSize',20,...
    'FontWeight','normal');

IP = inputParser;
IP.KeepUnmatched = true;
addParamValue(IP,...
    'FontUnits', UI.FontUnits, @(x)isnumeric(x));
addParamValue(IP,...
    'FontName', UI.FontName, @(x)ischar(x));
addParamValue(IP,...
    'FontAngle', UI.FontAngle, @(x)ischar(x));
addParamValue(IP,...
    'FontSize', UI.FontSize, @(x)isnumeric(x));
addParamValue(IP,...
    'FontWeight', UI.FontWeight, @(x)ischar(x));
addParamValue(IP,...
    'IsModal', true, @(x)islogical(x));
parse(IP,varargin{:});
inputs = IP.Results;

if iscell(string)
    numString = numel(string);
    [stringWidth,stringHeight] = deal(zeros(numString,1));
    for idxString = 1:numString
        [stringWidth(idxString),stringHeight(idxString)] = ...
            get_text_extent(string{idxString},varargin{:});
    end %for
else
    numString = 1;
    [stringWidth,stringHeight] = ...
        get_text_extent(string,varargin{:});
end %for
scrSize = get(0, 'ScreenSize');
%             if max(stringExtent) > scrSize(3)
%                 %cut string
%             end %if

numOption = numel(option);

axWidth = max(numOption*(UI.ButtonWidth+UI.Margin),...
    max(stringWidth)+2*UI.Margin);
figWidth = axWidth+UI.IconSize;
axHeight = sum(stringHeight)+2*UI.Margin;
figHeight = axHeight+UI.ButtonBarHeight;
UI.hFig =...
    figure(...
    'Units','pixels',...
    'Position',[0.5*(scrSize(3)-figWidth),0.5*(scrSize(4)-figHeight),figWidth,figHeight],...
    'Name', title,...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'DockControls', 'off',...
    'Resize', 'off',...
    'IntegerHandle','off',...
    'Color', [1 1 1],...
    'CloseRequestFcn',@(src,evnt)respond_to_closed_by_figure,...
    'Visible','off');
if inputs.IsModal
    set(UI.hFig,...
        'WindowStyle','modal')
end %if

hAx = axes(...
    'Parent',UI.hFig,...
    'Units','pixels',...
    'Position',[UI.Margin+UI.IconSize+1,UI.ButtonBarHeight+1,...
    axWidth,axHeight],...
    'Visible','off');

y0 = linspace(0,axHeight,numString+2);
y0 = y0(end-1:-1:2);
for idxString = 1:numString
    text(0,y0(idxString),...
        string{idxString},...
        'Parent',hAx,...
        'Units','pixels',...
        'HorizontalAlignment','left',...
        'VerticalAlignment','middle',...
        'FontUnits',inputs.FontUnits,...
        'FontName',inputs.FontName,...
        'FontAngle',inputs.FontAngle,...
        'FontSize',inputs.FontSize,...
        'FontWeight',inputs.FontWeight)
end %for

hAx = axes(...
    'Parent',UI.hFig,...
    'Units','pixels',...
    'Position',[1,UI.ButtonBarHeight+1,UI.IconSize,axHeight],...
    'Visible','off');
icon = load('dialogicons.mat');
icon.questIconData(icon.questIconData == 255) = 1;
imshow(icon.questIconData,icon.questIconMap,'Parent',hAx)

option = option(end:-1:1);
for idxOption = 1:numOption
    uicontrol(...
        'Parent', UI.hFig,...
        'Style', 'pushbutton',...
        'Units','pixels',...
        'Position', [figWidth-idxOption*(UI.ButtonWidth+UI.Margin),...
        (UI.ButtonBarHeight-UI.ButtonHeight)/2,...
        UI.ButtonWidth,UI.ButtonHeight],...
        'FontUnits',inputs.FontUnits,...
        'FontName',inputs.FontName,...
        'FontAngle',inputs.FontAngle,...
        'FontSize',inputs.FontSize,...
        'FontWeight',inputs.FontWeight,...
        'String', option{idxOption},...
        'Callback',@(src,evnt)respond_to_polynomial_decision(option{idxOption}));
end %for

set(UI.hFig,...
    'Visible','on');
uiwait(UI.hFig)

    function respond_to_polynomial_decision(decision)
        output = decision;
        delete(UI.hFig)
    end %fun
    function respond_to_closed_by_figure
        generate_information_dialog('TROUBLESHOOTING',...
             {'You need to \bftake a decision \rmto proceed.'})
    end %fun
end %fun