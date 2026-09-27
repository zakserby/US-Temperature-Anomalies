#===============================================================================
# AEM 6850
# County-level temperature anomalies, 1960-2024
#===============================================================================

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 1). Preliminary -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Load libraries
library(magick)

# Directories
dir <- list()
dir$root <- dirname(getwd())
dir$pop <- paste(dir$root,"/data/population",sep="")
dir$shape <- paste(dir$root,"/data/shapefile",sep="")
dir$prism <- paste(dir$root,"/data/prism",sep="")

### NOTE: YOU MUST RUN "DOWNLOAD PRISM ADN RASTER TO POLYGON DO-FILES" FIRST ###

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2). Create relevant functions -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Putting them together for an arbitrary year
year <- 2024
frame_index <- which(yrs == year)  # get the index for the year

# Define where the folder is before calling png
dir$output <- file.path(dir$root, "output_figure")
# Save as PNG in output_figure folder
png(file.path(dir$output, paste0(year, ".png")), width = 1000, height = 1300)

layout(matrix(c(1,2,3), ncol = 1), heights = c(5, 1, 3)) 

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2a). Function top panel -----
f1 <- function(co_proj, year) {
  # To curve the US, need to transform counties to polyconic projection
  co_proj <- st_transform(co2, crs = "+proj=poly +lon_0=-96 +lat_0=38")
  # Plot map
  par(mar=c(4,4,4,4), bg="black") # Set background to black
  breaks <- c(-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5)
  colors <- rev(brewer.pal(length(breaks)-1, "RdBu"))  # 9 main colors
  # BC using polygons instead of raster, we must match each county to a color
  vals <- as.numeric(co_proj[[paste0("PRISM_tmean_stable_4kmM3_", year, "_bil")]])
  colorsmatched <- cut(vals, breaks = breaks, labels = FALSE, include.lowest = TRUE)
  plot(st_geometry(co_proj), col = colors[colorsmatched])
  # Plot state borders
  states <- aggregate(co_proj["STATE"], by = list(co_proj$STATE), FUN = mean) 
  plot(st_geometry(states), add = TRUE, border = "black", lwd = 3)  
  
  # Add y-axis title
  mtext(bquote(bold(.(year))), # expression () allows one to write formatted text, allowing part of the text to be bold
        side = 3, line = -5, cex = 4.75, col = "white")
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2b). Function for legend -------
f2 <- function() {
  par(mar = c(3, 4, 3, 4))
  plot(1, type = "n", xlim = c(0, 1), ylim = c(0, 10), axes = FALSE, xlab = "", ylab = "")
  # define breaks and colors exactly as in top_panel
  breaks <- c(-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5)
  colors <- rev(brewer.pal(length(breaks)-1, "RdBu"))  # 9 main colors
  box_width <- 0.08  # Define box width to compress width of legend
  total_width <- box_width * (length(breaks) - 1)
  x_start <- (1 - total_width) / 2 # This helps to center the box in the plot
  # Compute left and right x positions of each box
  xlefts  <- x_start + seq(0, by = box_width, length.out = length(breaks) - 1)
  xrights <- xlefts + box_width
  # Draw rectangles
  for (i in 1:(length(breaks) - 1)) {
    rect(xleft = xlefts[i], xright = xrights[i],
         ybottom = 5, ytop = 9,
         col = colors[i], border = NA)
  }
  # Draw tick marks at breaks excluding the outer ticks
  internal_breaks <- breaks[2:(length(breaks) - 1)]
  tick_pos <- xlefts[-1]
  for (x in tick_pos) {
    lines(x = c(x, x), y = c(5, 9), lwd = 0.6)
  }
  text(x = tick_pos, y = 1.5, labels = internal_breaks, cex = 3, col = "white")
  mtext("Temperature anomaly (°C)", side = 3, line = 1, cex = 2.25, col = "white")
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 2c). Function for bottom panel -----
f3 <- function(frame_index, yrs, anomalies) {
  # Compute average anomalies per year across all counties
  avg_anomalies <- colMeans(anomalies, na.rm = TRUE)
  # Frame_index specifies to plot one frame/year
  plot_years <- yrs[1:frame_index]
  plot_anomalies <- avg_anomalies[1:frame_index]
  # Plot line
  par(mar=c(10,15,5,4), mgp=c(3,3,0))
  plot(plot_years, plot_anomalies, type = "l", col = "red", lwd = 3, xlim = c(1960,2024), ylim = c(-1, 2), xaxt = "n", yaxt = "n")
  points(plot_years[frame_index], plot_anomalies[frame_index], pch = 19, col = "red", cex = 3)
  segments(x0 = min(yrs), x1 = max(yrs), y0 = 0, y1 = 0, col = "white", lty = 2) # acts as abline, x0,x1,t0,y1 acts as coordinates of points from which to draw
  axis(1, at = seq(1960, 2020, 10), col = "white", col.axis = "white", col.ticks = "white", cex.axis = 3.5, lwd = 3.5, lwd.ticks = 3.5)
  axis(2, at = seq(-1, 2, by = 0.5), col = "white", col.axis = "white", col.ticks = "white", cex.axis = 3.5, lwd = 3.5, lwd.ticks = 3.5, las = 1)
  mtext("Temperature anomaly (°C)", side = 2, line = 9, cex = 2.25, col = "white")
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

f1(co_proj, year)
f2()
f3(frame_index, yrs, anomalies)

dev.off()

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 3). Generate individual figures for each year -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Generate individual figures for each year
lapply(misc$years, function(year) {
  
  frame_index <- which(yrs == year)
  png(file.path(dir$output, paste0(year, ".png")), width = 1000, height = 1300)
  
  layout(matrix(c(1,2,3), ncol = 1), heights = c(5, 1, 3)) 
  
  f1(co_proj, year)            
  f2()                          
  f3(frame_index, yrs, anomalies)  
  
  dev.off()
})

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# 4). Generate GIF file -----
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Generate GIF from list of PNGs in the disk
# Path to all PNG files
png_files <- list.files(dir$output, pattern = "\\.png$", full.names = TRUE)
png_files <- png_files[order(png_files)]  

# Read PNGs and create GIF
img_list <- image_read(png_files)
img_gif <- image_animate(img_list, fps = 2) 
image_write(img_gif, file.path(dir$output, "temperature_anomalies.gif"))

# Delete unnecessary PNG files
file.remove(png_files)

# The end 

