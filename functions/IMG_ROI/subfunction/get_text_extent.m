function [width,height] = get_text_extent(string,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

UI = struct(...
    'FontUnits','points',...
    'FontName','FixedWidth',...
    'FontAngle','normal',...
    'FontSize',20,...
    'FontWeight','normal'); %[px]

IP = inputParser;
IP.KeepUnmatched = true;
addParameter(IP,...
    'FontUnits', UI.FontUnits, @(x)isnumeric(x));
addParameter(IP,...
    'FontName', UI.FontName, @(x)ischar(x));
addParameter(IP,...
    'FontAngle', UI.FontAngle, @(x)ischar(x));
addParameter(IP,...
    'FontSize', UI.FontSize, @(x)isnumeric(x));
addParameter(IP,...
    'FontWeight', UI.FontWeight, @(x)ischar(x));
parse(IP,varargin{:});
inputs = IP.Results;

%generate invisible axes to measure expected text extent
hFig = figure(...
    'Units','pixels',...
    'Visible','off');
hAx = axes(...
    'Parent',hFig,...
    'Units','pixels');
hText = text(0,0,string,...
    'Parent',hAx,...
    'Units','pixels',...
    'FontUnits',inputs.FontUnits,...
    'FontName',inputs.FontName,...
    'FontAngle',inputs.FontAngle,...
    'FontSize',inputs.FontSize,...
    'FontWeight',inputs.FontWeight);
extent = get(hText,'Extent');
width = extent(3);
height = extent(4);

close(hFig)
end