clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;

%% [image processing toolbox] 체크하는 부분
% Check that user has the Image Processing Toolbox installed.
hasIPT = license('test', 'image_toolbox');   % license('test','Statistics_toolbox'), license('test','Signal_toolbox')
if ~hasIPT
  % User does not have the toolbox installed.
  message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
  reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
  if strcmpi(reply, 'No')
    % User said No, so exit.
    return;
  end
end
%===============================================================================

%% 이미지 읽어들이는 부분 => 이부분을 드론에서 받아오는거로 바꾸면 됨
% Read in gray scale demo image.
folder = pwd;
% baseFileName = '1.jpeg';
% baseFileName = '7.jpg';
baseFileName = 'a (1).jpg';
% Get the full filename, with path prepended.
fullFileName = fullfile(folder, baseFileName);
% Check if file exists.
if ~exist(fullFileName, 'file')
  % File doesn't exist -- didn't find it there.  Check the search path for it.
  fullFileNameOnSearchPath = baseFileName; % No path this time.
  if ~exist(fullFileNameOnSearchPath, 'file')
    % Still didn't find it.  Alert user.
    errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
    uiwait(warndlg(errorMessage));
    return;
  end
end

%% 받아온 이미지를 grayscale 로 바꾸는 부분
grayImage = imread(fullFileName);
% Get the dimensions of the image.  
% numberOfColorBands should be = 1.
[rows, columns, numberOfColorChannels] = size(grayImage);
if numberOfColorChannels > 1
  % It's not really gray scale like we expected - it's color.
  % Convert it to gray scale by taking only the green channel.
  grayImage = grayImage(:, :, 2); % Take green channel.
end


%% 바꾼 이미지를 matlab 상에 plot하는 부분. [이부분은 실제 구현시에는 생략]
% Display the image.
subplot(2, 2, 1);
imshow(grayImage, []);
title('Original Grayscale Image', 'FontSize', fontSize, 'Interpreter', 'None');
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 
% Let's compute and display the histogram.

%% Plot filled Image
% grayImage = imfill(grayImage);
subplot(2, 2, 2);
imshow(grayImage, []);
title('Filled Grayscale Image', 'FontSize', fontSize, 'Interpreter', 'None');
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 
% Let's compute and display the histogram.


%% Binary Image의 민감도 조절
subplot(2, 2, 4); 
histogram(grayImage, 0:256);
grid on;
title('Histogram of original image', 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Gray Level', 'FontSize', fontSize);
ylabel('Pixel Count', 'FontSize', fontSize);
xlim([0 255]); % Scale x axis manually.
% Threshold and binarize the image
binaryImage = grayImage > 180;  %여기서 민감도를 조절해줘. 조절해서 진행해야함
% binaryImage = binaryImage < 250;  %여기서 민감도를 조절해줘. 조절해서 진행해야함
% binaryImage = imfill(binaryImage);
% Display the image.
subplot(2, 2, 3);
imshow(binaryImage, []);
axis on;
title('Binary Image', 'FontSize', fontSize, 'Interpreter', 'None');

%% 각 사각형의 property 뽑는 부분
% Label the image
labeledImage = bwlabel(binaryImage);
% Get the orientation

measurements = regionprops(labeledImage, 'Area','Orientation','FilledImage', 'MajorAxisLength', 'Centroid','Extrema','Circularity');
measurements = [measurements(709) , measurements(775)];
allAngles = -[measurements.Orientation]; % 이미지의 각도. 음수로 표시됨. 실제 드론에서 받아들이는거를 기준으로 수정 필요
allPoints_1 = [measurements(1).Extrema]; % 꼭짓점 (8개) 구함. 8개라서 겹치는거 있음
allPoints_2 = [measurements(2).Extrema]; % 꼭짓점 (8개) 구함. 8개라서 겹치는거 있음

%% 경사각 계산
d1 = zeros(1,8); d2 = zeros(1,8);
for i = 1 : 8 %각 모서리 길이 구하기
    if i ~= 8
        d1(i) = sqrt( (allPoints_1(i,1)-allPoints_1(i+1,1))^2 + (allPoints_1(i,2)-allPoints_1(i+1,2))^2);
        d2(i) = sqrt( (allPoints_2(i,1)-allPoints_2(i+1,1))^2 + (allPoints_2(i,2)-allPoints_2(i+1,2))^2);
    else
        d1(i) = sqrt( (allPoints_1(i,1)-allPoints_1(1,1))^2 + (allPoints_1(i,2)-allPoints_1(1,2))^2);
        d2(i) = sqrt( (allPoints_2(i,1)-allPoints_2(1,1))^2 + (allPoints_2(i,2)-allPoints_2(1,2))^2);
    end
end
d1 = sort(d1,'descend'); d1 = d1(1:4); %내림차순 정리 후 중복 제거
d2 = sort(d2,'descend'); d2 = d2(1:4); %내림차순 정리 후 중복 제거

incline = [acosd((d1(3)+d1(4))/(d1(1)+d1(2))), acosd((d2(3)+d2(4))/(d2(1)+d2(2)))];
incline_angle = sum(incline)/2;

%% matlab 상에서 plot하는 부분. 실제 드론에서 구현시 없어도 된다
hold on;
center_point = [];
for k = 1 : length(measurements)
  fprintf('For blob #%d, the angle = %.4f\n', k, allAngles(k));
  xCenter = measurements(k).Centroid(1);
  yCenter = measurements(k).Centroid(2);
  % Plot centroids.
  plot(xCenter, yCenter, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
  % Determine endpoints
  axisRadius = measurements(k).MajorAxisLength / 2;
  x1 = xCenter + axisRadius * cosd(allAngles(k));
  x2 = xCenter - axisRadius * cosd(allAngles(k));
  y1 = yCenter + axisRadius * sind(allAngles(k));
  y2 = yCenter - axisRadius * sind(allAngles(k));
  
  x3 = xCenter + axisRadius * cosd(allAngles(k)+90);
  x4 = xCenter - axisRadius * cosd(allAngles(k)+90);
  y3 = yCenter + axisRadius * sind(allAngles(k)+90);
  y4 = yCenter - axisRadius * sind(allAngles(k)+90);
  
  center_point = [center_point, [xCenter; yCenter]];

  fprintf('x1 = %.2f, y1 = %.2f, x2 = %.2f, y2 = %.2f\n\n', x1, y1, x2, y2);
  plot([x1, x2], [y1, y2], 'r-', 'LineWidth', 2);
  plot([x3, x4], [y3, y4], 'b-', 'LineWidth', 2);
end

% 정렬각 계산
align = - rad2deg(atan2(center_point(2,1) - center_point(2,2),center_point(1,1) - center_point(1,2)));

%% 해당 그림의 극점(꼭짓점)이 어딘지 plot하는 부분. 실제 구현시 필요 없음
figure(2)
plot(allPoints_1(:,1),allPoints_1(:,2),allPoints_2(:,1),allPoints_2(:,2));
% plot(allPoints_1(:,1),allPoints_1(:,2));
xlim([0,columns]); ylim([0,rows]);
% text_for_figure = sprintf('align angle = %.2f',rad2deg(align));
% title(text_for_figure)

figure(1)
subplot(223)
title(sprintf('Binary Image.\nIncline Angle : %.2f\nAlign Angle : %.2f',incline_angle,align));

Area = [measurements.Area];
Circles = [measurements.Circularity];
Centroids = [measurements.Centroid];
Centroids = Centroids';
Centroids = reshape(Centroids,2,[]);

maxn = maxk(Area,8);
ind = Area > (maxn(end)-1);

Area_ind = Area(ind);
Circles_ind = Circles(ind);
Centroids_ind = Centroids(:,ind);
