#===============================================================================
# AEM 6850
# County-level temperature anomalies, 1960-2024
#===============================================================================

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 1). Preliminary -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("sf","terra","RColorBrewer","Matrix","tmaptools","prism","parallel")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# Directories
  dir <- list()
  dir$root <- dirname(getwd())
  dir$pop <- paste(dir$root,"/data/population",sep="")
  dir$shape <- paste(dir$root,"/data/shapefile",sep="")
  dir$prism <- paste(dir$root,"/data/prism",sep="")
  
# Misc
  misc <- list()
  misc$years <- 1960:2024
  misc$refyears <- 1960:1980
  
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2). Download  -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

  # Set where PRISM package will download data
  prism_set_dl_dir(dir$prism)
  
  # Download some PRISM data
  get_prism_annual(
    type=c("tmean"),
    years=misc$years,
    keepZip = F,
    keep_pre81_months = F,
    service = NULL
  )
  

# the end