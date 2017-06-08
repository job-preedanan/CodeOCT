function output = FindMaxRegion(img)

output = img;
cn=bwconncomp(img);
Prop = regionprops(cn,'Area','PixelList');
MaxArea=max([Prop.Area]);
for i = 1:cn.NumObjects
    if Prop(i).Area ~= MaxArea   %not max region
        for a = 1:size(Prop(i).PixelList,1)
            x = Prop(i).PixelList(a,2);    %x
            y = Prop(i).PixelList(a,1);    %y
            output(x,y) = 0;
        end
    end    
end