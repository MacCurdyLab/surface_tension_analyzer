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
% =========================================================

%%
function imageCaptureGUI()

% clear;
close all;

 %% Initialize camera -- Specific values depend on your cam model and if such parameters exist
    
    AspectRatio=[16 9]; %Specify the Aspect Ratio. Default is with a 1080p cam of 16:9

    cam = webcam(); % Initialize the camera object
  
    cam.Resolution = '1920x1080'; % Edit based on your specific webcam

    cam.ExposureMode="manual"; % Set to Manual exposure to keep it consistent
    
    cam.Exposure=-7; % Goes from -13 to 0 -- darkest to highest
    
    cam.BacklightCompensation=1; % 1 is default. 0 turns it off
    
    cam.Contrast=64; % Goes from 0 to 64 on MACLab camera model
    
    cam.Brightness=0; % Goes from 0 to 64 on MACLab camera model
    
    cam.Sharpness=2; %Sharpness goes from 0 to 6. Default = 3

%% The GUI is created in the following section

    % Create the main figure with extra width for thumbnails
    fig = figure('Name', 'Surface Tension Image Capture GUI', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [50 50 1350 800]); % Increased width by 300 pixels for thumbnails

    % Create Live view axes 
    LiveAxes = axes('Parent', fig, ...
                      'Units', 'pixels', ...
                      'Position', [10 250 960 540], ...
                      'XTick',[],'YTick',[]); % Live relay of webcam in 16:9 aspect ratio

    % Create Image preview axes to check thresholding for post-processed images
    preview_Axes = axes('Parent', fig, ...
                      'Units', 'pixels', ...
                      'Position', [350 10 400 225],'BoxStyle','full', ...
                      'LineWidth',2,'XColor','g','YColor','g', ...
                      'Box','on','XTick',[],'YTick',[]); % Preview to check thresholds
    %Preview Button - calls the Preview function to view sample image
    uicontrol('Style', 'pushbutton', ...
                          'Position', [760 20 160 30], ...
                          'String', 'Processed Img. Preview', ...
                          'Callback', @previewCallback,'FontSize',10,'FontWeight','bold','BackgroundColor',[0.2 0.8 0.5])



    % Threshold Adjust Input for post-processing
   uicontrol('Style', 'text', ...
             'Position', [750 80 100 50], ...
             'String', 'Filter (0 to 100)','FontSize',11,'FontWeight','bold','HorizontalAlignment','right');
% Default Filename - Can be over-written by user input
    preview_filter = uicontrol('Style', 'edit', ...
                          'Position', [855 102 60 25], ...
                          'String', '0.75','FontSize',11,'HorizontalAlignment','left');
  % Threshold Adjust Input for post-processing
   uicontrol('Style', 'text', ...
             'Position', [750 130 90 50], ...
             'String', 'Threshold B/W (0 to 1)','FontSize',11,'FontWeight','bold','HorizontalAlignment','right');
% Default Filename - Can be over-written by user input
    preview_thresh = uicontrol('Style', 'edit', ...
                          'Position', [855 142 60 25], ...
                          'String', '0.75','FontSize',11,'HorizontalAlignment','left');




% Filename Prefix - helps to save files in appropriately named directories
    uicontrol('Style', 'text', ...
             'Position', [5 200 180 25], ...
             'String', 'Folder / Material Name:','FontSize',11,'FontWeight','bold','HorizontalAlignment','right');
% Default Filename - Can be over-written by user input
    prefixEdit = uicontrol('Style', 'edit', ...
                          'Position', [190 200 105 25], ...
                          'String', 'Material_Name','FontSize',11,'HorizontalAlignment','left');

    


 % Needle Gauge - Helpful to keep track of files later on
  uicontrol('Style', 'text', ...
             'Position', [5 170 180 25], ...
             'String', 'Needle Gauge:','FontSize',11,'FontWeight','bold','HorizontalAlignment','right');
 % Get Needle Gauge from the user-input
  needleGAEdit = uicontrol('Style', 'edit', ...
                          'Position', [190 170 30 25], ...
                          'String', '15','FontSize',11,'HorizontalAlignment','left');
    
    
  
  % Burst Images Control
    uicontrol('Style', 'text', ...
             'Position', [5 140 180 25], ...
             'String', 'Total Imgs (Burst):','FontSize',11,'FontWeight','bold','HorizontalAlignment','right');
    
    % Burst images default total - Set to 120 in sequence. Change it in GUI
    numImagesEdit = uicontrol('Style', 'edit', ...
                             'Position', [190 140 40 25], ...
                             'String', '120','FontSize',11,'HorizontalAlignment','left');

    

    %Capture Button - calls the Capture function to record images
    uicontrol('Style', 'pushbutton', ...
                          'Position', [50 60 180 50], ...
                          'String', 'Start Capture', ...
                          'Callback', @captureCallback,'FontSize',14,'FontWeight','bold','BackgroundColor',[0.8 0.8 0]);
 

    % Display the number of the image being recorded. Check the...
    % captureCallBack function -- it is updated within a FOR loop inside...
    % that function
    uicontrol('Style', 'text', ...
             'Position', [10 20 200 25], ...
             'String', 'Now Capturing Img. Num:','FontSize',12,'FontWeight','bold','ForegroundColor',[0 0.5 0]);
 
 % Live view text - No purpose, just indicates that the preview is live
 uicontrol('Style', 'text', ...
             'Position', [5 770 100 20], ...
             'String', 'Live View','FontSize',12,'FontWeight','bold','ForegroundColor',[0 0.5 0], ...
             'BackgroundColor',[0.85 0.85 0]);


% Create a Check Preview window to set Post-Process parameters and threshholds




  % Create outer panel for thumbnails on the right
    outerPanel = uipanel('Parent', fig, ...
                        'Title', 'Scroll & Click Thumbnails to Save', ...
                        'Position', [0.74,0.125 0.25 0.85],'FontSize',11,'BackgroundColor',[0.8 0.8 0.8]); % Right side position [[5]]


    % Create inner panel for thumbnails (scrollable content)
    thumbnailPanel = uipanel('Parent', outerPanel, ...
                            'Units', 'pixels', ...
                            'Position', [5 0 310 720], ... % Make it taller than viewport
                            'BorderType','line','BorderColor',[0.75 0.75 0.0],'BorderWidth',2, ...
                            'BackgroundColor',[0.75 0.85 0.85]);

    % Create vertical scrollbar for thumbails
    scrollbar = uicontrol('Parent', outerPanel, ...
                         'Style', 'slider', ...
                         'Units', 'normalized', ...
                         'BackgroundColor',[0.7 0.85 0.85],...
                         'Value',1,'Min',0,'Max',1,...
                         'Position', [0.922 0.073 0.065 0.9], ... % Right side of panel
                         'Callback', @scrollCallback); % [[11]]




%% This section does some of the image capture and shows live view

    % Store data from the image capture
    data = struct();
    data.cam = cam;
    data.previewAxes = LiveAxes;
    data.thumbnailPanel = thumbnailPanel;
    data.capturedImages = {};
    setappdata(fig, 'data', data);

    % Store capture state in figure data
    data.isCapturing = false;
    setappdata(fig, 'data', data);


    % Capture the Live Frames to display 
    frame = snapshot(cam);
    live_view=imshow(frame, 'Parent', LiveAxes);


    % Create preview timer with update rate - 30fps by default, leave it as
    % is since the timer function can be finicky in MATLAB
    previewTimer = timer('ExecutionMode', 'fixedRate', ...
                        'Period', 0.033, ... % ~30 FPS
                        'TimerFcn', @(~,~)updateLive(cam, live_view));

    setappdata(fig, 'PreviewTimer', previewTimer);
    start(previewTimer);
   
    % Cleanup on close - Stops the timer and clears the cache
    set(fig, 'CloseRequestFcn', @(~, ~, ~)cleanupFcn(fig, cam, previewTimer));

    
%% This section has the actual functions that are being called

    function scrollCallback(src, ~)
        % Get scroll value (0 to 1)
        scrollValue = get(src, 'Value');
        
        % Get panel position
        pos = get(thumbnailPanel, 'Position');
        
        % Calculate maximum scroll
        maxScroll = max(0, pos(4) - outerPanel.Position(4)*fig.Position(4));
        
        % Update panel position
        pos(2) = -scrollValue * maxScroll;
        
        set(thumbnailPanel, 'Position', pos);
    end

%    function updatePreview(cam, previewAxes,live_view)
     function updateLive(cam, live_view)

        if isvalid(LiveAxes)
            live_view.CData = snapshot(cam);
            drawnow;
        end
     end

    function previewCallback(~, ~, ~)
     fig = gcf;
    data = getappdata(fig, 'data');
    img = snapshot(data.cam);
    %data.capturedImages{i} = img;
     
   % updatePreview(cam,previewAxes);
   %updateLive(cam,live_view);
   threshVal = str2double(get(preview_thresh, 'String'));
   filtVal = str2double(get(preview_filter, 'String'));

filt_prev_img = imgaussfilt(rgb2gray(img), filtVal);
     prev_sharpened = imsharpen(filt_prev_img, 'Radius', 5.1, 'Amount', 2);   
     prev_enhanced = imadjust(prev_sharpened)*1.2;
 
    T = adaptthresh(prev_enhanced, threshVal);
    img_bin = imbinarize(prev_enhanced,T);
    img_inverted = imcomplement(img_bin);
    img_removeDots = bwareaopen(img_inverted,50,8);
    img_removeDots = bwareaopen(img_removeDots,70,8);
    img_removeDots = bwareaopen(img_removeDots,90,4);
    final_preview = imcomplement(img_removeDots);
    %final_preview = bwareaopen(final_preview,150,4);

imshow(final_preview,'Parent',preview_Axes);

    
end
 
% NOTE: Thumbnail image creation is done within in captureCallback function

    function captureCallback(~, ~, ~)

   % pause(1);
    fig = gcf;
    data = getappdata(fig, 'data');
   % updatePreview(cam,previewAxes);
   updateLive(cam,live_view);


    % Get parameters
    numImages = str2double(get(numImagesEdit, 'String')); %convert the input num. of imgs to a double-type num.
    prefix = get(prefixEdit, 'String'); % Filename Prefix to create a Folder in directory the filenames
    needleGa = get(needleGAEdit, 'String'); % Needle Gauge to create name and ref. directory


    % Clear previous thumbnails
    delete(get(data.thumbnailPanel, 'Children'));

    % Clear previous captured images
    data.capturedImages = cell(1, numImages);

    % Calculate thumbnail size
    thumbWidth = 320;
    thumbHeight = (thumbWidth/AspectRatio(1))*AspectRatio(2); % Thumbnail Width remains fixed

    % Calculate text height for filename
    textHeight = 20; % Height for filename text [[1]]

    % Update inner panel height based on number of images (including text space)
    totalHeight = numImages * (thumbHeight + textHeight + 10) + 10;
    set(thumbnailPanel, 'Position', [5 1 310 totalHeight]);

    % Reset scrollbar
    set(scrollbar, 'Value', 0);

    % Capture sequence - runs in a for loop
    for i = 1:numImages

        % Capture the image
        img = snapshot(data.cam);
        data.capturedImages{i} = img;

        %update the live view again after capture;
        updateLive(cam,live_view);

        % Updates the text of Image Number being captured
        uicontrol('Style', 'text', ...
             'Position', [215 20 40 25], ...
             'String', num2str(i),'FontSize',12,'FontWeight','bold','ForegroundColor',[0.7 0.0 0]);


       % Generate filename
       % filename = sprintf('%s_%d.tif', prefix, i);
        filename=strcat(prefix,'_',needleGa,'Ga_',num2str(i));


        % Calculate positions from top
        yPos = totalHeight - (i * (thumbHeight + textHeight + 10));

        % Create container panel for thumbnail and text
        containerPanel = uipanel('Parent', thumbnailPanel, ...
                               'Units', 'pixels', ...
                               'Position', [5 yPos thumbWidth thumbHeight+textHeight], ...
                               'BorderType', 'none','FontSize',7);

        % Create thumbnail button
        thumbBtn = uicontrol('Parent', containerPanel, ...
                           'Style', 'pushbutton', ...
                           'Units', 'pixels', ...
                           'Position', [0 textHeight thumbWidth thumbHeight], ...
                           'UserData', struct('image', img, 'index', i));

        % Create text label for filename [[2]]
        textLabel = uicontrol('Parent', containerPanel, ...
                            'Style', 'text', ...
                            'Units', 'pixels', ...
                            'Position', [0 0 thumbWidth textHeight], ...
                            'String', filename,'FontSize',10, ...
                            'BackgroundColor', get(containerPanel, 'BackgroundColor'));

        % Create thumbnail
        [thumbImg, ~, ~] = createThumbnail(img, [thumbWidth thumbHeight]);
        set(thumbBtn, 'CData', thumbImg);

        % Set callback
        set(thumbBtn, 'Callback', @(src,~,~,~,~)thumbnailCallback(src, prefixEdit, needleGAEdit, preview_thresh, preview_filter));

        % Add tooltip for full filename [[3]]
        set(thumbBtn, 'TooltipString', filename);
        set(textLabel, 'TooltipString', filename);

        pause(0.1);
    end

    setappdata(fig, 'data', data);
end


% This function makes the Thumbnail to be a clickable button to save
    function thumbnailCallback(src, prefixEdit, needleGAEdit, preview_thresh, preview_filter)
        % Get image data
        userData = get(src, 'UserData');
        img = userData.image;
        idx = userData.index;
        prefix = get(prefixEdit, 'String');
        needleGa = get(needleGAEdit, 'String');
        threshVal = str2double(get(preview_thresh, 'String'));
        filtVal = str2double(get(preview_filter, 'String'));



        % Post-Process the image to write to disk

        % The MACLab setup has the camera rotated 90degrees.
        % This rotates the image to be upright while saving
        rotated = imrotate(img, -90, 'bilinear');
        grayImg = rgb2gray(rotated);

        %Gaussian blur to smoothen edges
        gauss_image = imgaussfilt(grayImg, filtVal); % filter value got from user input in GUI
        
        % Sharpen the blurred images to smoothen contours at edges
        sharpened = imsharpen(gauss_image, 'Radius', 5.1, 'Amount', 2);
        adjusted_tempImg = imadjust(sharpened); %Adjusted BW Image for next step

        T = adaptthresh(adjusted_tempImg, threshVal); % Threshhold value got from user input in GUI
        img_bin = imbinarize(adjusted_tempImg,T);
       
        img_inverted = imcomplement(img_bin);
        img_removeDots = bwareaopen(img_inverted,50,8);
        img_removeDots = bwareaopen(img_removeDots,70,8);
        img_removeDots = bwareaopen(img_removeDots,90,4);
        img_enhanced = imcomplement(img_removeDots);


        RGBfilterHval = ones(5,5)/25;
        img_filt_rgb=imfilter(img,RGBfilterHval); % Gaussian blur on the Raw RGB images
        RGB_sharpened = imsharpen(img_filt_rgb, 'Radius', 5.1, 'Amount', 2);


        % Save image to local folder
        currentPath=pwd; % Gets the current folder directory

        % Create the Filename for each unique image
        %filename = sprintf('%s_%d.tif', prefix, idx);
        filename_final=strcat(prefix,'_',needleGa,'Ga_',num2str(idx),'.tif'); %Final imgs for analysis
        filename_RGB=strcat(prefix,'_',needleGa,'GaRGB_',num2str(idx),'.tif');
        filename_BW=strcat(prefix,'_',needleGa,'GaBW_',num2str(idx),'.tif');


        % Creates the full directory path to save images
        % OutputSaveDir = fullfile(currentPath, 'Outputs', prefix, strcat(needleGa,'Ga'),'Results');
        % [~,~]=mkdir(OutputSaveDir); %Makes a directory to save the imgs
        ImgSaveDir = fullfile(currentPath, 'Outputs', prefix, strcat(needleGa,'Ga'),'Images');
        [~,~]=mkdir(ImgSaveDir); %Makes a directory to save the imgs
        RawSaveDir = fullfile(currentPath, 'Outputs', prefix, strcat(needleGa,'Ga'),'RawFiles');
        [~,~]=mkdir(RawSaveDir); %Makes a directory to save the imgs

        
        % Generate Image Full Paths and Save images using imwrite()
        ImgSaveFinal=strcat(ImgSaveDir,'\',filename_final);
        imwrite(img_enhanced, ImgSaveFinal, "tif",'Compression','none');
        %imwrite(adjusted_tempImg, ImgSaveFinal, "tif",'Compression','none');
        
        ImgSaveRAW=strcat(RawSaveDir,'\',filename_RGB);
        imwrite(RGB_sharpened, ImgSaveRAW, "tif",'Compression','none');
        
        ImgSaveBW=strcat(RawSaveDir,'\',filename_BW);
        imwrite(adjusted_tempImg, ImgSaveBW, "tif",'Compression','none');
       
        % Highlight saved thumbnail
        set(src, 'BackgroundColor', [0.0 1 0.5]);

        % Show confirmation that the image has been saved
       save_msg= msgbox(strcat('Saved',filename_final), 'Image','replace');
 
        set(save_msg, 'position', [500 500 150 50]);
      % msg_temp=get(save_msg,'CurrentAxes');
      % msg_fnt=get(msg_temp,'Children');
      % set(msg_fnt,'FontSize',10);

 end

function [thumbImg, map, alpha] = createThumbnail(img, thumbSize)
    % Resize image to thumbnail size maintaining aspect ratio
    imgSize = size(img);
    ratio = imgSize(2)/imgSize(1);

    % Calculate new dimensions
    if ratio > thumbSize(1)/thumbSize(2)
        newWidth = thumbSize(1);
        newHeight = round(thumbSize(1)/ratio);
    else
        newHeight = thumbSize(2);
        newWidth = round(thumbSize(2)*ratio);
    end

    % Resize image
    thumbImg = imresize(img, [newHeight newWidth]);

    % Create final thumbnail with correct dimensions
    finalThumb = uint8(zeros(thumbSize(2), thumbSize(1), 3));

    % Calculate positions for centering
    startRow = max(1, floor((thumbSize(2) - newHeight)/2) + 1);
    startCol = max(1, floor((thumbSize(1) - newWidth)/2) + 1);

    % Place resized image in center
    rowIdx = startRow:(startRow + size(thumbImg,1) - 1);
    colIdx = startCol:(startCol + size(thumbImg,2) - 1);
    rowIdx = rowIdx(rowIdx <= thumbSize(2));
    colIdx = colIdx(colIdx <= thumbSize(1));

    finalThumb(rowIdx, colIdx, :) = thumbImg(1:length(rowIdx), 1:length(colIdx), :);

    thumbImg = finalThumb;
    map = [];
    alpha = ones(thumbSize(2), thumbSize(1));
end

function cleanupFcn(fig, ~, previewTimer)
    
    % Stop and delete timer
    stop(previewTimer);
    delete(previewTimer);
    
    % Delete figure
    %close all;
    delete(fig);
    
    % Clear camera
    clear cam;

end

end