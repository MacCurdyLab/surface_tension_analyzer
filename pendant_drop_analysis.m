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
function pendant_drop_analysis()
    % Get directory containing .tif images
    folder = uigetdir('Select folder containing .tif images');
    if folder == 0
        return
    end
    
    % Get list of .tif files
    files = dir(fullfile(folder, '*.tif'));
    if isempty(files)
        errordlg('No .tif files found in the selected directory');
        return
    end
    
    % Get material properties from user with larger font
    prompt = {'\fontsize{12}Enter liquid density[kg/m³]. Default shown for DI-water @25C', '\fontsize{12}Enter Air density [kg/m³]. Default shown for air in Boulder, CO'};
    dlgtitle = 'Material Properties';
    dims = [1 90]; % Made dialog box wider
    definput = {'998', '1.04'}; % Default values for water and air
    opts.Interpreter = 'tex'; % Enable tex interpreter for font size
    props = inputdlg(prompt, dlgtitle, dims, definput, opts);
    if isempty(props)
        return
    end
    
    density_liquid = str2double(props{1});
    density_surrounding = str2double(props{2});
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

    function [x, y] = customPointSelect(fig)

    % Set up crosshair cursor
    set(fig, 'Pointer', 'crosshair');

    % Wait for mouse click
    waitforbuttonpress;
    cp = get(gca, 'CurrentPoint');
    x = cp(1,1);
    y = cp(1,2);
    end
    
    imshow(img);
    title('Zoom if needed, then press any key to continue');
    zoom on; % Enable zoom
   
    
   % waitforbuttonpress;
    
    % Get meniscus start point with confirmation
    while true
        title('Click where the meniscus starts');
       % [x_meniscus, y_meniscus] = ginput(1);
       [x_meniscus, y_meniscus] = customPointSelect(fig);
        hold on;
        
        % Delete previous line if it exists
        delete(findobj(gca, 'Tag', 'MeniscusLine'));
        
        % Draw horizontal green line
        hLine = line([1 size(img,2)], [y_meniscus y_meniscus], ...
            'Color', 'g', 'LineWidth', 2, 'Tag', 'MeniscusLine');
        plot(x_meniscus, y_meniscus, 'g+', 'MarkerSize', 10);
        
        % Ask for confirmation
        choice = questdlg('Is this meniscus position correct?', ...
            'Confirm Meniscus Position', ...
            'Yes', 'No', 'Yes');
        if strcmp(choice, 'Yes')
            break;
        else
            delete(findobj(gca, 'Type', 'line'));
        end
    end
    
    % Get needle width points with confirmation
    while true

       title('Click first point for needle width measurement');
       % [x1, y1] = ginput(1);
       [x1, y1] = customPointSelect(fig);
        plot(x1, y1, 'r+', 'MarkerSize', 10); % Mark first point
        
        title('Click second point for needle width measurement');
        %[x2, y2] = ginput(1);
        [x2, y2] = customPointSelect(fig);
        
        % Delete previous line if it exists
        delete(findobj(gca, 'Tag', 'NeedleLine'));
        
        % Draw line between points
        NeedleLine = line([x1 x2], [y1 y2], ...
            'Color', 'r', 'LineWidth', 2, 'Tag', 'NeedleLine');
        plot(x2, y2, 'r+', 'MarkerSize', 10);
        
        % Ask for confirmation
        choice = questdlg('Are these needle width points correct?', ...
            'Confirm Needle Width Points', ...
            'Yes', 'No', 'Yes');
        if strcmp(choice, 'Yes')
            needle_width_pixels = abs(x2 - x1);
            break;
        else
            delete(findobj(gca, 'Type', 'line'));
            delete(findobj(gca, 'Type', 'point'));
        end
    end
    
    % Get physical needle width with larger font
    prompt = {'\fontsize{12}Enter actual needle width (microns):'};
    dims = [1 100];
    opts.Interpreter = 'tex';
    needle_width_microns = str2double(inputdlg(prompt, 'Needle Width', dims, {'1000'}, opts));
    if isempty(needle_width_microns)
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