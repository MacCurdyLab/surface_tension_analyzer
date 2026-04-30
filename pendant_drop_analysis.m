% =========================================================
% pendant_drop_analysis.m
% =========================================================
% Author: Vidyacharan G. Venkata
% Email: vigo0136@colorado.edu
% Organization: Matter Assembly Computation Lab (MACLab)
% University of Colorado
% Created: March 23, 2025
% Last Modified: April 2, 2025
%
% Description: GUI to pull up a folder and call functions to measure
% surface tension from a pendant drop image
% =========================================================

%%
function pendant_drop_analysis(folder, needleGauge, density_liquid, density_surrounding)
    if nargin < 1 || isempty(folder)
        folder = uigetdir('Select folder containing .tif images');
        if folder == 0
            return
        end
    end
    if nargin < 3
        density_liquid = 998;
        density_surrounding = 1.04;
    end
    
    % Get list of .tif files
    files = dir(fullfile(folder, '*.tif'));
    if isempty(files)
        errordlg('No .tif files found in the selected directory');
        return
    end
    
  
  % density_difference = density_liquid - density_surrounding;
  % Calculated in the surface_tension_calculation function later on
    
    % Load first image for calibration
    fname=fullfile(folder, files(1).name);
    img = imread(fname);


    if size(img, 3) == 3
        img = rgb2gray(img);
    end
   
    % ptr_data = NaN(32,32);
    % ptr_data(16,:) = 1;  % Horizontal line
    % ptr_data(:,16) = 1;  % Vertical line
    % 
    % % Set the custom pointer
    % % set(fig, 'PointerShapeCData', ptr_data);
    % set(fig, 'PointerShapeHotSpot', [16 16]);
    
  

    % Create figure for calibration with crosshair
    fig = figure('Name', 'Pendant Drop Calibration', 'NumberTitle', 'off', ...
        'Pointer', 'crosshair');
%fig.PointerMode

    
    
    imshow(img);
    title('Scroll to zoom. Click to place, then press Confirm.');
    set(fig, 'WindowScrollWheelFcn', @scrollZoom);
    
   % waitforbuttonpress;
    
    % Get meniscus start point — click to position, button to confirm
hold on;
y_meniscus = size(img, 1) / 2; % default starting position
title('Click to set meniscus line. Press Confirm when satisfied.');

hMeniscusBtn = uicontrol('Style', 'pushbutton', 'String', 'Confirm Meniscus', ...
    'Units', 'normalized', 'Position', [0.35 0.01 0.3 0.05], ...
    'Callback', @(~,~) uiresume(fig));

set(fig, 'WindowButtonDownFcn', @onMeniscusClick);
uiwait(fig);
set(fig, 'WindowButtonDownFcn', '');
delete(hMeniscusBtn);

function onMeniscusClick(~, ~)
    % Only block clicks on UI buttons, not on the image/axes
    if isa(fig.CurrentObject, 'matlab.ui.control.UIControl')
        return;
    end
    cp = get(gca, 'CurrentPoint');
    y_meniscus = cp(1, 2);
    delete(findobj(gca, 'Tag', 'MeniscusLine'));
    line([1 size(img,2)], [y_meniscus y_meniscus], ...
        'Color', 'g', 'LineWidth', 2, 'Tag', 'MeniscusLine');
    plot(cp(1,1), y_meniscus, 'g+', 'MarkerSize', 10, 'Tag', 'MeniscusLine');
    title('Click to reposition, or press Confirm Meniscus.');
end
    
    % Get needle width — alternating clicks set point 1 then point 2, button confirms
x1 = NaN; y1 = NaN; x2 = NaN; y2 = NaN;
needleClickCount = 0;
title('Click left edge of needle, then right edge. Press Confirm when satisfied.');

hNeedleBtn = uicontrol('Style', 'pushbutton', 'String', 'Confirm Needle Width', ...
    'Units', 'normalized', 'Position', [0.35 0.01 0.3 0.05], ...
    'Callback', @(~,~) uiresume(fig));

set(fig, 'WindowButtonDownFcn', @onNeedleClick);
uiwait(fig);
set(fig, 'WindowButtonDownFcn', '');
delete(hNeedleBtn);
needle_width_pixels = abs(x2 - x1);
close(fig);

function onNeedleClick(~, ~)
    % Only block clicks on UI buttons, not on the image/axes
    if isa(fig.CurrentObject, 'matlab.ui.control.UIControl')
        return;
    end
    cp = get(gca, 'CurrentPoint');
    needleClickCount = needleClickCount + 1;
    if mod(needleClickCount, 2) == 1   % Odd click → point 1
        x1 = cp(1,1); y1 = cp(1,2);
        delete(findobj(gca, 'Tag', 'NeedleLine'));
        plot(x1, y1, 'r+', 'MarkerSize', 10, 'Tag', 'NeedleLine');
        title('Now click the second (right) edge of the needle.');
    else                                % Even click → point 2
        x2 = cp(1,1); y2 = cp(1,2);
        delete(findobj(gca, 'Tag', 'NeedleLine'));
        plot(x1, y1, 'r+', 'MarkerSize', 10, 'Tag', 'NeedleLine');
        plot(x2, y2, 'r+', 'MarkerSize', 10, 'Tag', 'NeedleLine');
        line([x1 x2], [y1 y2], 'Color', 'r', 'LineWidth', 2, 'Tag', 'NeedleLine');
        title(sprintf('Width: %.1f px. Click to redo, or press Confirm Needle Width.', abs(x2-x1)));
    end
end
    
   gaugeTable = containers.Map( ...
    {14,15,16,17,18,19,20,21,22,23,24,25,26,27,28}, ...
    {2108,1829,1651,1473,1270,1067,908,819,718,641,566,514,464,413,362});
    
    if isKey(gaugeTable, needleGauge)
        needle_width_microns = gaugeTable(needleGauge);
    else
        errordlg('Unknown needle gauge — add it to the gauge table.', 'Gauge Error');
        return
    end

    
    % Calculate scaling factor (microns/pixel)
 %   scale_factor = needle_width_microns / needle_width_pixels;
    
   
    
    % Initialize arrays for results
    num_images = length(files);
    surface_tensions = zeros(num_images, 1);
    successful_files = cell(num_images, 1);
    error_files = cell(num_images, 1);
    error_count = 0;
    success_count = 0;
    
    sigma=1.5;
    

    OutputSaveDir = fullfile(folder, 'Results');
    [~,~]=mkdir(OutputSaveDir); %Makes a directory to save the imgs
    

   
    % Process all images
    fprintf('\nProcessing %d images...\n', num_images);
    for i = 1:num_images
        try
            % Load image
            current_img = imread(fullfile(folder, files(i).name));
            if size(current_img, 3) == 3
                current_img = rgb2gray(current_img);
            end
            
    [fpath,im_name,ext]=fileparts(files(i).name);
    Op_name=strcat(OutputSaveDir,'\',im_name,'.png');


            % Crop image below meniscus
            img_cropped = current_img(round(y_meniscus):end, :);          
            % sensitivity = 0.3;
            % high_threshold = graythresh(img_cropped) * sensitivity;
            % low_threshold = high_threshold * 0.4;
            % edges = edge(img_cropped, 'Canny', [low_threshold high_threshold], sigma);
        

[R0,beta_classic,surface_tension]=surface_tension_calculation(img_cropped, Op_name, density_liquid, density_surrounding, needle_width_microns, needle_width_pixels);

        % Calculate surface tension
        surface_tensions(i) = surface_tension;
            
            % Store successful file
            success_count = success_count + 1;
            successful_files{success_count} = files(i).name;
            
            % Display progress
            fprintf('Processed image %d/%d: %s\n', i, num_images, files(i).name);
            % Display results
    fprintf('Radius of Curvature (R0): %.6f mm\n', R0.*1000);
    fprintf('Shape Factor (Beta): %.4f\n', beta_classic);
    fprintf('Surface Tension: %.4f mN/m\n', surface_tension);
            
        catch ME
            % Handle errors
            error_count = error_count + 1;
            error_files{error_count} = files(i).name;
            fprintf('Error processing image %s: %s\n', files(i).name, ME.message);
        end
    end
    
    
    % Trim arrays to actual size
   % successful_files = successful_files(1:success_count);
   % error_files = error_files(1:error_count);
  %  surface_tensions = surface_tensions(1:success_count);
    
    % Display results in command window
    fprintf('\nAnalysis Complete!\n');
    fprintf('Successfully processed %d out of %d images\n', success_count, num_images);
    fprintf('Failed to process %d images\n', error_count);
    
    % Create results table
    results_table = table(successful_files, surface_tensions, ...
        'VariableNames', {'Filename', 'SurfaceTension_mN_m'});
    
    % Display results table
    disp(results_table);
    
    fprintf('Surface Tension Average: %.4f mN/m\n', mean(surface_tensions));


    % Save results to files
%    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    % Save as CSV
    csv_filename = fullfile(folder, 'surface_tension_results.csv');
    writetable(results_table, csv_filename);
    
    % % Save as MAT file with additional metadata
    mat_filename = fullfile(folder,'surface_tension_results.mat');
    metadata.processing_date = datetime('now');
    metadata.successful_files=successful_files;
    metadata.density_liquid = density_liquid;
    metadata.density_surrounding = density_surrounding;
    metadata.needle_width_microns = needle_width_microns;
    metadata.needle_width_pixels = needle_width_pixels;
    metadata.error_files = error_files;
    save(mat_filename, 'results_table','metadata');

    % fprintf('\nResults saved to:\n');
    % fprintf('CSV file: %s\n', csv_filename);
    % fprintf('MAT file: %s\n', mat_filename);
    function scrollZoom(~, event)
    ax = gca;
    cp = get(ax, 'CurrentPoint');
    xc = cp(1,1); yc = cp(1,2);
    xl = get(ax, 'XLim');
    yl = get(ax, 'YLim');
    factor = 1.1 ^ event.VerticalScrollCount; % >1 zooms out, <1 zooms in
    set(ax, 'XLim', xc + (xl - xc) * factor, ...
            'YLim', yc + (yl - yc) * factor);
end
end

% function [x_profile, y_profile] = extract_drop_profile(edges, scale_factor)
%     % Extract the coordinates of the drop's edge
%     [y, x] = find(edges);
% 
%     % Convert pixel coordinates to physical units (microns)
%     x_profile = x * scale_factor; % microns
%     y_profile = y * scale_factor; % microns
% 
%     % Sort the profile by y-coordinates (ascending)
%     [y_profile, sort_idx] = sort(y_profile);
%     x_profile = x_profile(sort_idx);
% end
% 
% function R0 = calculate_R0(x_profile, y_profile)
%     % Fit a circle to the apex of the drop to determine R0
%     % Select the apex region (e.g., top 10% of the drop)
%     apex_region = y_profile < (min(y_profile) + 0.1 * (max(y_profile) - min(y_profile)));
%     x_apex = x_profile(apex_region);
%     y_apex = y_profile(apex_region);
% 
%     % Fit a circle to the apex region
%     [xc, yc, R0] = fit_circle(x_apex, y_apex);
% end
% 
% function beta = calculate_beta(x_profile, y_profile, R0)
%     % Fit the Young-Laplace equation to the drop profile to determine beta
%     % Define the theoretical drop shape function
%     drop_shape_func = @(beta, x) R0 * (1 - beta * (x / R0).^2);
% 
%     % Perform curve fitting
%     beta_initial_guess = 1; % Initial guess for beta
%     beta = lsqcurvefit(drop_shape_func, beta_initial_guess, x_profile, y_profile);
% end
% 
% function [xc, yc, R] = fit_circle(x, y)
%     % Fit a circle to a set of points (x, y)
%     % Using the least-squares method
%     A = [-2*x, -2*y, ones(size(x))];
%     b = -(x.^2 + y.^2);
%     params = A \ b;
%     xc = -params(1);
%     yc = -params(2);
%     R = sqrt((xc^2 + yc^2) - params(3));
% end