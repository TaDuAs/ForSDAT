import Simple.*;
import Simple.App.*;
import Simple.UI.*;
import Simple.UI.Plotting.*;

%%
dirName = 'C:\Users\taldu\Google Drive\Reches Lab Share\TADA\Results\QCM\';
fig = figure; %create new figure

%% Native Peptide
sp = subplot('Position',...
    [0.13 0.84527518172378 0.494202898550725 0.152414330218068]);
copyFigureToSubplot([dirName '2017-01-05 - Native Peptide.fig'], fig, sp);
sp = subplot('Position',...
    [0.69159420289855 0.84527518172378 0.213405797101449 0.152414330218068]);
copyFigureToSubplot([dirName '2017-01-05 Native Peptide dF vs dD (all OTs).fig'], fig, sp);

%% Peptide 2
sp = subplot('Position',...
    [0.13 0.646864381297892 0.494202898550725 0.152414330218067]);
copyFigureToSubplot([dirName '2017-04-20 - Peptide 2.fig'], fig, sp);
sp = subplot('Position',...
    [0.69159420289855 0.647100974219027 0.213405797101449 0.152414330218067]);
copyFigureToSubplot([dirName '2017-04-20 - Peptide 2 dF vs dD (OT-7).fig'], fig, sp);

%% Peptide 3
sp = subplot('Position',...
    [0.13 0.448974627507485 0.494202898550725 0.152414330218068]);
copyFigureToSubplot([dirName '2017-05-01 - Peptide 3.fig'], fig, sp);
sp = subplot('Position',...
    [0.69159420289855 0.448464304892777 0.213405797101449 0.152414330218068]);
copyFigureToSubplot([dirName '2017-05-01 - Peptide 3 dF vs dD (OT-7).fig'], fig, sp);

%% Peptide 4
sp = subplot('Position',...
    [0.13 0.249306174403663 0.494202898550725 0.152414330218067]);
copyFigureToSubplot([dirName '2017-06-30 Peptide 4.fig'], fig, sp);
sp = subplot('Position',...
    [0.69159420289855 0.249087357852279 0.213405797101449 0.152414330218068]);
copyFigureToSubplot([dirName '2017-06-30 Peptide 4 dF vs dD (OT-7).fig'], fig, sp);

%% Peptide 5
sp = subplot('Position',...
    [0.13 0.0496377212998394 0.494202898550725 0.152414330218068]);
copyFigureToSubplot([dirName '2017-07-31 Peptide 5.fig'], fig, sp);
sp = subplot('Position',...
    [0.691594202898551 0.0497104108117815 0.213405797101449 0.152414330218068]);
copyFigureToSubplot([dirName '2017-07-31 Peptide 5 dF vs dD (OT-7).fig'], fig, sp);
