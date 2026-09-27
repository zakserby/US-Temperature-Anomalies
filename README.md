# US Temperature Anomalies

R code for AEM 6850 (Empirical Methods, Cornell, Fall 2025) that maps population-weighted annual temperature anomalies for every county in the continental US, 1960-2024, relative to the 1960-1980 average, and animates them as a GIF.

script_files (run in order):
- 1_download_prism.R : downloads PRISM annual mean temperature rasters for 1960-2024 into data/prism/
- 2_raster_to_polygon.R : weights each PRISM grid cell by population, builds a sparse matrix that maps grid cells to counties, aggregates temperature to counties and subtracts each county's 1960-1980 mean
- 3_plot_video.R : draws one frame per year (county map, legend and a line of the average anomaly over time) and combines the frames into a GIF with magick
- US-Temperature-Anomalies.Rproj : RStudio project, open this first so the scripts find the data folders

data:
- shapefile/ : 2010 US Census county boundaries (Cartographic Boundary File, 1:20,000,000)
- population/ : GPWv4 Population Count, Revision 11 (2010, 2.5 arc-minute), readme only (see below)
- prism/ : PRISM annual mean temperature rasters, not included (see below)

output_figure:
- temperature_anomalies.gif : animated county maps of annual temperature anomalies, 1960-2024

Other files:
- readme.rtf : full readme with sources, methods and data-specific information

Data not included (too large for GitHub):
- data/prism/ (about 219 MB) : run 1_download_prism.R, or see the PRISM Group at Oregon State University, https://prism.oregonstate.edu
- data/population/gpw-v4-population-count-rev11_2010_2pt5_min_tif/gpw_v4_population_count_rev11_2010_2pt5_min.tif (about 28 MB) : https://www.earthdata.nasa.gov/data/catalog/sedac-ciesin-sedac-gpwv4-popcount-r11-4.11

Requires R 4.x with sf, terra, RColorBrewer, Matrix, tmaptools, prism, parallel and magick.
