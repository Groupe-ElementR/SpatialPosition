## ----regionalmap, fig.width=7, fig.height=6-----------------------------------
library(cartography)
library(sp)
library(sf)
library(SpatialPosition)
data(nuts2006)

# Compute the GDP per capita variable
nuts3.df$gdpcap <- nuts3.df$gdppps2008 * 1000000 / nuts3.df$pop2008

# Discretize the variable
bv <- quantile(nuts3.df$gdpcap, seq(from = 0, to = 1, length.out = 9))

# Draw the map
opar <- par(mar = c(0,0,1.2,0))

# Set a color palette
pal <- carto.pal(pal1 = "wine.pal", n1 = 8)

# Draw the basemap
plot(nuts0.spdf, add = F, border = NA, bg = "#cdd2d4")
plot(world.spdf, col = "#f5f5f3ff", border = "#a9b3b4ff", add = TRUE)

# Map the regional GDP per capita
choroLayer(spdf = nuts3.spdf, df = nuts3.df, 
           var = "gdpcap", 
           legend.pos = "topright",
           breaks = bv, col = pal, 
           border = NA, 
           legend.title.txt = "GDP per capita",
           legend.values.rnd = -2, 
           add = TRUE)
plot(nuts0.spdf, add = TRUE, lwd = 0.5, border = "grey30")
plot(world.spdf, col = NA, border = "#7DA9B8", add = TRUE)

# Set a layout
layoutLayer(title = "Wealth Inequality in Europe", 
            sources = "Basemap: UMS RIATE, 2015 - Data: Eurostat, 2008", 
            author = "T. Giraud, 2015")
par(opar)

## ----regionalmappot, fig.width=7, fig.height=6--------------------------------
# Create a distance matrix between units
mat <- CreateDistMatrix(knownpts = nuts3.spdf, 
                        unknownpts = nuts3.spdf)

# Merge the data frame and the SpatialPolygonsDataFrame
nuts3.spdf@data <- nuts3.df[match(nuts3.spdf$id, nuts3.df$id),]

# Compute the potentials of population per units
# function = exponential, beta = 2, span = 75 km
poppot <- stewart(knownpts = nuts3.spdf, 
                  unknownpts = nuts3.spdf, 
                  matdist = mat,
                  varname = "pop2008", 
                  typefct = "exponential", 
                  beta = 2, 
                  span = 75000,
                  returnclass = "sf")

# Compute the potentials of GDP per units
# function = exponential, beta = 2, span = 75 km
gdppot <- stewart(knownpts = nuts3.spdf, 
                  unknownpts = nuts3.spdf, 
                  matdist = mat,
                  varname = "gdppps2008", 
                  typefct = "exponential", 
                  beta = 2,
                  span = 75000, 
                  returnclass = "sf")

# Create a data frame of potential GDP per capita
pot <- data.frame(id = nuts3.df$id, 
                  gdpcap = gdppot$OUTPUT * 1000000 / poppot$OUTPUT, 
                  stringsAsFactors = FALSE)

# Discretize the variable
bv2 <- c(min(pot$gdpcap), bv[2:8], max(pot$gdpcap))

# Draw the map
par <- par(mar = c(0,0,1.2,0))

# Draw the basemap
plot(nuts0.spdf, add = F, border = NA, bg = "#cdd2d4")
plot(world.spdf, col = "#f5f5f3ff", border = "#a9b3b4ff", add = TRUE)

# Map the regional potential of GDP per capita
choroLayer(spdf = nuts3.spdf, df = pot, 
           var = "gdpcap", 
           legend.pos = "topright",
           breaks = bv2, col = pal, 
           border = NA,
           legend.title.txt = "Potential\nGDP per capita",
           legend.values.rnd = -2, add = TRUE)
plot(nuts0.spdf, add=T, lwd = 0.5, border = "grey30")
plot(world.spdf, col = NA, border = "#7DA9B8", add=T)

# Set a text to explicit the function parameters
text(x = 6271272, y = 3743765, 
     labels = "Distance function:\n- type = exponential\n- beta = 2\n- span = 75 km", 
     cex = 0.8, adj = 0, font = 3)

# Set a layout
layoutLayer(title = "Wealth Inequality in Europe", 
            sources = "Basemap: UMS RIATE, 2015 - Data: Eurostat, 2008", 
            author = "T. Giraud, 2015")
par(opar)

## ----smoothedmappot, fig.width=7, fig.height=6--------------------------------
# Compute the potentials of population on a regular grid (50km span)
# function = exponential, beta = 2, span = 75 km
poppot <- stewart(knownpts = nuts3.spdf, 
                  varname = "pop2008", 
                  typefct = "exponential", 
                  span = 75000, 
                  beta = 2, 
                  resolution = 50000, 
                  mask = nuts0.spdf, 
                  returnclass = "sf")

# Compute the potentials of GDP on a regular grid (50km span)
# function = exponential, beta = 2, span = 75 km
gdppot <- stewart(knownpts = nuts3.spdf, 
                  varname = "gdppps2008", 
                  typefct = "exponential", 
                  span = 75000, 
                  beta = 2, 
                  resolution = 50000, 
                  mask = nuts0.spdf, 
                  returnclass = "sf")

# Create the ratio variable
poppot$OUTPUT2 <- gdppot$OUTPUT * 1e6 / poppot$OUTPUT

# Create an isopleth layer
pot <- isopoly(x = poppot, var = "OUTPUT2",
               breaks = bv, 
               mask = nuts0.spdf, 
               returnclass = "sf")

# Get breaks values
bv3 <- sort(c(unique(pot$min), max(pot$max)), decreasing = FALSE)

# Draw the map
par <- par(mar = c(0,0,1.2,0))

# Draw the basemap
plot(nuts0.spdf, add = F, border = NA, bg = "#cdd2d4")
plot(world.spdf, col = "#f5f5f3ff", border = "#a9b3b4ff", add = TRUE)

# Map the potential GDP per Capita
choroLayer(x = pot, var = "center", 
           legend.pos = "topright",
           breaks = bv3, col = pal, add=T, 
           border = NA, lwd = 0.2,
           legend.title.txt = "Potential\nGDP per capita",
           legend.values.rnd = -2)
plot(nuts0.spdf, add=T, lwd = 0.5, border = "grey30")
plot(world.spdf, col = NA, border = "#7DA9B8", add=T)

# Set a text to explicit the function parameters
text(x = 6271272, y = 3743765, 
     labels = "Distance function:\n- type = exponential\n- beta = 2\n- span = 75 km", 
     cex = 0.8, adj = 0, font = 3)

# Set a layout
layoutLayer(title = "Wealth Inequality in Europe", 
            sources = "Basemap: UMS RIATE, 2015 - Data: Eurostat, 2008", 
            author = "T. Giraud, 2015")
par(opar)

