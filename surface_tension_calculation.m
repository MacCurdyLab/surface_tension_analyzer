% =========================================================
% surface_tension_calculation.m
% =========================================================
% Author: Vidyacharan G. Venkata
% Email: vigo0136@colorado.edu
% Organization: Matter Assembly Computation Lab (MACLab)
% University of Colorado
% Created: March 23, 2025
% Last Modified: April 2, 2025
%
% Description:
% Edge Detection algorithm + Mathematical functions
% to compute surface tension from a pendant drop image 
% =========================================================

%%
function [R0,beta_classic,preliminarycalc]=surface_tension_calculation(I, im_name, density_liquid, density_surrounding, needle_width_microns, needle_width_pixels)

% Constants and calculations
    g = 9.81;
    density_difference = density_liquid - density_surrounding;
    scale_factor = ((needle_width_microns) / needle_width_pixels)*1e-6;
    
    % Load and preprocess image
  %  I = imread(image_path);
    % if size(I, 3) == 3
    %     I_gray = rgb2gray(I);
    % else
    %     I_gray = I;
    % end
    Analysis_Image = I;

    % Create figure for debugging visualization
   OutputFig= figure('Name', 'Pendant Drop Analysis Debug', 'Position', [100 100 1400 600],'Visible','off');
        
    % Calculate and display gradient magnitude
    [Gx, Gy] = imgradientxy(Analysis_Image);
    gradient_magnitude = imgradient(Gx, Gy);
 
    
    % Apply Canny edge detection
 %   sensitivity = 0.3;
%    high_threshold = graythresh(smoothed_image) * sensitivity;
%    low_threshold = high_threshold * 0.4;
    %edges = edge(smoothed_image, 'Canny', [0.05 0.3],0.25);
edges = edge(Analysis_Image, 'Canny', [0.05 0.3],0.25);
    

% Extract edge coordinates
    [y, x] = find(edges);
    
    % Plot edges in red
     % Display input image with Edge Detection overlay
   figure(OutputFig);
    subplot(1, 2, 1,"replace");
    imshow(I);
    hold on;
    plot(x, y, 'r.', 'MarkerSize', 1);
%   imshow(edges);
    title('Input Img with Edge Detection overlay');
    hold off;

    
    % % Create a new figure for profile analysis
    % figure('Name', 'Drop Profile Analysis', 'Position', [20 100 850 500]);
    
    % Extract and process drop profile
    [x_profile, y_profile] = extract_drop_profile(edges, scale_factor);
    
    % % Plot the extracted profile
    % subplot(1, 2, 2);
    % plot(x_profile, y_profile, 'b.', 'MarkerSize', 2);
    % title('Extracted Drop Profile');
    % xlabel('X (meters)');
    % ylabel('Y (meters)');
    % axis equal;
    % grid on;
    
    % Calculate and display results
    [xFit, yFit] = calculate_FitRegion(x_profile, y_profile);
  %  [xcp, ycp, R_raw] = circle_fit(xFit, yFit);
    [x_outer, y_outer, x_center, y_center, R0] = fit_circle(xFit, yFit);

   % beta = calculate_beta(x_profile, y_profile, R0);
  %  surface_tension = (density_difference * g * R0^2) / beta;

    % 
    % % Display numerical results
    % subplot(1, 2, 2);
    % axis off;
    % text(0.1, 0.8, sprintf('R0: %.6f mm', R0 * 1000));
    % %text(0.1, 0.6, sprintf('Beta: %.4f', beta));
    % %text(0.1, 0.4, sprintf('Surface Tension: %.4f mN/m', surface_tension * 1000));
    % title('Calculated Parameters');
    
    % Print results to command window
    % fprintf('\nResults:\n');
    % fprintf('R0: %.6f mm\n', R0 * 1000);
    % fprintf('Beta: %.4f\n', beta);
    % fprintf('Surface Tension: %.4f mN/m\n', surface_tension * 1000);

%dS = ds_Calc(xc_pts, yc_pts, xcp, ycp, R0, x_profile, y_profile,x_outer, y_outer);
dS=dS_Calc(x_profile, y_profile, xFit, yFit, x_outer, y_outer, x_center, y_center, R0, OutputFig);

    % fprintf('dS val in mm: %.4f \n', dS*1000);
    % fprintf('dS val in pixels: %.4f \n', dS/scale_factor);


beta_classic = 0.12836 - 0.7577*(dS/(2*R0)) + 1.7713*(dS/(2*R0))^2 - 0.5426*(dS/(2*R0))^3;
preliminarycalc = 1000*9.81*density_difference*(R0^2)/beta_classic;
    fprintf('prelim calc of surface tension = %.4f \n', preliminarycalc);

     beta = beta_classic;
    surface_tension = preliminarycalc;
    
    OutputGraph=gcf;
    exportgraphics(OutputGraph,im_name,"Resolution",600);
    close(OutputFig);
   
   % close OutputFig;
%%
% figure;
% imshow(I);
% hold on;
% x_profile=x_profile./scale_factor;
% 
% y_profile=y_profile./scale_factor;
% plot(x_profile, y_profile, 'r.', 'MarkerSize', 1);
% 
% xFit=xFit./scale_factor;
% yFit=yFit./scale_factor;
% plot(xFit, yFit, 'g.', 'MarkerSize', 1);
% 
% x_outer=x_outer./scale_factor;
% y_outer=y_outer./scale_factor;
% plot(x_outer, y_outer, 'm.', 'MarkerSize', 1);
% 
% x_center=x_center/scale_factor;
% y_center=y_center/scale_factor;
% plot(x_center, y_center, 'm+', 'MarkerSize', 5);
% 
% R0=R0/scale_factor;
% hold off;

%%
%     %
%     [B,L] = bwboundaries(smoothed_image,'noholes');
% imshow(label2rgb(L, @jet, [.5 .5 .5]))
% hold on
% for k = 1:length(B)
%    boundary = B{k};
%    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 1)
% end
% %

end
%%


function [x_profile, y_profile] = extract_drop_profile(edges, scale_factor)
    % Extract the coordinates of the drop's edge
    [y, x] = find(edges);
    
    % Convert pixel coordinates to physical units (microns)
    x_profile = x * scale_factor; % microns
    y_profile = y * scale_factor; % microns
    
    % Sort the profile by y-coordinates (ascending)
    [y_profile, sort_idx] = sort(y_profile,'ascend');
    x_profile = x_profile(sort_idx);
end

function [x_apex, y_apex] = calculate_FitRegion(x_profile, y_profile)
    % Fit a circle to the apex of the drop to determine R0
    % Select the apex region (e.g., bottom 30% of the drop)
    bottom_ratio=0.5;
    apex_region = y_profile > (min(y_profile) + (1-bottom_ratio) * (max(y_profile) - min(y_profile)));
    x_apex = x_profile(apex_region);
    y_apex = y_profile(apex_region);
        
    % Fit a circle to the apex region
%    [x_outer, y_outer,xc, yc, R0] = fit_circle(x_apex, y_apex);
  
end

function beta = calculate_beta(x_profile, y_profile, R0)
    % Fit the Young-Laplace equation to the drop profile to determine beta
    % Define the theoretical drop shape function
    drop_shape_func = @(beta, x) R0 * (1 - beta * (x / R0).^2);
    
    % Perform curve fitting
    beta_initial_guess = 1; % Initial guess for beta
    beta = lsqcurvefit(drop_shape_func, beta_initial_guess, x_profile, y_profile);
end

function [x_outer, y_outer, xc, yc, R] = fit_circle(x, y)
    % This function fits a circle to input coordinates (x,y), eliminates points
    % inside the initial circle, and performs a final fit on outer points
    % This is to prevent detected edge points on the Inner side of droplet
    % from confusing the fit circle calculation

    [xc_init, yc_init, R_raw] = circle_calc_lsq(x, y);
    
    % Create new arrays x_outer and y_outer containing only points outside the circle
 
 distances = (x - xc_init).^2 + (y - yc_init).^2; %note that the 
% dist_array_debug=size(distances)
outer_region = ( distances > R_raw^2)&(y>=yc_init);
%outer_debug=size(outer_region)
%  y_outer_prelim = y(outer_region);
%  x_outer_prelim = x(outer_region);
% 
%  y_outer_final=(y_outer_prelim>=yc_init);
% 
% x_outer=x_outer_prelim(outer_region);
% y_outer=y(outer_region);
% 
%  y_profile > (min(y_profile) + (1-bottom_ratio) * (max(y_profile) - min(y_profile)));
%     x_apex = x_profile(apex_region);
%     y_apex = y_profile(apex_region);
    
 x_outer=x(outer_region);
 y_outer=y(outer_region);
 
 [xc, yc, R] = circle_calc_lsq(x_outer, y_outer);

% The below commented lines are another way to determine the outer edge points for fitting

 % ctr=1; 
 % x_outer=[];
 % y_outer=[];
 % 
 % %
 %  for i=1:length(y)
 %    distance = (x(i) + xc_init).^2 + (y(i) + yc_init).^2; %calculate euclidian distance^2 to each point
 % 
 %        if distance >=R_raw^2  % If the distance^2 to point from initial fit circle center is > R^2
 %         x_outer(ctr,:)=x(i); %this means that the x and y coordinates are OUTSIDE the initial guess circle
 %         y_outer(ctr,:)=y(i); % so this means that this is an 'Outer' edge point, so we save it to find ACTUAL circle
 %         ctr=ctr+1; % Since the number of points is unknown, we just save each new discovered point
 %        end
 %  end
 % %
   
    % Step 4: Final least squares circle fitting on outer points
    % Using least squares geometric fit for highest accuracy [[15]]
   % [xc, yc, R] = circle_calc_lsq(x_outer, y_outer);

end
%%
function dS=dS_Calc(x_profile, y_profile, xFit, yFit, x_outer, y_outer,xc, yc, R,OutputFig)
    % Create a new figure
figure(OutputFig);
%hold on;
subplot(1, 2, 2,"replace");

% Plot entire edge of droplet detected
    scatter(x_profile, y_profile, 20, 'filled', 'MarkerEdgeColor', [0 0.7 0], ...
        'MarkerFaceColor', [0 0.9 0], ...
        'DisplayName', 'Droplet Contour');
    hold on;
    
    % Plot bottom contour points for the Fitting circle
    scatter(xFit, yFit, 15, 'filled', 'MarkerEdgeColor', [0 0.7 0.7], ...
        'MarkerFaceColor', [0.0 0.85 0.85], ...
        'DisplayName', 'Region Searched for Fitting');

   % Plot bottom contour points for the Fitting circle
    scatter(x_outer, y_outer, 8, 'filled', 'MarkerEdgeColor', [0.7 0 0.7], ...
        'MarkerFaceColor', [0.7 0.7 0], ...
        'DisplayName', 'Pts for Circle Fit');

    
    % Generate points for the circle using parametric equations
    theta = linspace(0, 2*pi, 100); % 100 points for smooth circle
    x_circle = xc + R * cos(theta);
    y_circle = yc + R * sin(theta);
    
    % Plot the fitted circle
    plot(x_circle, y_circle, 'LineWidth', 2, ...
        'Color', [0 0.4470 0.7410], ...
        'DisplayName', 'Fitted Circle');
       
    % Plot the center point
    plot(xc, yc, 'k+', 'LineWidth', 2, 'MarkerSize', 16, ...
        'DisplayName', 'Circle Center');
    
    plot(xc, max(y_profile), 'r+', 'LineWidth', 2, 'MarkerSize', 12, ...
        'DisplayName', 'Detected Droplet Bottom');

    y_dS=max(y_profile)-(2*R) - abs(max(y_profile)-R-yc);
 %  y_dS=yc-R;
  
  plot(xc, y_dS, 'm+', 'LineWidth', 2, 'MarkerSize', 12, ...
        'DisplayName', 'dS Location');

    %  R = R_raw + abs(max(y)-R_raw+yc);    
%  R = R + abs(max(y)-R+yc);

    % Add labels and title
    xlabel('X-axis', 'FontSize', 12);
    ylabel('Y-axis', 'FontSize', 12);
    title('Contour Points with Fitted Circle', 'FontSize', 14);
    
    % Add legend
    legend('Location', 'bestoutside');
   
    % Add text showing circle parameters
    text_str = sprintf('Center: (%.5f, %.5f)\nRadius: %.5f', xc, yc, R);
    text(min(x_profile), max(y_profile), text_str, 'VerticalAlignment', 'top', ...
        'FontSize', 10, 'BackgroundColor', 'white');

    % Make the plot look nice
    grid on;
    axis equal; % This ensures the circle appears circular and not elliptical
        
   % hold off;

 
    % dS value computation test  
%    Y_Cutoff1=(max(y)-(2*R)-(max(y)-R))*1.00001;
Y_Cutoff1=y_dS*1.01;
  %  Y_Cutoff2=(max(y)-(2*R)-(max(y)-R))*0.99999;
Y_Cutoff2=y_dS*0.99;

    % Find indices where y equals the target value (within some tolerance)
 %   tolerance = 1e-10; % Adjust tolerance as needed
    %indices = find(y>=Y_Cutoff2 & y<=Y_Cutoff1);
    indices1 = find(y_profile>=Y_Cutoff1);
    indices2 = find(y_profile>=Y_Cutoff2);

    % indx1_start=min(indices1);
    % indx1_end=max(indices1);
    % indx2_start=min(indices2);
    % indx2_end=max(indices2);
    
    indices=[min(indices2):1:min(indices1)];
    x_val_Temp = x_profile(indices);
    xVal_left=x_val_Temp(x_val_Temp<xc);
    xVal_right=x_val_Temp(x_val_Temp>xc);

    x_Debug = x_profile(indices);
    y_Debug= y_profile(indices);
    plot(x_Debug, y_Debug,'bo', 'LineWidth', 1, 'MarkerSize', 8, ...
        'DisplayName', 'dS Calc Identified Pts');

    xVal_meanL=mean(xVal_left);
    xVal_meanR=mean(xVal_right);
    xVal_minL=min(xVal_left);
    xVal_maxR=max(xVal_right);

    % plot(xVal_minL, (max(y)-2*R),'ko', 'LineWidth', 1, 'MarkerSize', 8, ...
    %     'DisplayName', 'dS Calc Identified Pts');
    % plot(xVal_maxR, (max(y)-2*R),'ro', 'LineWidth', 1, 'MarkerSize', 8, ...
    %     'DisplayName', 'dS Calc Identified Pts');
    
    
    %dS=abs(xVal_meanR-xVal_meanL);
    dS=abs(xVal_maxR-xVal_minL);
    plot([xVal_minL xVal_maxR],[y_dS y_dS],'m-', 'LineWidth', 1.5,...
        'DisplayName', 'dS parameter Line');
    hold off

   
end

function [xc, yc, R] = circle_calc_lsq(x, y)
    % Fit a circle to a set of points (x, y)
    % Using the least-squares method
    A = [-2*x, -2*y, ones(size(x))];
    b = -(x.^2 + y.^2);
    params = A \ b;
    xc = params(1);
    yc = params(2);
    R = sqrt((xc^2 + yc^2) - params(3));
end