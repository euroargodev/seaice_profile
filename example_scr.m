addpath '\H:\CodeProjects\imab'
addpath '\H:\CodeProjects\matlab_toolboxes\m_map'
sat_dir='\H:\ICE\ice_im\';
datev=[2011  11  1   21   58   44;2011  11  2   21   58   44];
lon=[-5.17,-5.17];
lat=[76.0195,76.0195];
for i=1:numel(lon)
    [pix_ice(i),dist_ice(i),sat_ice(i)]=metaprof_satice(datev(i,:),lon(i),lat(i),sat_dir);
end
