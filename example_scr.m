addpath '\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\CodeProjects\imab'
addpath '\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\CodeProjects\matlab_toolboxes\m_map'
sat_dir='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\';
datev=[2011  11  1   21   58   44];
lon=2.470;
lat= 37.40;
[pix_ice,dist_ice,sat_ice]=metaprof_satice(datev,lon,lat,sat_dir);
