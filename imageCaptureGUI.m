% =========================================================
% imageCaptureGUI.m
% =========================================================
% Author: Vidyacharan G. Venkata
% Email: vigo0136@colorado.edu
% Organization: Matter Assembly Computation Lab (MACLab)
% University of Colorado
% Created: March 23, 2025
% Last Modified: April 2, 2025
%
% Description:
% Continuous Image capture GUI for Surface Tension setup
%
% Changelog (bug fixes):
%   - FIX 1: previewTimer stopped/restarted around captureCallback and
%             thumbnailCallback to eliminate camera race condition crashes
%   - FIX 2: Heavy image processing in thumbnailCallback offloaded via
%             parfeval so the UI never freezes on click
%   - FIX 3: Removed gcf calls inside callbacks; fig captured via closure
%   - FIX 4: Counter uicontrol created once, updated in-loop (no stacking)
%   - FIX 5: pause(0.1) replaced with drawnow limitrate
%   - FIX 6: cleanupFcn now receives and properly deletes the cam object
%   - FIX 7: imadjust * 1.2 uint8 overflow fixed (double conversion)
% =========================================================

%%
function imageCaptureGUI()

close all;

%% Initialize camera

    AspectRatio = [16 9];

    cam = webcam();
    cam.Resolution = '1920x1080';
    cam.ExposureMode = "manual";
    cam.Exposure = -7;
    cam.BacklightCompensation = 1;
    cam.Contrast = 64;
    cam.Brightness = 0;
    cam.Sharpness = 2;

%% Build GUI

    fig = figure('Name', 'Surface Tension Image Capture GUI', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Position', [50 50 1350 800]);

    LiveAxes = axes('Parent', fig, ...
                    'Units', 'pixels', ...
                    'Position', [10 250 960 540], ...
                    'XTick', [], 'YTick', []);

    preview_Axes = axes('Parent', fig, ...
                        'Units', 'pixels', ...
                        'Position', [350 10 400 225], 'BoxStyle', 'full', ...
                        'LineWidth', 2, 'XColor', 'g', 'YColor', 'g', ...
                        'Box', 'on', 'XTick', [], 'YTick', []);

    uicontrol('Style', 'pushbutton', ...
              'Position', [760 20 160 30], ...
              'String', 'Processed Img. Preview', ...
              'Callback', @previewCallback, ...
              'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.2 0.8 0.5]);

    uicontrol('Style', 'text', ...
              'Position', [750 80 100 50], ...
              'String', 'Filter (0 to 100)', ...
              'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

    preview_filter = uicontrol('Style', 'edit', ...
                               'Position', [855 102 60 25], ...
                               'String', '0.75', 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'text', ...
              'Position', [750 130 90 50], ...
              'String', 'Threshold B/W (0 to 1)', ...
              'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

    preview_thresh = uicontrol('Style', 'edit', ...
                               'Position', [855 142 60 25], ...
                               'String', '0.75', 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'text', ...
              'Position', [5 200 180 25], ...
              'String', 'Folder / Material Name:', ...
              'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

    prefixEdit = uicontrol('Style', 'edit', ...
                           'Position', [190 200 105 25], ...
                           'String', 'Material_Name', 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'text', ...
              'Position', [5 170 180 25], ...
              'String', 'Needle Gauge:', ...
              'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

    needleGAEdit = uicontrol('Style', 'edit', ...
                             'Position', [190 170 30 25], ...
                             'String', '15', 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'text', ...
              'Position', [5 140 180 25], ...
              'String', 'Total Imgs (Burst):', ...
              'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

    numImagesEdit = uicontrol('Style', 'edit', ...
                              'Position', [190 140 40 25], ...
                              'String', '120', 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'pushbutton', ...
              'Position', [50 60 180 50], ...
              'String', 'Start Capture', ...
              'Callback', @captureCallback, ...
              'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0]);

    uicontrol('Style', 'text', ...
              'Position', [10 20 200 25], ...
              'String', 'Now Capturing Img. Num:', ...
              'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', [0 0.5 0]);

    % FIX 4: counter created once here; only its String is updated in the loop
    imgCounter = uicontrol('Style', 'text', ...
                           'Position', [215 20 40 25], ...
                           'String', '', ...
                           'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', [0.7 0 0]);

    uicontrol('Style', 'text', ...
              'Position', [5 770 100 20], ...
              'String', 'Live View', ...
              'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', [0 0.5 0], ...
              'BackgroundColor', [0.85 0.85 0]);

    outerPanel = uipanel('Parent', fig, ...
                         'Title', 'Scroll & Click Thumbnails to Save', ...
                         'Position', [0.74 0.125 0.25 0.85], ...
                         'FontSize', 11, 'BackgroundColor', [0.8 0.8 0.8]);

    thumbnailPanel = uipanel('Parent', outerPanel, ...
                             'Units', 'pixels', ...
                             'Position', [5 0 310 720], ...
                             'BorderType', 'line', 'BorderColor', [0.75 0.75 0.0], 'BorderWidth', 2, ...
                             'BackgroundColor', [0.75 0.85 0.85]);

    scrollbar = uicontrol('Parent', outerPanel, ...
                          'Style', 'slider', ...
                          'Units', 'normalized', ...
                          'BackgroundColor', [0.7 0.85 0.85], ...
                          'Value', 1, 'Min', 0, 'Max', 1, ...
                          'Position', [0.922 0.073 0.065 0.9], ...
                          'Callback', @scrollCallback);

%% App data and live view

    data = struct();
    data.cam = cam;
    data.previewAxes = LiveAxes;
    data.thumbnailPanel = thumbnailPanel;
    data.capturedImages = {};
    data.isCapturing = false;
    setappdata(fig, 'data', data);

    frame = snapshot(cam);
    live_view = imshow(frame, 'Parent', LiveAxes);

    previewTimer = timer('ExecutionMode', 'fixedRate', ...
                         'Period', 0.033, ...
                         'TimerFcn', @(~,~)updateLive(cam, live_view));
    setappdata(fig, 'PreviewTimer', previewTimer);
    start(previewTimer);

    % FIX 6: pass cam explicitly so cleanupFcn can properly delete it
    set(fig, 'CloseRequestFcn', @(~,~)cleanupFcn(fig, cam, previewTimer));

%% Nested functions

    function scrollCallback(src, ~)
        scrollValue = get(src, 'Value');
        pos = get(thumbnailPanel, 'Position');
        maxScroll = max(0, pos(4) - outerPanel.Position(4) * fig.Position(4));
        pos(2) = -scrollValue * maxScroll;
        set(thumbnailPanel, 'Position', pos);
    end

    function updateLive(cam, live_view)
        if isvalid(LiveAxes)
            live_view.CData = snapshot(cam);
            drawnow;
        end
    end

    function previewCallback(~, ~)
        % FIX 3: use closure variable 'fig' directly, not gcf
        data = getappdata(fig, 'data');
        img = snapshot(data.cam);

        threshVal = str2double(get(preview_thresh, 'String'));
        filtVal   = str2double(get(preview_filter, 'String'));

        filt_prev_img  = imgaussfilt(rgb2gray(img), filtVal);
        prev_sharpened = imsharpen(filt_prev_img, 'Radius', 5.1, 'Amount', 2);

        % FIX 7: convert to double before multiplying to prevent uint8 overflow
        prev_enhanced_d = min(double(imadjust(prev_sharpened)) * 1.2 / 255, 1);
        prev_enhanced   = im2uint8(prev_enhanced_d);

        T              = adaptthresh(prev_enhanced, threshVal);
        img_bin        = imbinarize(prev_enhanced, T);
        img_inverted   = imcomplement(img_bin);
        img_removeDots = bwareaopen(img_inverted, 50, 8);
        img_removeDots = bwareaopen(img_removeDots, 70, 8);
        img_removeDots = bwareaopen(img_removeDots, 90, 4);
        final_preview  = imcomplement(img_removeDots);

        imshow(final_preview, 'Parent', preview_Axes);
    end

    function captureCallback(~, ~)
        % FIX 1: stop timer before touching the camera to prevent race condition
        stop(previewTimer);

        % FIX 3: use closure variable 'fig' directly
        data = getappdata(fig, 'data');

        numImages = str2double(get(numImagesEdit, 'String'));
        prefix    = get(prefixEdit, 'String');
        needleGa  = get(needleGAEdit, 'String');

        delete(get(data.thumbnailPanel, 'Children'));
        data.capturedImages = cell(1, numImages);

        thumbWidth  = 320;
        thumbHeight = (thumbWidth / AspectRatio(1)) * AspectRatio(2);
        textHeight  = 20;
        totalHeight = numImages * (thumbHeight + textHeight + 10) + 10;

        set(thumbnailPanel, 'Position', [5 1 310 totalHeight]);
        set(scrollbar, 'Value', 0);

        for i = 1:numImages
            img = snapshot(data.cam);
            data.capturedImages{i} = img;

            % FIX 4: update the existing counter control, don't create a new one
            set(imgCounter, 'String', num2str(i));
            % FIX 5: drawnow limitrate instead of pause(0.1)
            drawnow limitrate;

            filename = strcat(prefix, '_', needleGa, 'Ga_', num2str(i));

            yPos = totalHeight - (i * (thumbHeight + textHeight + 10));

            containerPanel = uipanel('Parent', thumbnailPanel, ...
                                     'Units', 'pixels', ...
                                     'Position', [5 yPos thumbWidth thumbHeight+textHeight], ...
                                     'BorderType', 'none', 'FontSize', 7);

            thumbBtn = uicontrol('Parent', containerPanel, ...
                                 'Style', 'pushbutton', ...
                                 'Units', 'pixels', ...
                                 'Position', [0 textHeight thumbWidth thumbHeight], ...
                                 'UserData', struct('image', img, 'index', i));

            textLabel = uicontrol('Parent', containerPanel, ...
                                  'Style', 'text', ...
                                  'Units', 'pixels', ...
                                  'Position', [0 0 thumbWidth textHeight], ...
                                  'String', filename, 'FontSize', 10, ...
                                  'BackgroundColor', get(containerPanel, 'BackgroundColor'));

            [thumbImg, ~, ~] = createThumbnail(img, [thumbWidth thumbHeight]);
            set(thumbBtn, 'CData', thumbImg);

            set(thumbBtn, 'Callback', @(src,~)thumbnailCallback(src, prefixEdit, needleGAEdit, preview_thresh, preview_filter));

            set(thumbBtn,  'TooltipString', filename);
            set(textLabel, 'TooltipString', filename);
        end

        setappdata(fig, 'data', data);

        % FIX 1: restart timer now that capture loop is done
        start(previewTimer);
    end

    function thumbnailCallback(src, prefixEdit, needleGAEdit, preview_thresh, preview_filter)
        % FIX 1: stop timer to avoid camera contention during save
        stop(previewTimer);

        userData  = get(src, 'UserData');
        img       = userData.image;
        idx       = userData.index;
        prefix    = get(prefixEdit, 'String');
        needleGa  = get(needleGAEdit, 'String');
        threshVal = str2double(get(preview_thresh, 'String'));
        filtVal   = str2double(get(preview_filter, 'String'));

        % Disable button immediately so the user knows the click registered
        set(src, 'Enable', 'off', 'String', 'Saving...');
        drawnow;

        % FIX 2: offload heavy processing to a background worker via parfeval
        %         so the UI stays responsive. The completion callback handles
        %         the file write and highlights the button when done.
        f = parfeval(backgroundPool, @processAndSave, 1, ...
                     img, idx, prefix, needleGa, threshVal, filtVal);

        afterEach(f, @(~) onSaveDone(src, prefix, needleGa, idx), 0);

        % FIX 1: restart timer immediately — processing is now in the background
        start(previewTimer);
    end

    function onSaveDone(src, prefix, needleGa, idx)
        % Called on the main thread after parfeval finishes.
        % Re-enable button and show confirmation.
        if isvalid(src)
            set(src, 'BackgroundColor', [0.0 1 0.5], 'Enable', 'on', 'String', '');
        end
        filename_final = strcat(prefix, '_', needleGa, 'Ga_', num2str(idx), '.tif');
        save_msg = msgbox(strcat('Saved: ', filename_final), 'Image', 'replace');
        set(save_msg, 'Position', [500 500 150 50]);
    end

%% Utility functions

    function [thumbImg, map, alpha] = createThumbnail(img, thumbSize)
        imgSize = size(img);
        ratio   = imgSize(2) / imgSize(1);

        if ratio > thumbSize(1) / thumbSize(2)
            newWidth  = thumbSize(1);
            newHeight = round(thumbSize(1) / ratio);
        else
            newHeight = thumbSize(2);
            newWidth  = round(thumbSize(2) * ratio);
        end

        thumbImg   = imresize(img, [newHeight newWidth]);
        finalThumb = uint8(zeros(thumbSize(2), thumbSize(1), 3));

        startRow = max(1, floor((thumbSize(2) - newHeight) / 2) + 1);
        startCol = max(1, floor((thumbSize(1) - newWidth)  / 2) + 1);

        rowIdx = startRow : (startRow + size(thumbImg, 1) - 1);
        colIdx = startCol : (startCol + size(thumbImg, 2) - 1);
        rowIdx = rowIdx(rowIdx <= thumbSize(2));
        colIdx = colIdx(colIdx <= thumbSize(1));

        finalThumb(rowIdx, colIdx, :) = thumbImg(1:length(rowIdx), 1:length(colIdx), :);

        thumbImg = finalThumb;
        map      = [];
        alpha    = ones(thumbSize(2), thumbSize(1));
    end

    function cleanupFcn(fig, cam, previewTimer)
        % FIX 6: cam is now passed in explicitly and properly deleted
        stop(previewTimer);
        delete(previewTimer);
        if isvalid(cam)
            delete(cam);
        end
        delete(fig);
    end

end % imageCaptureGUI

%% =========================================================
%  Standalone processing function (runs in parfeval worker)
%  Must be a top-level function (not nested) to be callable
%  by backgroundPool.
%% =========================================================
function result = processAndSave(img, idx, prefix, needleGa, threshVal, filtVal)

    % Rotate: MACLab camera is mounted 90 degrees
    rotated  = imrotate(img, -90, 'bilinear');
    grayImg  = rgb2gray(rotated);

    gauss_image     = imgaussfilt(grayImg, filtVal);
    sharpened       = imsharpen(gauss_image, 'Radius', 5.1, 'Amount', 2);
    adjusted_tempImg = imadjust(sharpened);

    T          = adaptthresh(adjusted_tempImg, threshVal);
    img_bin    = imbinarize(adjusted_tempImg, T);
    img_inverted   = imcomplement(img_bin);
    img_removeDots = bwareaopen(img_inverted,  50, 8);
    img_removeDots = bwareaopen(img_removeDots, 70, 8);
    img_removeDots = bwareaopen(img_removeDots, 90, 4);
    img_enhanced   = imcomplement(img_removeDots);

    RGBfilterHval = ones(5,5) / 25;
    img_filt_rgb  = imfilter(img, RGBfilterHval);
    RGB_sharpened = imsharpen(img_filt_rgb, 'Radius', 5.1, 'Amount', 2);

    currentPath = pwd;

    filename_final = strcat(prefix, '_', needleGa, 'Ga_',    num2str(idx), '.tif');
    filename_RGB   = strcat(prefix, '_', needleGa, 'GaRGB_', num2str(idx), '.tif');
    filename_BW    = strcat(prefix, '_', needleGa, 'GaBW_',  num2str(idx), '.tif');

    ImgSaveDir = fullfile(currentPath, 'Outputs', prefix, strcat(needleGa, 'Ga'), 'Images');
    RawSaveDir = fullfile(currentPath, 'Outputs', prefix, strcat(needleGa, 'Ga'), 'RawFiles');
    [~,~] = mkdir(ImgSaveDir);
    [~,~] = mkdir(RawSaveDir);

    imwrite(img_enhanced,   fullfile(ImgSaveDir, filename_final), 'tif', 'Compression', 'none');
    imwrite(RGB_sharpened,  fullfile(RawSaveDir, filename_RGB),   'tif', 'Compression', 'none');
    imwrite(adjusted_tempImg, fullfile(RawSaveDir, filename_BW),  'tif', 'Compression', 'none');

    result = true; % signal success to afterEach
end