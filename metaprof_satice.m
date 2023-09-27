function [pix_ice,dist_ice,sat_ice]=metaprof_satice(datev,lon,lat,sat_dir)
% This function takes the metadata of a hydrographic profile (date,lon,lat)
% and extracts the sea ice information for that day and position from the
% OSI-SAF satellite product. If the image is not locally available, the
% code downloads the image from the OSI-SAF ftp server.
% METAPROF_SATICE also calculates the distance to three categories of sea ice (according to the concentration): open water
% (concentration between 1-40%), open ice (40-70%) and close ice (>70%).

% INPUTS
% DATEV: Date of the profile in vector format (minimum [YYYY MM DD])
% LON, LAT: Profile position
% SAT_DIR: directory where the sea ice image are/will be locally stored*

% OUTPUTS
% The outputs are organized in 3 structures
% PIX_ICE: Satellite data extracted for the closest pixel
% DIST_ICE: Distance to the closest sea ice per category
% SAT_ICE: Satellite data extracted for the rectangular area containing the
% search radius.
% more details below the example

% EXAMPLE
% sat_dir='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\';
% datev=[2011  11  9   21   58   44];
% lon=-5.1730;
% lat= 76.0195;
% [pix_ice,dist_ice,sat_ice]=metaprof_satice(datev,lon,lat,sat_dir);

% * If images are already stored locally the images in sat_dir need to be
% stored in subfolders as in the OSI SAF ftp website. For example, the image
% ice_conc_nh_polstere-100_multi_201207011200.nc needs to be stored in the
% folder 'sat_dir'/2012/07/ for the script to find it.

% THINGS YOU CAN CHANGE
% - Ice categories for the distance to ice calculations
% This thresholds and number of categories can be changed in the
% ICE_CAT_LOW variable (lower boundary for each category).
% - Search radius to find nearby ice
% SEARCH_RADIUS variable (default is 10^5 m or 100 km)

% OUTPUD DETAILS
% Pixel data - PIX_ICE
% LON and LAT give the position of the pixel's center
% DATA contains the data for each one of the satellite variables
% VARS contains the name of each variable
% DIST is the distance from the profile position to the pixel's center
% IX,IY and AIX,AIY are the indices of the pixel position in the
% coordinates of the extracted data (stored in SAT_ICE) and in the original
% image coordinates, respectively

% Distance to ice - DIST_ICE
% each field contains a value for each ice category

% ICE_CAT_LB contains the lower boundary of each ice category (upper
% boundary is the following element or 100 for the last one since are
% monotonically increasing)
% ISIN is 1 if the pixel is in that category and 0 otherwise
% DIST is the distance from the profile position to the closest ice pixel
% in that category. Is 0 if ISIN is 1 and NAN if the category is not found
% in the search region
% XLAND is a flag that is 1 if the path between the profile an the pixel crosses land
% CICE is the ice concentration of the pixel
% LON and LAT are the positions of the pixels
% IX,IY and AIX,AIY are the indices of the pixel position lile in PIX_ICE

% Satellite data - SAT_ICE
% LON and LAT are the longitude and latitude grids
% DATA contains the data for each one of the satellite variables
% VARS contains the name of each variable
% IMAGE is the image name
% ST and CT are the Start and the count variables to extract the satellite
% data from the netcdf file
% RADIUS is the search radius in meters

% Ingrid M. Angel-Benavides (BSH)07.2020 (Matlab 2018b)
% THE CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND
%% getting ice categories info
ice_cat_low=[1 40 70];
n_ice_cat=numel(ice_cat_low);
ithres=[ice_cat_low 100];
search_radius=10^5;

%% Images default info
% image text string
if lat>0
    concstr='ice_conc_nh_polstere-100_multi_';
else
    concstr='ice_conc_sh_polstere-100_multi_';
end
% OSI-SAF ftp site
indir_sat='archive/ice/conc/';
site='osisaf.met.no';

%% Access satellite image
% download sea ice concentration image if is not locally available
disp('Checking if the image is locally available')
% get image local full path
YYs=num2str(datev(1));MMs=num2str(datev(2),'%02.f');DDs=num2str(datev(3),'%02.f');
indir=[sat_dir  YYs '\' MMs '\'];filename=[concstr YYs MMs DDs '*.nc'];
% check if the image is there
d=dir([indir filename]);
if isempty(d)% if is there get the image from ftp server
    disp('downloading missing image')
    % connecting to ftp site
    tic
    f = ftp(site);
    %cd(f); sf=struct(f); sf.jobject.enterLocalPassiveMode();
    cd(f,indir_sat);
    % going to directory
   
    if isempty(dir(f,YYs))
        disp('Date not in catalog')
    else
        cd(f,YYs);
        if isempty(dir(f,MMs))
            display('Date not in catalog')
        else
            cd(f,MMs);
        end
        % getting the image
        disp('downloading w. mget')   
        mget(f,[concstr YYs MMs DDs '*.nc'],[sat_dir  YYs '\' MMs '\']);
        close(f)
        toc
        disp('.')
    end
   
else
    disp('Image is locally available')
end

%% Find region of interest
% get points in a circle
[lon2,lat2,a21] = m_fdist(lon,lat,0:10:360,search_radius);
% convert longitude
lon2=convertlon(lon2,180);
% find limits to extract image pixels in the region
lonlims=[min(lon2) max(lon2)];
latlims=[min(lat2) max(lat2)];

%% Extract image data
tmp=dir([indir filename]);
% get exact image name
if isempty(tmp)==0
    filename=tmp.name;
    % get indices for extraction
    [st,ct,geovars,typevars,S,strext]=get_geosubsetind(lonlims,latlims,indir,filename);
    
    if isnan(st)==0
        % get grid
        glat=double(ncread([indir filename],'lat',st(1:2),ct(1:2)));
        glon=double(ncread([indir filename],'lon',st(1:2),ct(1:2)));
        % get geovariables in area
        fip=[indir,filename];
        for j=1:numel(geovars)
            try eval(['tmp=' strext{j} ])
                sat(:,:,j)=double(tmp);
            end
        end
        
        % get closest pixel data (in image coordinates)
        % for the selected subset
        [ix,iy,mdist]=closest_gcell(lon, lat, glon, glat);
        if numel(ix)>1
           ix=ix(1);iy=iy(1);mdist=mdist(1);
        end
        % for the entire image
        aix=st(1)+ix-1;aiy=st(2)+iy-1;
        
        % extract data for the closest pixel center
        lon_pix=glon(ix,iy,:);lat_pix=glat(ix,iy,:);
        sat_pix=sat(ix,iy,:);
        
        %% Getting land mask
        m_proj('lambert','long',lonlims,'lat',latlims);
        [bath,lobath,labath]=m_elev([lonlims latlims]);
        [lon_pts,lat_pts]=corners(lonlims,latlims);
        in=inpolygon(lon,lat,lon_pts,lat_pts);
        F=scatteredInterpolant(lobath(:),labath(:),bath(:));
        BATH=F(glon,glat);
        BATH(in==0)=NaN;
        
        %Apply land mask in lon lat grid
        glon(isnan(BATH))=NaN;glon(BATH>=0)=NaN;
        glat(isnan(BATH))=NaN;glat(BATH>=0)=NaN;
        
        %% Distance to ice
        % calculate distance to each pixel in the extracted image subset
        d=nan(size(glon));
        indx=find(isnan(glon)==0);
        for kk=1:numel(indx)
            k=indx(kk);
            d(k)=m_lldist([lon glon(k)],[lat glat(k)]);
        end
        
        % for each ice category
        for i=1:3
            % check if the pixel is in that category
            isin(i)=sat_pix(:,1)>=ithres(:,i) & sat_pix(:,1)<=ithres(:,i+1);
            if isin(1,i)==1 % if it is, then distance is 0 and the ix, iy_ice are NaN
                % because they are equal to ix
                dice(i)=0;
                cice(i)=NaN;
                ix_ice(i)=NaN;iy_ice(i)=NaN;
                lon_ice(i)=NaN;lat_ice(i)=NaN;
                xland(i)=NaN;
            else
                % if the pixel is not in that category, make a mask of the pixels
                % in the category
                mtype=sat(:,:,1)>=ithres(:,i) & sat(:,:,1)<=ithres(:,i+1);
                % mask out pixels outside the category
                d2=d;d2(mtype==0)=NaN;
                
                if sum(isnan(d2(:)))<numel(d2) % if there are pixels in the category
                    dice(i)=min(d2(:)); % find the closest (shortest distance)
                    [ix_ice(i),iy_ice(i)]=find(d2==dice(i)); % and store the image coodinates
                    cice(i)=sat(ix_ice(i),iy_ice(i),1);
                    lon_ice(i)=glon(ix_ice(i),iy_ice(i));
                    lat_ice(i)=glat(ix_ice(i),iy_ice(i));
                    % check if path crosses land
                    [d2,lons,lats]=m_lldist([lon lon_ice(i)],[lat lon_ice(i)],10);
                    if numel(find(F(lons,lats)>=0))==0
                        xland(i)=0;
                    else
                        xland(i)=1;
                    end
                else % if there are no pixels in that category, the distance to ice is NaN and the positions are also NaN
                    dice(i)=NaN;
                    cice(i)=NaN;
                    ix_ice(i)=NaN;iy_ice(i)=NaN;
                    lon_ice(i)=NaN;lat_ice(i)=NaN;
                    xland(i)=NaN;
                end
            end
        end
        % indices in original image coordinates
        aix_ice=st(1)+ix_ice-1;aiy_ice=st(2)+iy_ice-1;
        
        %% Organize output
        
        % Pixel data
        pix_ice.sic=sat_pix(:,:,1);
        pix_ice.lon=lon_pix;
        pix_ice.lon=lat_pix;
        pix_ice.data=squeeze(sat_pix);
        pix_ice.dist=mdist;
        pix_ice.ix=ix;pix_ice.iy=iy;
        pix_ice.aix=aix;pix_ice.aiy=aiy;
        pix_ice.vars=geovars;
        
        % Distance to ice
        dist_ice.ice_cat_lb=ice_cat_low;
        dist_ice.isin=double(isin);
        dist_ice.dist=dice;
        dist_ice.xland=xland;
        dist_ice.conc=cice;
        dist_ice.lon=lon_ice;
        dist_ice.lat=lat_ice;
        dist_ice.ix=ix_ice;dist_ice.iy=iy_ice;
        dist_ice.aix=aix_ice;dist_ice.aiy=aiy_ice;
        
        % Satellite data
        sat_ice.lon=glon;sat_ice.lat=glat;
        sat_ice.vars=geovars;
        sat_ice.data=sat;
        sat_ice.st=st;sat_ice.ct=ct;
        sat_ice.radius=search_radius;
        sat_ice.image=filename;
    else
        disp('Position is not coverd by the satellite images')
        pix_ice.sic=[];
        pix_ice.lon=[];
        pix_ice.lon=[];
        pix_ice.data=[];
        pix_ice.dist=[];
        pix_ice.ix=[];pix_ice.iy=[];
        pix_ice.aix=[];pix_ice.aiy=[];
        pix_ice.vars=[];
        
        % Distance to ice
        dist_ice.ice_cat_lb=[];
        dist_ice.isin=[];
        dist_ice.dist=[];
        dist_ice.xland=[];
        dist_ice.conc=[];
        dist_ice.lon=[];
        dist_ice.lat=[];
        dist_ice.ix=[];dist_ice.iy=[];
        dist_ice.aix=[];dist_ice.aiy=[];
        
        % Satellite data
        sat_ice.lon=[];sat_ice.lat=[];
        sat_ice.vars=[];
        sat_ice.data=[];
        sat_ice.st=[];sat_ice.ct=[];
        sat_ice.radius=[];
        sat_ice.image=filename;
    end
else
    disp('image is missing in the ftp server')
    pix_ice.sic=[];
    pix_ice.lon=[];
    pix_ice.lon=[];
    pix_ice.data=[];
    pix_ice.dist=[];
    pix_ice.ix=[];pix_ice.iy=[];
    pix_ice.aix=[];pix_ice.aiy=[];
    pix_ice.vars=[];
    
    % Distance to ice
    dist_ice.ice_cat_lb=[];
    dist_ice.isin=[];
    dist_ice.dist=[];
    dist_ice.xland=[];
    dist_ice.conc=[];
    dist_ice.lon=[];
    dist_ice.lat=[];
    dist_ice.ix=[];dist_ice.iy=[];
    dist_ice.aix=[];dist_ice.aiy=[];
    
    % Satellite data
    sat_ice.lon=[];sat_ice.lat=[];
    sat_ice.vars=[];
    sat_ice.data=[];
    sat_ice.st=[];sat_ice.ct=[];
    sat_ice.radius=[];
    sat_ice.image=[];
end