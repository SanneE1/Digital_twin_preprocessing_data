
library(terra)

##------------------------------------------------------
## Get coordinates
##------------------------------------------------------

rast_file_peninsula = "data/pre_processed_data/Rabbit_HabitatMap_500_Peninsula_Fordham_2013.asc"
rast_file_donana = "data/pre_processed_data/Rabbit_HabitatMap_500_Donana_Fordham_2013.asc"

mat_dim_p = 4822110
mat_dim_d = 25920
  

donana <- rast(rast_file_donana)
peninsula <- rast(rast_file_peninsula)

coor_d <- cbind(xyFromCell(object = donana, cell = c(1:mat_dim_d)), 
                 col = colFromCell(object = donana, cell = c(1:mat_dim_d)),
                 row = rowFromCell(object = donana, cell = c(1:mat_dim_d)))
colnames(coor_d) <- c("Longitude", "Latitude", "col", "row")

coor_p <- cbind(xyFromCell(object = peninsula, cell = c(1:mat_dim_p)), 
                col = colFromCell(object = peninsula, cell = c(1:mat_dim_p)),
                row = rowFromCell(object = peninsula, cell = c(1:mat_dim_p)))
colnames(coor_p) <- c("Longitude", "Latitude", "col", "row")


# The coordinates are currently in ETRS89 but need to be in WGS84 to get the correct coordinates for CHELSA tiffs. 
# reprojecting the spatraster first changes the cells meaning the climate wouldn't line up with the other maps!!!
write.table(coor_d, file = "data/pre_processed_data/coordinates_donana_500_EPSG3035.txt", sep = " ", row.names = F, col.names = F)
write.table(coor_p, file = "data/pre_processed_data/coordinates_peninsula_500_EPSG3035.txt", sep = " ", row.names = F, col.names = F)





