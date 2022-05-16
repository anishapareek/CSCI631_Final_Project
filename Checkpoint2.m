function Checkpoint2()

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
        card_identification(im_new);
    end

    function card_identification(im)
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
        boxes(:,1) = boxes(:,1);
        boxes(:,2) = boxes(:,2);
        boxes(:,3) = boxes(:,3);
        boxes(:,4) = boxes(:,4);
        count = 1;
        %demonstrate every card
        figure();
        for i = 1 : size(boxes,1)
            if(boxes(i,3)*boxes(i,4)>200000)
                subplot(4,3,count);
                count = count + 1;
                ima = im(fix(boxes(i,2)):fix(boxes(i,2)+boxes(i,4)),fix(boxes(i,1)):fix((boxes(i,1)+boxes(i,3))),:);
                [color] = color_identification(ima);
                imshow(ima);
                title(color);
            end
        end
    end

    function [color] = color_identification(im)
        imhsv = rgb2hsv(im);
        red = 0;
        green = 0;
        magenta = 0;
        for col = 1:size(imhsv,2)
            for row = 1:size(imhsv,1)
                if(imhsv(row,col,2)>0.2)
                    if(imhsv(row,col,1)>0.3 &&imhsv(row,col,1)<0.5)
                        green = green + 1;
                    elseif(imhsv(row,col,1)>0.9 ||imhsv(row,col,1)<0.1)
                        red = red + 1;
                    elseif(imhsv(row,col,1)>0.7 &&imhsv(row,col,1)<0.9)
                        magenta = magenta +1;
                    end
                end
            end
        end
        
        if(red > green && red > magenta)
            color = 'red';
        elseif(green > magenta)
            color = 'green';
        else
            color = 'magenta';
        end
    end
end