clear variables;
load('ArgoFloats_8187_253e_f5c7_Arctic.mat')

t = datenum('01-Jan-1970 00:00:00');
for i=1:numel(ArgoFloats.time_location)
    ArgoFloats.t(i,1)= addtodate(t, ArgoFloats.time_location(i,1), 'second');
    ArgoFloats.date(i,:)=datevec(ArgoFloats.t(i,1));
    DATE(i,:)=ArgoFloats.date(i,:);
    LONG(i,1)=ArgoFloats.longitude(i);
    LAT(i,1)=ArgoFloats.latitude(i);
    POS_QC(i,1)=str2double(ArgoFloats.position_qc(i));
end

% get only profiles with interpolated positions
f1=find(POS_QC==8);
f2=setdiff(1:numel(POS_QC),f1);
f=union(f2,find(DATE(:,1)<1998));
LONG(f)=[];
LAT(f)=[];
DATE(f,:)=[];

clear ArgoFloats f* i POS_QC t

%% Days
uDATE=unique(DATE(:,1:3),'rows');
DOY=datevec2doy([uDATE zeros(size(uDATE))]);
YY=uDATE(:,1);
MM=uDATE(:,2);
DD=uDATE(:,3);

%%
im_path='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\';
n=size(uDATE,1);

% ftp info & login
indir='archive/ice/conc/';
site='osisaf.met.no';
f = ftp(site);
cd(f); sf=struct(f); sf.jobject.enterLocalPassiveMode();
cd(f,indir);


% check if concentration image is locally available
concstr='ice_conc_nh_polstere-100_multi_';
disp('Checking if the image is locally available')
for i=1:n
    disp(num2str(i))
    YYs=num2str(YY(i));MMs=num2str(MM(i),'%02.f');DDs=num2str(DD(i),'%02.f');
    full_path=[im_path  YYs '\' MMs '\' concstr YYs MMs DDs '*'];
    % check if the image is there
    d=dir(full_path);
    % if is not get the image
    if isempty(d)
        disp('downloading missing image')
        tic
        cd(f,YYs);
        cd(f,MMs);
        mget(f,[concstr YYs MMs DDs '*'],[im_path  YYs '\' MMs '\']);
        cd(f,'..');
        cd(f,'..');
        toc
        disp('.')
    end
end

%% Extract data
indir='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\2015\12\';
filename='ice_conc_nh_polstere-100_multi_201512011200.nc';
% get indices
lonlims=[-180 180];
latlims=[60 90];
[st,ct,geovars,typevars,S,strext]=get_geosubsetind(lonlims,latlims,indir,filename);
lat=double(ncread([indir filename],'lat',st(1:2),ct(1:2)));
lon=double(ncread([indir filename],'lon',st(1:2),ct(1:2)));
m_proj('lambert','long',lonlims,'lat',latlims);

% getting land mask 
[bath,lobath,labath]=m_elev([lonlims latlims]);
[lon_pts,lat_pts]=corners(lonlims,latlims);
in=inpolygon(lon,lat,lon_pts,lat_pts);
F=scatteredInterpolant(lobath(:),labath(:),bath(:));
BATH=F(lon,lat);
BATH(in==0)=NaN;

lon(isnan(BATH))=NaN;lon(BATH>=0)=NaN;
lat(isnan(BATH))=NaN;lat(BATH>=0)=NaN;

YY=DATE(:,1);
MM=DATE(:,2);
DD=DATE(:,3);

N=numel(LONG);
for i=1:50
    disp(num2str(i))
    YYs=num2str(YY(i));MMs=num2str(MM(i),'%02.f');DDs=num2str(DD(i),'%02.f');
    part_path=[im_path  YYs '\' MMs '\' concstr YYs MMs DDs '*'];
    % get full path image
    D=dir(part_path);
    fip=[D.folder '\' D.name];
   
    
    % calculating distances from profile to each pixel in the sea
    % ice images
    d=nan(size(lon));
    indx=find(isnan(lon)==0);
    for kk=1:numel(indx)
        k=indx(kk);
        d(k)=m_lldist([lon(k) LONG(i)],[lat(k) LAT(i)]);
    end
    % find pixel closest to profile position
    [ix,iy]=find(d==min(d(:)));
    
    for j=1:numel(geovars)
        eval(['tmp=' strext{j} ])
        ice(:,:,j,i)=tmp(ix-1:ix+1,iy-1:iy+1);
    end    
    
    openwater(i)=ice(2,2,1,i)==0||ice(2,2,1,i)==9999;
    % if profile is not under ice, calculate distance
    if openwater(i)==1
        % load ice
        eval(['tmp=' strext{1} ])
        D=d;
        D(tmp==0)=max(d(:));%excludes all pixels without ice by assigning the maximum distance
        D(isnan(tmp))=max(d(:));%excludes all pixels without ice by assigning the maximum distance
        [~,fmin]=min(D(:));% finds the closest pixel with ice
        [fminx,fminy]=ind2sub(size(lon),fmin);
        % gets the concentration and the position
        lon0(i)=lon(fminx,fminy);lat0(i)=lat(fminx,fminy);
        conc0(i)=tmp(fminx,fminy);
        dist0(i)=m_lldist([LONG(i) lon0(i)],[LAT(i) lat0(i)]);
        
        % distance accross land flag
        [px,py]=bresenham(fminx,fminy,ix,iy);
        for ii=1:numel(px)
            bath(ii)=BATH(px(ii),py(ii));
            lonpt(ii)=lon(px(ii),py(ii));
            latpt(ii)=lat(px(ii),py(ii));
        end
        land(i)=isempty(find(bath<=0, 1));
        
%         figure
%         m_pcolor(lon,lat,double(tmp));shading flat
%         hold on
%         m_plot(LONG(i),LAT(i),'r*')
%         m_plot(lon0(i),lat0(i),'ro')
%         m_plot([LONG(i) lonpt lon0(i)],[LAT(i) latpt lat0(i)],'m')
        clear lonpt latpt bath
        
        D(tmp<40)=max(d(:));%excludes all pixels with less than 40% ice
        [~,fmin]=min(D(:));% finds the closest pixel with ice
        [fminx,fminy]=ind2sub(size(lon),fmin);
        % gets the concentration and the position
        lon1(i)=lon(fminx,fminy);lat1(i)=lat(fminx,fminy);
        conc1(i)=tmp(fminx,fminy);
        dist1(i)=m_lldist([LONG(i) lon1(i)],[LAT(i) lat1(i)]);
        
        % distance accross land flag
        [px,py]=bresenham(fminx,fminy,ix,iy);
        for ii=1:numel(px)
            bath(ii)=BATH(px(ii),py(ii));
            lonpt(ii)=lon(px(ii),py(ii));
            latpt(ii)=lat(px(ii),py(ii));
        end
        land1(i)=isempty(find(bath<=0, 1));
    end
end

