function [ix,iy,mdist]=closest_gcell(coord1, coord2, grid_coord1, grid_coord2)
% This function finds the closest point in a grid
% INPUT: coord1 (lon), coord2(lat), grid_coord1 (grid lon) , grid_coord2
% (grid lat)
% OUTPUT: IX,IY indices of the closest pixel and MDIST distance from the
% input coordinates to that grid cell

% Ingrid M. Angel-Benavides (BSH) 07.2020 (Matlab 2018b)

c1_range=[floor(coord1)-1 ceil(coord1)+1];
c2_range=[floor(coord2)-1 ceil(coord2)+1];
f1=find(grid_coord1>=c1_range(1)&grid_coord1<c1_range(2));
f2=find(grid_coord2>=c2_range(1)&grid_coord2<c2_range(2));
f=intersect(f1,f2);

for k=1:numel(f)
    d(k)=m_lldist([coord1 grid_coord1(f(k))],[coord2 grid_coord2(f(k))]);
end
% find pixel closest to profile position
mdist=min(d(:));
closest=f(find(d==mdist));
[ix,iy]=ind2sub(size(grid_coord1),closest);