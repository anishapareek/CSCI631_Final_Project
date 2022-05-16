function Checkpoint1()
addpath('.\TEST_IMAGES');
 file_list = dir('.\TEST_IMAGES\*.jpg');
 for counter = 1 : length( file_list )
   fn = file_list(counter).name;
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
        %demonstrate every card
        for i = 1 : size(boxes,1)
            if(boxes(i,3)*boxes(i,4)>200000)
                subplot(4,3,count);
                count = count + 1;
                imshow(im(fix(boxes(i,2)):fix(boxes(i,2)+boxes(i,4)),fix(boxes(i,1)):fix((boxes(i,1)+boxes(i,3))),:));
            end
        end
    end
end