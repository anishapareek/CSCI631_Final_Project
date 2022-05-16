function shape_detection()

    MS = 5;
    LW = 4;
    FS = 22;

    addpath('./TEST_IMAGES');
    file_list = dir('./TEST_IMAGES/*.jpg');
    for counter = 1 : length( file_list )
       path_prefix = file_list(counter).folder;
       fn = file_list(counter).name;
       fn = strcat(path_prefix, '/', fn);
       process_image(fn);
    end
%     fn = 'IMG_7664.JPG';
%     process_image(fn);
end


function take_out_the_shape(im)
    b_im = im(:,:,1) < 225;
    se = strel('disk',10);
%     figure();
%     imshow(binary_im);
    
    s = regionprops(b_im,'Area');
    area_white = s.Area;
        
    if area_white > 200000
        b_im = imcomplement(b_im);
    end
    
    
    binary_im = imclose(b_im, se);
%     figure();
%     imshow(binary_im);
    s = regionprops(binary_im,'Area');
    area_white = s.Area;
    if area_white > 300000
        binary_im = imcomplement(binary_im);
    end
    binary_im = bwareaopen(binary_im, 3500);

    binary_im = bwareafilt(binary_im,1, 'smallest');
%     figure();
%     imshow(binary_im);
    
    binary_im = imfill(binary_im, 'holes');
    figure();
    imshow(binary_im);
    
    s = regionprops(binary_im, 'Extent');
    extent = s.Extent;
    predict_shape(extent);
    disp('');
end

function predict_shape(extent)
    if extent > 0.8
       disp('Ellipse');
    elseif extent > 0.55
        disp('Squiggle');
    else
        disp('Diamond');
    end
end

function process_image(fn)

    MS = 5;
    LW = 4;
    FS = 22;
        
%         hough
        im = imread(fn);
        
        %binarize
        im_bw = imbinarize(im(:,:,3),graythresh(im));
        
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
                
                                subplot(4,3,count);
                count = count + 1;
                imshow(im(fix(boxes(i,2)):fix(boxes(i,2)+boxes(i,4)),fix(boxes(i,1)):fix((boxes(i,1)+boxes(i,3))),:));
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
       plot(xy_pts_in(1,:), xy_pts_in(2,:), 'cd-', 'MarkerSize', MS, 'LineWidth', LW, 'MarkerFaceColor', 'c'); 
       
       % Output points
       uv_pts_out = [top_row_xmin  top_row_xmin  top_row_xmax  top_row_xmax;
                    ymax  ymin  ymin  ymax];
       
       plot(uv_pts_out(1,:), uv_pts_out(2,:), 'cd-', 'MarkerSize', MS, 'LineWidth', LW, 'MarkerFaceColor', 'r'); 
              
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
       hold on; 
       
       plot(xs_crop, ys_crop, 'r-', 'LineWidth', 8);
       
       % rectify the image
       im_new = im_rectified(ys_crop(2):ys_crop(1), xs_crop(1):xs_crop(3), :);
%        figure();
%        imagesc(im_new);
%        axis image;
%        title('Rectified and cropped image', 'FontSize', FS);
        get_each_card(im_new);
    end

function get_each_card(fn)

        im = fn;
        
        %binarize
        im_bw = imbinarize(im(:,:,1),graythresh(im));
%         im_bw = rgb2gray(im);
%         im_bw = imbinarize(im_bw);

%         im_bw = imbinarize(im);
        
        %clear background
        im_bw = imclearborder(im_bw,4);
        
        se = strel('disk',5);
        afterOpening = imclose(im_bw,se);
    
        % clean the image by removing the areas which have less than 1000 bright pixels
        cleaned_im = bwareaopen(afterOpening, 1000);
        im_bw = cleaned_im;
        
        %clean white dots
%         im_bw = imopen(im_bw,strel('disk',10));
        [labeled_im, num_dice] = bwlabel(im_bw);
        
        %find bounding box
        bboxes = regionprops(im_bw,'Centroid','BoundingBox');
        
        for index = 1:length(bboxes)
            current_bbox = bboxes(index).BoundingBox;
            y = floor(current_bbox(1));
            x = floor(current_bbox(2));
            w = ceil(current_bbox(3));
            h = ceil(current_bbox(4));
            [rows, columns , ~] = size(labeled_im);
            xmin = x-10;
            xmax = x+w+200;
            ymin = y-10;
            ymax = y+h-125;
            if xmin < 0
                xmin = x;
            end
            if xmax > rows
                continue;
            end
            if ymin < 0
                ymin = y;
            end
            if ymax > columns
                continue;
            end

%             im_subset = labeled_im(xmin:xmax, ymin:ymax);
            im_subset = im(xmin:xmax, ymin:ymax);
            
            
            im_subset = im2gray(im_subset);
            im_subset = imadjust(im_subset);
%             figure();
%             imshow(im_subset);
            take_out_the_shape(im_subset);
        end

end
