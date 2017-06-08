function Intensity3dPlot(img,Bimg)
global pathname;
global idx;

    %original img
    X=1:size(img,1);
    Y=1:size(img,2);
    [xx,yy]=meshgrid(Y,X);
    img=im2double(img);
    figure(2),mesh(xx,yy,img);
    filename = [pathname 'TestingResult\' idx '_3dplot.fig'];
    colorbar
    saveas(figure(2),filename);
    
    %Bilateral filter
    X=1:size(Bimg,1);
    Y=1:size(Bimg,2);
    [xx,yy]=meshgrid(Y,X);
    Bimg=im2double(Bimg);
    figure(3),mesh(xx,yy,Bimg);
    filename = [pathname 'TestingResult\' idx '_3dplotBF.fig'];
    colorbar
    saveas(figure(3),filename);