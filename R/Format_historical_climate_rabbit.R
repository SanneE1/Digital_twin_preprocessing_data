library(terra)

# ---------------------------------------------------------------------------------------------
# Extract WorldClim values from tif files
# ---------------------------------------------------------------------------------------------

files <- list.files("data/original_data/WorldClimCruts4.09_2.5min/", full.names = T)

coords_donana <- read.table("data/pre_processed_data/coordinates_donana_500_EPSG4326.txt")[,c(1,2)]
coords_peninsula <- read.table("data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt")[,c(1,2)]

if (!dir.exists(file.path("data", "pre_processed_data", "climate_donana_historic"))) {dir.create(file.path("data", "pre_processed_data", "climate_donana_historic"), recursive = T)}
if (!dir.exists(file.path("data", "pre_processed_data", "climate_peninsula_historic"))) {dir.create(file.path("data", "pre_processed_data", "climate_peninsula_historic"), recursive = T)}


for (file in files) {

a <- strsplit(file, "[[:punct:]]")
month = a[[1]][16]
year = a[[1]][15]
var = a[[1]][14]
if (var == "prec") {var = "pr"} else if (var == "tmax") {var = "tasmax"} else if (var == "tmin") {var = "tasmin"} else {stop("Wrong variable string")}

tif <- terra::rast(file)
tif <- crop(tif, ext(-11.81, 4.25, 34.7, 45.39))
tif <- terra::focal(tif, w=9, mean, na.policy = "only", na.rm=T)  # This line is here to create some extra coastline so that all habitat cells will have climate variables

dfD <- raster::extract(tif, coords_donana)

dfP <- raster::extract(tif, coords_peninsula)

write.table(dfD[,2], file = file.path("data", "pre_processed_data", "climate_donana_historic", 
                                      paste0(paste("WorldClimCruts", var, year, month, sep = "_"), ".txt")), 
            row.names = F, col.names = F)
write.table(dfP[,2], file = file.path("data", "pre_processed_data", "climate_peninsula_historic",
                                      paste0(paste("WorldClimCruts", var, year, month, sep = "_"), ".txt")),
            row.names = F, col.names = F)

}         
    
# ---------------------------------------------------------------------------------------------
# Format to rabbit variables
# ---------------------------------------------------------------------------------------------

source("R/Format_climate_data_for_rabbit.R")

# WorldClim 
 calculate_BM_cDM(download_location = "data/pre_processed_data/climate_donana_historic/",
                  year_min = 2002,
                  year_max = 2024,
                  result_dir = "input_data/climate_donana_historic/",
                  coord_file = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt",
                  temperature_type = "worldclimhist")

# calculate_BM_cDM(download_location = "data/pre_processed_data/climate_peninsula_historic/",
#                  year_min = 2002, 
#                  year_max = 2024,
#                  result_dir = "input_data/climate_peninsula_historic/",
#                  coord_file = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt",
#                  temperature_type = "worldclimhist")

#CHELSA
calculate_BM_cDM(download_location = "data/pre_processed_data/CHELSA_Donana_500/",
                 year_min = 2002,
                 year_max = 2018,
                 result_dir = "input_data/climate_donana_historic_CHELSA/",
                 coord_file = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt",
                 temperature_type = "chelsahist")

calculate_BM_cDM(download_location = "data/pre_processed_data/CHELSA_Peninsula_500/",
                 year_min = 2002,
                 year_max = 2018,
                 result_dir = "input_data/climate_peninsula_historic_CHELSA/",
                 coord_file = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt",
                 temperature_type = "chelsahist")


