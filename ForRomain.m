% In the excel file Romain send me, I created another sheet for extracting
% the date in the format I needed it. I saved it as Text separated by Tabs.
% then I had to replace commas by dots using a text editor.
% Finally, I imported the data using the matlab import wizard (saved script
% as ImportExcelData)
clear variables;
load listromain2
datev=[YEAR MONTH DAY];
lon=LONGITUDE;
lat=LATITUDE;
sat_dir='\\win.bsh.de\root$\Standard\Hamburg\Homes\Homes00\bm2286\ICE\ice_im\';

warning('off','MATLAB:structOnObject')
f=find(abs(lat)>60);
for i=1:numel(f)
    disp([num2str(i) '/' num2str(numel(f))])
    %[pix_ice(f(i)),dist_ice(f(i)),sat_ice(f(i))]=metaprof_satice(datev(f(i),:),lon(f(i)),lat(f(i)),sat_dir);
    [pix_ice(f(i)),dist_ice(f(i)),sat_ice(f(i))]=metaprof_satice_src(datev(f(i),:),lon(f(i)),lat(f(i)),sat_dir,'RT');
end
save extr_romain3.mat

%%

for i=1:numel(sat_ice)
    if isempty(getfield(pix_ice,{i},'sic'))==0
        sic(i)=getfield(pix_ice,{i},'sic');
    else
        sic(i)=NaN;
    end
end