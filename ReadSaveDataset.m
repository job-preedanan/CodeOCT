clc;
clear;
close;

for n = 1:4
    Filename = ['Farsiu_Ophthalmology_2013_AMD_Subject_100' num2str(n)];
    load([Filename '.mat']);
    pathName = 'C:\Users\Lenovo\Desktop\OCT\OCT_Project\Farsiu_Ophthalmology_2013' ;  %path name
    foldername = Filename;
    mkdir(pathName,foldername);
    for i = 1:size(images,3)
        img = images(:,:,i);
        img = uint8(img);
        imshow(img);
        ImgName = [pathName '\' foldername '\' Filename '_' num2str(i) '.png'];
        imwrite(img,ImgName);
    end
    clear;
end