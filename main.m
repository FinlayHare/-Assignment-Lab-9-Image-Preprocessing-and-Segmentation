clear; clc; close all;

imageFiles = {'/MATLAB Drive/studded_tire.jpeg', '/MATLAB Drive/summer_tire.jpg'};

THRESHOLD = 200
BRIGHT_THRESHOLD = 180

for i = 1:numel(imageFiles)

    % ---------- 1) Read & resize ----------
    I = imread(imageFiles{i});
    I = imresize(I, 0.5);   % optional scaling

    % ---------- 2) Convert to grayscale ----------
    
    Igray = rgb2gray(I);
   

    % ---------- 3) Create tire mask ----------
    
    tireMask = Igray < THRESHOLD;
    
    tireMask = imfill(tireMask, 'holes'); % Fill holes in the tire mask
    tireMask = bwareaopen(tireMask, 50);  % Remove small objects

    % ---------- 4) Candidate studs ----------
    
    cand = (Igray > BRIGHT_THRESHOLD) & tireMask;
 
    cand = bwareaopen(cand, 10); % Remove small noise
    cand = imfill(cand, 'holes'); % Fill holes in the candidate mask

    % ---------- 5) Connected components ----------
    CC = bwconncomp(cand);
    stats = regionprops(CC, 'Area', 'Perimeter', 'Eccentricity');

    % ---------- 6) Filter candidates ----------
    studMask = false(size(cand));
    studCount = 0;

    % Choose reasonable limits for your images:
    minA = 4;      % min area of a stud
    maxA = 120;    % max area of a stud
    minCirc = 0.6; % minimum circularity
    maxEcc = 0.85; % maximum eccentricity

    %end
    for k = 1:numel(stats)
    if stats(k).Area >= minA && stats(k).Area <= maxA && ...
       (4 * pi * stats(k).Area / (stats(k).Perimeter^2)) >= minCirc && ...
       stats(k).Eccentricity <= maxEcc
        studMask(CC.PixelIdxList{k}) = true; % Mark valid studs in the studMask
        studCount = studCount + 1; % Increment the stud count
    end
end

    % ---------- 7) Decision rule ----------

    isStudded = (studCount > 10);

    % ---------- 8) Visualization ----------
    figure;
    subplot(1,3,1);
    imshow(I); title(sprintf('Input: %s', imageFiles{i}), 'Interpreter','none');

    subplot(1,3,2);
    imshow(cand); title('Candidate studs (binary)');

    subplot(1,3,3);
    imshow(I); hold on;
    visboundaries(studMask, 'LineWidth', 0.7);

    if isStudded
        title(sprintf('STUDDED TIRE (studs: %d)', studCount));
    else
        title(sprintf('NON-STUDDED TIRE (studs: %d)', studCount));
    end

end
