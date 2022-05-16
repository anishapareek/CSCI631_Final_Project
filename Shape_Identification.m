function Shape_Identification()

MS = 5;
LW = 4;
FS = 22;

addpath('./target_shapes');
addpath('./TEST_IMAGES');
file_list = dir('./TEST_IMAGES/*.jpg');
%  for counter = 1 : length( file_list )
for counter = 6 : 6
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
                %                 subplot(4,3,count);
                count = count + 1;
                ima = im(fix(boxes(i,2)):fix(boxes(i,2)+boxes(i,4)),fix(boxes(i,1)):fix((boxes(i,1)+boxes(i,3))),:);
                [color] = color_identification(ima);
                [shape] = shape_identification(ima);
                figure();
                imshow(ima);
                title(strcat(color, " ", shape));
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

    function [imbwc] = modified_binarize(im)
        [nx,ny,~] = size(im);
        imhsv = rgb2hsv(im);
        imbwc = ones(nx,ny);
        avg_val = 0;
        for col = 1:size(imhsv,2)
            for row = 1:size(imhsv,1)
                avg_val = avg_val + imhsv(row,col,3);
            end
        end
        
        avg_val = avg_val / (nx*ny);
        
        for col = 1:size(imbwc,2)
            for row = 1:size(imbwc,1)
                if(imhsv(row,col,1)< 0.2 && imhsv(row,col,2)< 0.22 && (imhsv(row,col,3) - avg_val) > -0.03)
                    imbwc(row,col) = 0;
                end
            end
        end
    end

    function [shape] = shape_identification(im)
        
        %binarize
        %         im = imbinarize(im(:,:,1),graythresh(im));
        %         im = imclose(im, strel('diamond', 5));
        [im] = modified_binarize(im);
        im = imerode(im, strel('line', 5, 90));
        
        %         figure()
        %         imagesc(im);
        %         axis image;
        %         colormap('gray');
        
%         shapes = ['diamond', 'squiggle', 'oval'];
%         targets = ['./target_shapes/filled_diamond.jpg' './target_shapes/filled_squiggle.jpg'];
        
        shape_index = 0;
        for target = 1:2
            
            if target == 1
                im_of_target = im2double(imread('./target_shapes/filled_diamond.jpg'));
            end
            
            if target == 2
                im_of_target = im2double(imread('./target_shapes/filled_squiggle.jpg'));
            end
            
            % set the pattern we are seeking
%             im_of_target = im2double(imread(targets(shape_index)));
            
            %binarize
            %         im_of_target = imbinarize(im_of_target(:,:,1),graythresh(im_of_target));
            %         im_of_target = 1 - im_of_target;
            %         im_of_target = imclose(im_of_target, strel('diamond', 5));
            [im_of_target] = modified_binarize(im_of_target);
            im_of_target = imerode(im_of_target, strel('line', 5, 90));
            
            % make this a difference filter
            im_of_target = im_of_target - mean(im_of_target(:));
            
            % pad the target pattern to be same size as image
            [orig_rows, orig_cols] = size(im);
            [rows, cols] = size(im_of_target);
            pad_by_rows = floor((orig_rows / 2) - (rows / 2));
            pad_by_cols = floor((orig_cols / 2) - (cols / 2));
            im_of_target = padarray(im_of_target, [pad_by_rows pad_by_cols], 0, 'both');
            
            [rows, cols] = size(im_of_target);
            pad_by_rows = orig_rows - rows;
            pad_by_cols = orig_cols - cols;
            im_of_target = padarray(im_of_target, [pad_by_rows pad_by_cols], 0, 'post');
            
            pattern = rot90(im_of_target, 2);
            
            % subtract the average value of the original image
            pattern = pattern - mean(im(:));
            
            % take edges from both images
            edges_im = edge(im, 'Canny', [0.0025, 0.05]);
            edges_pattern = edge(pattern, 'Canny');
            
            %         figure();
            %         subplot(1,3,1);
            %         imagesc(edges_im);
            %         subplot(1,3,2);
            %         imagesc(edges_pattern);
            %         subplot(1,3,3);
            %         imagesc(im);
            %         axis image;
            
            im_fft2 = fft2( edges_im );
            pattern_fft2 = fft2( edges_pattern );
            
            results_fft2 = im_fft2 .* pattern_fft2;
            
            results_from_convolution = fftshift(abs(ifft2(results_fft2)));
            results_from_convolution = 1 - results_from_convolution;
            
            maximax = max(max(results_from_convolution));
            
            if maximax >= 0
                if target == 1
                    shape = 'diamond';
                    return
                end
                
                if target == 2
                    shape = 'squiggle';
                    return
                end
                    
            end
            
%             figure()
%             imagesc(results_from_convolution);
%             title('convolved');
%             axis image;
%             colormap('gray');
            
        end
        
        shape = 'oval';
        
    end % end shape identification

end