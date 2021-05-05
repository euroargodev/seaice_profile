# Sea Ice Meta Profile
Access Sea Ice concentration images for a given time and position (Metadata) and returns local sea ice information and distance to the closest sea ice.
TLDR: Calculate the distance to the sea ice (edge) from a given position (&amp; date)

Please make sure to use the latest version.

Q: Does it work for the Antarctic as well? Any point even at the equator?

A: Yes. The script selects if it should download the ice of the southern or northern hemisphere according to the latitude (negative or positive). Then it finds the given (profile) position in the sea ice image. For positions too close to the equator, which are not inside the ice image grid (i.e. very far away from the ice), the outputs of the script will be all equal to NaN.

Q: For the reference ice dataset, is there a limit back in time or can I use any date?

A: It depends on which ice times series do you want to use. There are two functions with similar names: metaprof_satice and metaprof_satice_climate
They are practically the same script but they access two different ftp directories (OSI-SAF ftp://osisaf.met.no/)
metaprof_satice goes for the near real time images (10 km resolution) which span from 2005 to the present. I use this one because of availability period and resolution.
metaprof_satice_climate uses the climate record (reprocessed) images 1979 to 2015 (25 km resolution)
A2: (Update) metaprof_satice_src includes a switch to use each database, using the input variable src. The allowed values are 'NT' and 'CLIM'.

Requires:
- m_map,
- imab toolbox https://github.com/imab4bsh/imab
