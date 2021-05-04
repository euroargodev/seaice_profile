addpath '\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\CodeProjects\imab'
addpath '\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\CodeProjects\matlab_toolboxes\m_map'
sat_dir='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\';
datev=[2011  11  9   21   58   44];
lon=-5.1730;
lat= 76.0195;
[pix_ice,dist_ice,sat_ice]=metaprof_satice(datev,lon,lat,sat_dir);
