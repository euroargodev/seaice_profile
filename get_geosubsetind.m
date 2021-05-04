function [st,ct,geovars,typevars,S,strext]=get_geosubsetind(lonlims,latlims,indir,filename)
% Given longitude and latitude limits (LONLIMS and LATLIMS) and the path
% for a satellite image (stored in a netcdf, with grids stored in variables
% lon and lat as in OSI-SAF) this function finds the pixels inside those
% limits and returns
% - The start and count values for accessing the region of interest from the image
% using ncread (ST and CT)
% - A list of the (geo)variables in the file (GEOVARS) and their type
% (TYPEVARS)
% - The size of the variables (S)
% - A string of text to extract each of the variables (using eval for
% example - STREXT

% THE CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND
% Ingrid M. Angel-Benavides (BSH) 07.2020 (Matlab 2018b)

info=ncinfo([indir filename]);
lat=ncread([indir filename],'lat');
lon=ncread([indir filename],'lon');

count=0;
for i=1:numel(info.Variables)
    s=info.Variables(i).Size;
    if numel(s)==3
        count=count+1;
        geovars{count}=info.Variables(i).Name;
        typevars{count}=info.Variables(i).Datatype;
        strext{count}=['ncread(fip,' '''' geovars{count} '''' ...
            ',st,ct);'];
        S(count,:)=s;
    end
end

[lon_pts,lat_pts]=corners(lonlims,latlims);
in=inpolygon(lon,lat,lon_pts,lat_pts);
[in1,in2]=ind2sub(size(lon),find(in==1));
if isempty(in1)==0
in1_lim=[min(in1) max(in1)];
in2_lim=[min(in2) max(in2)];

st1=in1_lim(1);n1=diff(in1_lim)+1;
st2=in2_lim(1);n2=diff(in2_lim)+1; 

st=[st1 st2 1];
ct=[n1 n2 1];
else
    st=NaN;
    ct=NaN;
end