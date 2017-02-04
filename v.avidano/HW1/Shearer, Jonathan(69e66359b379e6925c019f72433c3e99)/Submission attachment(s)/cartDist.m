function [out] = cartDist(x1,y1,x2,y2)
% x1,y1,x2,y2 = coordinates of the two points
out = sqrt(((x2-x1).^2)+((y2-y1).^2));
out = round(out,2)
end