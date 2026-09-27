# data/prism

The PRISM rasters are not included here because they are too large for this repository (65 yearly folders, 435 files, about 220 MB).

They are the PRISM annual mean temperature rasters (tmean, stable, 4 km) for 1960-2024 from the PRISM Climate Group, Oregon State University: https://prism.oregonstate.edu

To get them, run script_files/1_download_prism.R. It uses the prism R package to download every year into this folder, one folder per year (PRISM_tmean_stable_4kmM3_YYYY_bil/).
