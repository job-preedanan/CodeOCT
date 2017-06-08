clear;
clc;
close;

global pathname;
global idx;
for m =1:1
pathname = ['C:\Users\Lenovo\Desktop\OCT\OCT_Project\Publication_Dataset (Normal+AMD+DME)\NORMAL' num2str(m) '\TIFFs\8bitTIFFs\'];
mkdir(pathname,'TestingResult\applyBilaterfilt');

for n = 44:54

    idx = ['0' num2str(n)];
    ImgName = [pathname idx '.tif'];
    I=imread(ImgName);
    
    %remove white space in rows
    for i = 1:size(I,1)/2
        if length(find(I(i,:) == 255)) < 0.1*size(I,2)   %start to find non-white space row
            r1=i;
            break;
        end
    end
    for i = size(I,1):-1:size(I,1)/2 + 1
        if length(find(I(i,:) == 255)) < 0.1*size(I,2)   %start to find non-white space row
            r2=i;
            break;
        end
    end

    img0 = I(r1+10:r2-10,10:end-10);
    
    % bilateral filter 
    rgb_img(:,:,1) = img0;
    rgb_img(:,:,2) = img0;
    rgb_img(:,:,3) = img0;
    rgb_img = double(rgb_img)/255;
    Bimg = bfilter2(rgb_img);
    Bimg = Bimg(:,:,1);
    
    % Preprocessing
    img = medfilt2(img0,[5,5]);
%     figure(1),subplot(2,2,1),imshow(img);

    %% plot3d
    %Intensity3dPlot(img);
    
    %% Multilevel thresholding
    level = multithresh(Bimg,2);
    SegmentedImg = imquantize(Bimg,level);
    RGBSegmentedImg = label2rgb(SegmentedImg); %display in rgb 
%     figure(1),subplot(2,2,2),imshow(RGBSegmentedImg);
    
    layer1 = RGBSegmentedImg(:,:,3);     % high level threshold    
    layer1 = bwareaopen(layer1,100);
    layer1 = bwmorph(layer1,'fill');
    se = strel('diamond',3);
    layer1 = imerode(layer1,se);
    layer1 = imdilate(layer1,se);
    layer1_skel = edge(layer1,'canny');
    
    layer2 = RGBSegmentedImg(:,:,2);     % low level threshold 
    layer2 = FindMaxRegion(layer2);       
    layer2 = bwmorph(layer2,'fill');
    layer2_skel = edge(layer2,'canny');
  
    %% finding  Layers    
    img2(:,:,1) = img;
    img2(:,:,2) = img;
    img2(:,:,3) = img;
    RPE_layer = layer1_skel;
    choroid = img;                      %copy gray img
    ILM_layer = layer2_skel;
    
    for j = 1:size(layer1_skel,2)   
        %-- scan from bottom -> top in high level thresh : FIND RPE LAYER
        scanUpperRPE = 0;
        for i = size(layer1_skel,1):-1:1  
            
            % Lower RPE layer
            if (layer1_skel(i,j) == 1) && (scanUpperRPE == 0) 
                
                %--- fix not connected point ---------------------
%                 if j == 2
%                     previous_i = i;     %initial previous i
%                 end               
%                 if i - previous_i > 1
%                     i = previous_i + 1; %round((i - previous_i)/2);
%                     previous_i = i;
%                 elseif i - previous_i < -1
%                     i = previous_i -1; %round((previous_i - i)/2);
%                     previous_i = i;    
% 
%                 end
                %--------------------------------------------------
                img2(i,j,1) = 255;
                img2(i,j,2) = 0;
                img2(i,j,3) = 0;

                choroid(1:i-1,j) = 255;                    
                
                %half column -> find upper bound and lower bound of choroid region
                if j == round(size(layer1_skel,2)/2)    
                    choroidUpBound = i - 40;
                    choroidLowBound = i + 100;
                end
                
                scanUpperRPE = 1;
                i = i-1;
            end   
            % Upper RPE layer (after found lower RPE layer)
            if (scanUpperRPE == 1) && (layer1_skel(i,j) == 1)  
                
                %--- fix not connected point ---------------------
%                 if j == 2
%                     previous_i_upLayer = i;     %initial previous i
%                 end               
%                 if i - previous_i_upLayer > 1
%                     i = previous_i_upLayer + 1;%round((i - previous_i_upLayer)/2);
%                     previous_i_upLayer = i;
%                 elseif i - previous_i_upLayer < -1
%                     i = previous_i_upLayer -1;%round((previous_i_upLayer - i)/2);
%                     previous_i_upLayer = i;                    
%                 end
                %--------------------------------------------------
                               
                img2(i,j,1) = 255;
                img2(i,j,2) = 0;
                img2(i,j,3) = 0;
                
                RPE_layer(1:i-1,j) = 0;       %remove region upper RPE line
                
                break;
            end        
                           
        end
        
        %-- scan from top -> bottom in middle level thresh : FIND ILM LAYER
         for i = 1:size(layer2_skel,1)  
            if (layer2_skel(i,j) == 1)    
                img2(i,j,1) = 0;
                img2(i,j,2) = 255;
                img2(i,j,3) = 0;
                ILM_layer(i+1:size(layer2_skel,1),j) = 0;
                break;
            end      
         end 
                      
    end    

    
    % find choroid layer  
    choroid = choroid(choroidUpBound:choroidLowBound,:);
    BWchoroid = adaptivethreshold(choroid,100,0.02,0);      % adaptive threshoulding
    BWchoroid = imcomplement(BWchoroid);
    
    %morphological operation
    se = strel('diamond',3);
    BWchoroid = imerode(BWchoroid,se);
    BWchoroid = bwareaopen(BWchoroid,200);
    BWchoroid = imdilate(BWchoroid,se);
    
    BWchoroid = imfill(BWchoroid,'holes');
    BWchoroid = FindMaxRegion(BWchoroid);
    choroidLayer = edge(BWchoroid,'canny');
    
    for j = 1:size(BWchoroid,2)   
     % run from bottom -> top in : find low choroid layer
        for i = size(BWchoroid,1):-1:1            
            if (BWchoroid(i,j) == 1)    
                
                %--- fix not connected point ---------------------
%                 if j == 1
%                     previous_i = i;     %initial previous i
%                 end               
%                 if i - previous_i > 1
%                     i = previous_i + 1;
%                     previous_i = i;
%                 elseif i - previous_i < -1
%                     i = previous_i - 1;
%                     previous_i = i;                
%                 end
                % ------------------------------------------------
                
                img2(choroidUpBound + i,j,1) = 255;
                img2(choroidUpBound + i,j,2) = 255;
                img2(choroidUpBound + i,j,3) = 0;
                %remove region upper RPE line
                choroid(i-1:size(BWchoroid,1),j) = 255;
                break;
            end
        end
    end
     
    figure(3),imshow(img2);
%     figure(3),subplot(1,3,2),imshow(choroid);
%     figure(3),subplot(1,3,3),imshow(BWchoroid);
    
%     figure(1),subplot(2,2,3),imshow(RPE_layer);
%     figure(1),subplot(2,2,4),imshow(ILM_layer);
    
    filename1 = [pathname 'TestingResult\' idx '_multithresh.tif'];
    filename2 = [pathname 'TestingResult\' idx '_RPE-layer.tif'];
    filename3 = [pathname 'TestingResult\' idx '_ILM-layer.tif'];
    filename5 = [pathname 'TestingResult\' idx '_LayerBoundary.tif'];
    imwrite(RGBSegmentedImg,filename1);
%     imwrite(RPE_layer,filename2);
%     imwrite(ILM_layer,filename3);
    imwrite(img2,filename5);
    
    %filename3 = ['C:\Users\Lenovo\Desktop\OCT\OCT_Project\Publication_Dataset (Normal+AMD+DME)\AMD1\TIFFs\8bitTIFFs\TestingResult\' idx '_test.png'];
    %saveas(figure(1),filename3)
    
    clear img2;
    clear rgb_img;
end
end

