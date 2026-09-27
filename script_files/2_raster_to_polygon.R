#===============================================================================
# AEM 6850
# County-level temperature anomalies, 1960-2024
#===============================================================================

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 1). Preliminary -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Directories
dir <- list()
dir$root <- dirname(getwd())
dir$pop <- paste(dir$root,"/data/population",sep="")
dir$shape <- paste(dir$root,"/data/shapefile",sep="")
dir$prism <- paste(dir$root,"/data/prism",sep="")

### NOTE: YOU MUST RUN "DOWNLOAD PRISM DO FILE" FIRST ###

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2). Get the necessary data -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# PRISM data
  flist <- list.files(dir$prism, full.names=T, recursive = T)
  flist <- flist[grepl("bil.bil",flist) & !grepl("bil.bil.",flist)]
  length(flist)
  s <- rast(flist)
  
  # cell id raster for PRISM grid
  id <- mean(s)
  id[] <- ifelse(is.na(id[]), NA, 1:ncell(id))
  plot(id)
  
# Population raster
  fname <- list.files(dir$pop, recursive=T, full.names=T)
  fname <- fname[grepl("[.]tif",fname)] # only select the file name with ".tif" in the name
  pop <- rast(fname)
  
  dens <- pop/5 # density per squared kilometer
  breaks <- c(0,5,25,200,500,1000,1500,250000)
  colors <- colorRampPalette(brewer.pal(9,"Oranges"))(length(breaks)-1)
  plot(dens, breaks=breaks, col=colors, colNA="lightskyblue1", axes=FALSE, box=FALSE, legend=T)
  
  dens2 <- resample(dens, id, method="bilinear") # 0.4s
  dens2[] <- ifelse(is.na(id[]),NA,dens2[])
  plot(dens2, breaks=breaks, col=colors, colNA="lightskyblue1", axes=FALSE, box=FALSE, legend=T)
  
# Polygons for US counties
  fname <- paste(dir$shape,"/gz_2010_us_050_00_20m.shp",sep="")
  co <- st_read(fname)
  co <- co[!(co$STATE %in% c("15","02","72")),] # remove Hawaii, Alaska, Puerto Rico
  co <- st_transform(co, crs(s)) # same projection as weather data
  
  
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 3). Generate projection matrix -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Extract match between counties and raster gridcells
  system.time({
    info <- extract(id, vect(co), weights=TRUE, cells=TRUE, exact=TRUE) # 18 secs
  })

  co$ID <- 1:nrow(co)
  co.info <- st_drop_geometry(co[,c("ID","GEO_ID","STATE","COUNTY","NAME")])
  co.info$fips <- as.numeric(co.info$STATE)*10^3 + as.numeric(co.info$COUNTY)
  info <- merge(info, co.info)
  
  # Takes about 65 seconds with mclapply and 8 cores
  system.time({
    info2 <- mclapply(as.character(unique(info$fips)), mc.cores=8, FUN=function(coname) {
      print(coname) 
      df <- info[info$fips==coname,]
      x <- dens2[df[,"cell"]] # get population for those cells
      x <- x/sum(x,na.rm=T) # make them add to 1
      df$popweight <- unlist(x)
      df <- df[!is.na(df$popweight),, drop=F] # drop=F, to make sure object stays as a matrix, even with 1 row
      df <- df[,c("ID","cell","popweight")]
    })
  })
  
  temp <- do.call("rbind", info2)
  
  # Generate sparse matrix "P"
  P <- sparseMatrix(i=temp$ID, # row
                    j=temp$cell, # column
                    x=temp$popweight, # weights that sum to 1
                    dims = c(length(info2),ncell(s))) # dimensions of matrix

  
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 4). Data aggregation -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Aggregate data
  
  # To compute aggregation we need both the M and P matrices, we made the sparse matrix P above so let's make M
  M <- s[] # takes a bit for all years
  
  # Compute aggregation with matrix multiplication
  system.time({
    Mco <- P %*% M # 0.3s (compare to 166s above with canned code)
  })
  
  # 5.4 View data in a map ------
  
  # Arrange data
  co2 <- co # just making a copy so I can keep original "co" untouched
  
  # Extract years from PRISM layer names to get a vector of yrs and make sures layers match the # of yrs
  yrs <- as.numeric(gsub(".*([0-9]{4}).*", "\\1", names(s)))
  
  # Assign row names to Mco using FIPS codes in order to merge data sets later
  co2$fips <- as.numeric(co2$STATE) * 1000 + as.numeric(co2$COUNTY)
  rownames(Mco) <- co2$fips
  
  # Compute baseline relative to 1960–1980
  baseline <- which(yrs >= 1960 & yrs <= 1980)
  baseline_mean <- rowMeans(Mco[, baseline], na.rm = TRUE) # calculate means across columns 1960-1980 for each county/row
  # Temperature anomalies compared to the baseline 1960-1980
  anomalies <- sweep(Mco, 1, baseline_mean, FUN = "-") # sweep is a function that applies along each row the value minus the baseline value
  
  # Merge into one data frame
  df <- data.frame(fips = as.numeric(rownames(anomalies)), as.matrix(anomalies))
  co2 <- merge(co2, df, by = "fips")
  
  # The end
  
  
  
  
  