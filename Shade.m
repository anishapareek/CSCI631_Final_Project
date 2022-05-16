function Shade()

MS = 5;
LW = 4;
FS = 22;
% IDX = 10;

addpath('./TEST_IMAGES');
 file_list = dir('./TEST_IMAGES/*.jpg');
 for fcounter = 1 : length( file_list )
%    fcounter = IDX;
   path_prefix = file_list(fcounter).folder;
   fn = file_list(fcounter).name;
   fn = strcat(path_prefix, '/', fn);
   process_image(fn);
   if(fcounter >= IDX)
       break
   end
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
            if(boxes(i,3)*boxes(i,4)>100000)

                subplot(4,3,count);
                count = count + 1;
                ima = im(fix(boxes(i,2)):fix(boxes(i,2)+boxes(i,4)),fix(boxes(i,1)):fix((boxes(i,1)+boxes(i,3))),:);
                [color] = color_identification(ima);
                [shading] = shade_dientification(ima);
                imshow(ima);
                t = sprintf("Color:%s, Shading:%s",color,shading);
                title(t);
            end
        end
    end

    function [color] = color_identification(im)
        [nx,ny,~] = size(im);
        center = round([nx,ny]/2);
        imc = im(center(1)-150:center(1)+150,center(2)-150:center(2)+150,:);
        imhsv = rgb2hsv(imc);
        red = 0;
        green = 0;
        magenta = 0;
%         [dx,dy,~] = size(imhsv);
%         imre = zeros(dx,dy);
        for col = 1:size(imhsv,2)
            for row = 1:size(imhsv,1)
                if(not((imhsv(row,col,1)< 0.2 && imhsv(row,col,2)< 0.3 && imhsv(row,col,3) > 0.6) || imhsv(row,col,2)< 0.1))
                    if(imhsv(row,col,1)>0.3 &&imhsv(row,col,1)< 0.5)
                        green = green + 1;
%                         imre(row,col) = 1;
                    elseif((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.1) && imhsv(row,col,2) >= 0.4)
                        red = red + 1;
%                         imre(row,col) = 2;
                    elseif(imhsv(row,col,1)>0.6 && imhsv(row,col,1)<=0.95 || ((imhsv(row,col,1)>0.95 ||imhsv(row,col,1)<0.1) && imhsv(row,col,2) < 0.4))
                        magenta = magenta +1;
%                         imre(row,col) = 3;
                    end
                end
            end
        end
%         figure();
%         subplot(1,2,1)
%         imagesc(imre);
%         colormap("gray");
%         colorbar();
%         subplot(1,2,2)
%         imshow(im);
        if(red > green && red > magenta)
            color = 'Red';
        elseif(green > magenta)
            color = 'Green';
        else
            color = 'Magenta';
        end
%         disp(red + " " + green + " " + magenta);
    end

    function [shading] = shade_dientification(im)
                [nx,ny,~] = size(im);
                center = round([nx,ny]/2);
                imc = im(center(1)-90:center(1)+90,center(2)-10:center(2)+10,:);
                imhsv = rgb2hsv(imc);
                [nx,ny,~] = size(imhsv);
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
%                 imbwc = imopen(imbwc,strel('line',2,90));

                scounter = 0;
                for col = 1:size(imbwc,2)
                    for row = 1:size(imbwc,1)
                        if(imbwc(row,col)==1)
                            scounter = scounter + 1;
                        end
                    end
                end
%                 figure();
%                 subplot(1,2,1)
%                 imagesc(imbwc);
%                 colormap("gray");
%                 subplot(1,2,2)
%                 imshow(im);
                title(scounter);
                if(scounter < 600)
                    shading = "Open";
                elseif(scounter < 2200)
                    shading = "Striped";
                else
                    shading = "Solid";
                end
%                 shading = int2str(scounter);
    end
end