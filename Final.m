function Final()

%the index of image you want to start at
IDX = 1;

addpath('./TEST_IMAGES');
%read in every target image
file_list = dir('./TEST_IMAGES/*.jpg');
for fcounter = IDX : length( file_list )
    path_prefix = file_list(fcounter).folder;
    fn = file_list(fcounter).name;
    fn = strcat(path_prefix, '/', fn);
    %call main prediction method
    process_image(fn);
    pause(2);
end

    function process_image(fn)

    im = imread(fn);

    %binarize
    im_bw = imbinarize(im(:,:,1),graythresh(im));

    %clear background
    im_bw = imclearborder(im_bw,4);

    %clean white dots
    im_bw = imopen(im_bw,strel('disk',10));

    %find bounding box
    s = regionprops(im_bw,'Centroid','BoundingBox');
    boxes = cat(1,s.BoundingBox);

    %enlarge bounding box
    boxes(:,1) = boxes(:,1)- 50;
    boxes(:,2) = boxes(:,2)- 50;
    boxes(:,3) = boxes(:,3)+ 100;
    boxes(:,4) = boxes(:,4)+ 100;
    count = 1;

    % Initilaize arrays to store the x and y values of the cards
    x_min_val = ones(1, 12);
    x_max_val = ones(1, 12);
    y_min_val = ones(1, 12);
    y_max_val = ones(1, 12);

    %demonstrate every card
    for i = 1 : size(boxes,1)
        if(boxes(i,3)*boxes(i,4)>200000)

            % Get the values for x and y coordinates of the cards
            x_min_val(count) = fix(boxes(i,1));
            x_max_val(count) = fix(boxes(i,1)+boxes(i,3));
            y_min_val(count) = fix(boxes(i,2));
            y_max_val(count) = fix(boxes(i,2)+boxes(i,4));
            count = count + 1;
        end
    end

    % sort the x values for the leftmost corner of the cards
    x_min_val = sort(x_min_val);

    % sort the x values for the rightmost corner of the cards
    x_max_val = sort(x_max_val, 'descend');

    % sort the y values for the top corner of the cards
    y_min_val = sort(y_min_val);

    % sort the y values for the bottom corner of the cards
    y_max_val = sort(y_max_val, 'descend');

    top_row_xmin = x_min_val(3);  % top left x-coord
    top_row_xmax = x_max_val(3);  % top right x-coord
    xmin = x_min_val(1);  % bottom left x-coord
    xmax = x_max_val(1);  % bottom right x-coord
    ymin = y_min_val(1);  % top y-coord
    ymax = y_max_val(1);  % bottom y-coord

    % Initial boundary points
    xy_pts_in = [xmin  top_row_xmin  top_row_xmax  xmax;
        ymax  ymin  ymin  ymax];
    % Output points
    uv_pts_out = [top_row_xmin  top_row_xmin  top_row_xmax  top_row_xmax;
        ymax  ymin  ymin  ymax];
    input_pts = [xy_pts_in(1, :).', xy_pts_in(2, :).'];
    output_pts = [uv_pts_out(1, :).', uv_pts_out(2, :).'];

    t_cards = fitgeotrans(input_pts, output_pts, 'projective');

    % Move all the pixels into a new image
    im_rectified = imwarp(im, t_cards, 'OutputView', imref2d(size(im)));

    %        figure();
    %        imshow(im_rectified);
    %        axis image;

    % crop the image
    xs_crop = round(uv_pts_out(1,:));
    ys_crop = round(uv_pts_out(2, :));
    % rectify the image
    im_new = im_rectified(ys_crop(2):ys_crop(1), xs_crop(1):xs_crop(3), :);

    card_identification(im_new);
    end

    function card_identification(im)
    %binarize
    im_bw = imbinarize(im(:,:,1),graythresh(im)^2);

    %clean white dots
    im_bw = imopen(im_bw,strel('disk',10));
    %find bounding box
    s = regionprops(im_bw,'Centroid','BoundingBox');
    boxes = cat(1,s.BoundingBox);
    count = 1;
    %demonstrate every card
    figure();
    for i = 1 : size(boxes,1)
        if(boxes(i,3)*boxes(i,4)>100000)
            subplot(4,3,count);
            count = count + 1;
            dims = size(im_bw);

            %solve the issue when the bounding box is touching the
            %edge.
            ny1 = fix(boxes(i,2)+boxes(i,4));
            ny2 = fix(boxes(i,2));
            nx1 = fix((boxes(i,1)+boxes(i,3)));
            nx2 = fix(boxes(i,1));
            if(ny1 > dims(1))
                ny1 = dims(1);
            end
            if(nx1 > dims(2))
                nx1 = dims(2);
            end
            if(ny2 < 1)
                ny2 = 1;
            end
            if(nx2 < 1)
                nx2 = 1;
            end

            ima = im(ny2:ny1,nx2:nx1,:);
            %do color identification
            [color] = color_identification(ima);
            %do shape and number identification
            [shape,num] = take_out_the_shape(ima);
            %do shading identification
            [shading] = shade_identification(ima,num);
            imshow(ima);
            axis image;
            %display our result as the title of individual cards
            t = sprintf("Color:%s, Shading:%s, Shape:%s, Number:%d",color,shading,shape,num);
            title(t);
        end
    end
    end

    function [color] = color_identification(im)
    [nx,ny,~] = size(im);
    center = round([nx,ny]/2);
    %find the center cur of the image for better performance
    imc = im(center(1)-150:center(1)+150,center(2)-150:center(2)+150,:);

    %convert the image into hsv color space
    imhsv = rgb2hsv(imc);
    red = 0;
    green = 0;
    magenta = 0;

    for col = 1:size(imhsv,2)
        for row = 1:size(imhsv,1)
            %if current pixel is not a background
            if(not((imhsv(row,col,1)< 0.15 && imhsv(row,col,2)< 0.3 && imhsv(row,col,3) > 0.6) || imhsv(row,col,2)< 0.1))
                %if the current pixel is green
                if(imhsv(row,col,1)>0.3 &&imhsv(row,col,1)< 0.5)
                    green = green + 1;
                    %if the current pixel is red
                elseif((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.1) && imhsv(row,col,2) >= 0.4)
                    red = red + 1;
                    %if the current pixel is magenta or dark red
                elseif(imhsv(row,col,1)>0.6 && imhsv(row,col,1)<=0.95 || ((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.1) && imhsv(row,col,2) < 0.4))
                    magenta = magenta +1;
                end
            end
        end
    end

    %find out which bin has the most votes and assign that color to our
    %result.
    if(red > green && red > magenta)
        color = 'Red';
    elseif(green > magenta)
        color = 'Green';
    else
        color = 'Magenta';
    end
    end

    function [shading,num] = shade_identification(im,num)
    [nx,ny,~] = size(im);
    %binarize the input image
    im = modified_binarize(im);

    %focuse on a single shape
    center = round([nx,ny]/2);
    if num == 2
        imc = im(center(1) + 40:center(1)+140,center(2)-10:center(2)+10,:);
    else
        imc = im(center(1)-50:center(1)+50,center(2)-10:center(2)+10,:);
    end
    [imbwc] = imc;

    %count colored pixels at target area
    scounter = 0;
    for col = 1:size(imbwc,2)
        for row = 1:size(imbwc,1)
            if(imbwc(row,col)==1)
                scounter = scounter + 1;
            end
        end
    end

    % use the colored area ratio to determine the shading
    if(scounter < 0.2 * size(imbwc,1) * size(imbwc,2))
        shading = "Open";
    elseif(scounter < 0.9 * size(imbwc,1) * size(imbwc,2))
        shading = "Striped";
    else
        shading = "Solid";
    end
    end

    function [imbwc] = modified_binarize(im)
    [nx,ny,~] = size(im);
    %convert the input image to hsv
    imhsv = rgb2hsv(im);
    %initialize the result image
    imbwc = ones(nx,ny);
    avg_val = 0;
    %calculate the average value
    for col = 1:size(imhsv,2)
        for row = 1:size(imhsv,1)
            avg_val = avg_val + imhsv(row,col,3);
        end
    end
    avg_val = avg_val / (nx*ny);

    %mark non colored area as zero
    for col = 1:size(imbwc,2)
        for row = 1:size(imbwc,1)
            %a method to determine whether a pixel is colored.
            if(imhsv(row,col,1)< 0.2 && imhsv(row,col,2)< 0.22 && (imhsv(row,col,3) - avg_val) > 0)
                imbwc(row,col) = 0;
            end
        end
    end
    end

%identify shape using fft
    function [shape,num] = shape_identification(im)

    %binarize
    [imbw] = modified_binarize(im);

    %clean up the image
    imbw = imclose(imbw, strel('diamond', 20));
    imbw = imclearborder(imbw);
    imbw = imfill(imbw,'holes');
    imlb = bwlabel(imbw,4);

    %find the number of patterns
    num = max(imlb(:));
    imbw(imlb ~= 1) = 0;

    %initialize result list
    shapes = ["diamond" "squiggle" "oval"];

    %initialize the maximum ot a small value
    maxv = -25623;
    maxi = 0;
    for target = 1:3

        %read target image
        if target == 1
            im_of_target = im2double(imread('./target_shapes/filled_diamond.jpg'));
        end

        if target == 2
            im_of_target = im2double(imread('./target_shapes/filled_squiggle.jpg'));
        end

        if target == 3
            im_of_target = im2double(imread('./target_shapes/oval.jpeg'));
        end

        %make the target image slightly smaller to fit the input.
        im_of_target = imresize(im_of_target,0.9);
        im_of_target = modified_binarize(im_of_target);

        % make this a difference filter
        im_of_target = im_of_target - mean(im_of_target(:));

        [orig_rows, orig_cols] = size(imbw);

        %take edges from both images
        edges_im = edge(imbw, 'Canny', [0.0025, 0.05]);
        edges_pattern = edge(im_of_target, 'Canny');

        %calculate cross power spectrum
        im_fft2 = fft2( edges_im  );
        pattern_fft2 = fft2( edges_pattern,orig_rows,orig_cols);

        results_fft2 = real(ifft2((im_fft2.*conj(pattern_fft2))./abs(im_fft2.*conj(pattern_fft2))));
        maximax = max(abs(results_fft2(:)));

        if maxv == -25623
            maxv = maximax;
            maxi = target;
        end

        %reduce the likelyhood to give oval as result
        if target == 3
            maximax = 0.7* maximax;
        end

        %find maximum target
        if maxv <= maximax
            maxv = maximax;
            maxi = target;
        end
    end

    %assign out result
    shape  = shapes(maxi);
    end % end shape identification

    function [shape,num] = take_out_the_shape(im)

    %convert the image to double and blur it a little bit
    im = im2double(im);
    im = imfilter(im,fspecial('gaussian',2));

    %turn the image into hsv colorspace
    imhsv = rgb2hsv(im);
    %brighten up colored part and darken the background
    for col = 1:size(imhsv,2)
        for row = 1:size(imhsv,1)
            if(not((imhsv(row,col,1)< 0.14 && imhsv(row,col,2)< 0.3 && imhsv(row,col,3) > 0.6) || imhsv(row,col,2)< 0.1))
                if(imhsv(row,col,1)>0.3 &&imhsv(row,col,1)< 0.5)
                    imhsv(row,col,3) = imhsv(row,col,3)+ 0.5;
                elseif((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.1) && imhsv(row,col,2) >= 0.4)
                    imhsv(row,col,3)= imhsv(row,col,3)+ 0.5;
                elseif(imhsv(row,col,1)>0.7 && imhsv(row,col,1)<=0.95 || ((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.2) && imhsv(row,col,2) < 0.4))
                    imhsv(row,col,3)= imhsv(row,col,3) + 0.5;
                end
            else
                imhsv(row,col,3)= 0.5 * imhsv(row,col,3);
            end
        end
    end
    %bring the hsv image to grayscale
    im = hsv2rgb(imhsv);
    im = rgb2gray(im);
    im = imadjust(im);
    im = imclearborder(im);

    %binarize
    im_bw = imbinarize(im,graythresh(im)^2);

    %clean up the image
    se = strel('disk',2);
    im_bw = imopen(im_bw,se);

    %clear background
    im_bw = imclearborder(im_bw,4);
    se = strel('disk',2);
    afterOpening = imclose(im_bw,se);

    % clean the image by removing the areas which have less than 1000 bright pixels
    b_im = bwareaopen(afterOpening, 1000);
    se = strel('disk',10);

    %find the number of shapes
    im_lb = bwlabel(b_im);
    num = max(im_lb(:));

    %if no shape is detected, return undecided
    if num == 0
        shape = "undecided";
        return
    end
    s = regionprops(b_im,'Area');
    area_white = s.Area;

    %imcomplement the image if the background is white
    if area_white > 200000
        b_im = imcomplement(b_im);
    end

    %Clean up again
    binary_im = imclose(b_im, se);
    %imcomplement the image if the background is white
    s = regionprops(binary_im,'Area');
    area_white = s.Area;
    if area_white > 300000
        binary_im = imcomplement(binary_im);
    end
    %Remove noises
    binary_im = bwareaopen(binary_im, 3500);

    %find the number of shapes
    im_lb = bwlabel(binary_im);
    num = max(im_lb(:));

    %get a single shape from the image
    binary_im = bwareafilt(binary_im,1, 'smallest');
    %fill the shape
    binary_im = imfill(binary_im, 'holes');

    %calculate extent of the target shape
    s = regionprops(binary_im, 'Extent');
    if num == 0
        shape = "undecided";
        return
    end
    extent = s.Extent;
    %Do prediction
    shape = predict_shape(extent);
    end

    function [shape] = predict_shape(extent)
    %Predict according to our observation
    if extent > 0.8
        shape = "Oval";
    elseif extent > 0.55
        shape = "Squiggle";
    else
        shape = "Diamond";
    end
    end
end