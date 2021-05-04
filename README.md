# distance2ice
Script to calculate calculate the distance to the ice (edge) from a given position (&amp; date)

Please make sure to use the latest version.

Q: Does it work for the Antarctic as well? Any point even at the equator?

A: Yes. The script selects if it should download the ice of the southern or northern hemisphere according to the latitude (negative or positive). Then it finds the given (profile) position in the sea ice image. For positions too close to the equator, which are not inside the ice image grid (i.e. very far away from the ice), the outputs of the script will be all equal to NaN.

Q: For the reference ice dataset, is there a limit back in time or can I use any date?

A: It depends on which ice times eries do you want to use. There are two functions with similar names: metaprof_satice and metaprof_satice_climate
They are practically the same script but they access two different ftp directories (OSI-SAF ftp://osisaf.met.no/)
metaprof_satice goes for the near real time images (10 km resolution) which span from 2005 to the present. I use this one because of availability period and resolution.
Metaprof_satice_climate uses the climate record (reprocessed) images 1979 to 2015 (25 km resolution)

Requires:
- m_map,
- imab toolbox https://github.com/imab4bsh/imab
