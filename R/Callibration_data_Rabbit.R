# Prepare observational data from rabbit censuses to use for callibration of rabbit model

library(dplyr)
library(terra)
library(sf)
library(lubridate)

#--------------------------------------------------------------------------------------------------
# Donana night Censuses
#--------------------------------------------------------------------------------------------------
if(!(dir.exists("observation_data/Donana_conejos/"))) {dir.create("observation_data/Donana_conejos/", recursive = T)}

file.copy(from = "data/original_data/Rabbit_donana_KAI_PacoCarro/KAI_Rabbit_Night_2024_v1.csv", to = "observation_data/Donana_conejos/KAI_Rabbit_Night_2024_v1.csv")
file.copy(from = "data/original_data/Rabbit_donana_KAI_PacoCarro/Transect_oryctolagus.kml", to = "observation_data/Donana_conejos/Transect_oryctolagus.kml")

#--------------------------------------------------------------------------------------------------
# IberLince Censuses
#--------------------------------------------------------------------------------------------------
ilc_folder = "data/original_data/IberLince_Conejo_Censuses/"

count_points_per_line <- function(points, lines, distance = 0) {
  
  # Ensure both layers have the same CRS
  if (!same.crs(points, lines)) {
    points <- project(points, crs(lines))
    message("Reprojecting points to match lines CRS")
  }
  
  # Initialize a count column
  lines$point_count <- 0
  
  # For each line, count points that satisfy spatial relationships
  for (i in 1:nrow(lines)) {
    line_geom <- lines[i, ]
    
    # Count using different spatial predicates (matching QGIS "all options")
    # 1. Intersects (points on or very near the line)
    intersects_count <- nrow(points[line_geom, ])
    
    # 2. Within distance (if distance > 0, acts as buffer)
    if (distance > 0) {
      line_buffer <- buffer(line_geom, width = distance)
      within_dist_count <- nrow(points[line_buffer, ])
      lines$point_count[i] <- within_dist_count
    } else {
      lines$point_count[i] <- intersects_count
    }
  }
  
  return(lines)
}

transect2018 <- vect(file.path(ilc_folder, "2018_IBERLINCE_TRACKS_CRG.shp"))
transect2023 <- vect(file.path(ilc_folder, "2023_LYNXCONNECT_tracks.shp"))
transect2024 <- vect(file.path(ilc_folder, "2024_LYNXCONNECT_tracks.shp"))

transect2018$Id <- paste0( "2018_" , tibble::rowid_to_column(as.data.frame(transect2018), var = "row_id")$row_id)
transect2023$Id <- paste0( "2023_" , tibble::rowid_to_column(as.data.frame(transect2023), var = "row_id")$row_id)
transect2024$Id <- paste0( "2024_" , tibble::rowid_to_column(as.data.frame(transect2024), var = "row_id")$row_id)

transect2018 <- subset(transect2018, !is.na(transect2018$Fecha))
transect2023 <- subset(transect2023, !is.na(transect2023$Fecha))
transect2024 <- subset(transect2024, !is.na(transect2024$fecha))


latrinas2018 <- vect(file.path(ilc_folder, "2018_IBERLINCE_LETRINAS.shp"))
latrinas2023 <- vect(file.path(ilc_folder, "2023_LYNXCONNECT_letrinas.shp"))
latrinas2024 <- vect(file.path(ilc_folder, "2024_LYNXCONNECT_letrinas.shp"))

df18 <- count_points_per_line(latrinas2018, transect2018, 30)
df23 <- count_points_per_line(latrinas2023, transect2023, 30)
df24 <- count_points_per_line(latrinas2024, transect2024, 30)

df18$length <- terra::perim(df18)/1000
df23$length <- terra::perim(df23)/1000
df24$length <- terra::perim(df24)/1000

df18$KAI_calc <- df18$point_count / df18$length
df23$KAI_calc <- df23$point_count / df23$length
df24$KAI_calc <- df24$point_count / df24$length


df18$date <- as.Date(parse_date_time(df18$Fecha, 
                orders = c("Ymd", "d-m-y", "ymd", "b-Y", "dmy"),
                truncated = 2))

df18$date <- floor_date(df18$date, "month") + days(14)

a <- as.data.frame(df18) %>%
  mutate(year = year(date),
         month = month(date)) %>%
  group_by(year, month) %>%
  mutate(KAI_scale = KAI_calc/max(KAI_calc)) %>% 
  dplyr::select(Id, year, month, KAI_scale)
df18 <- terra::merge(df18, a, by = "Id")
df18 <- df18[, c("Id", "year", "month", "length", "KAI_calc", "KAI_scale")]

df23$date <- as.Date(parse_date_time(df23$Fecha, 
                                     orders = c("Ymd", "d-m-y", "ymd", "b-Y", "dmy"),
                                     truncated = 2))

df23$date <- floor_date(df23$date, "month") + days(14)
b <- as.data.frame(df23) %>%
  mutate(year = year(date),
         month = month(date)) %>%
  filter(year > 2020) %>%
  group_by(year, month) %>%
  mutate(KAI_scale = KAI_calc/max(KAI_calc)) %>% 
  dplyr::select(Id, year, month, KAI_scale)
df23 <- merge(df23, b, by = "Id")
df23 <- df23[, c("Id", "year", "month", "length", "KAI_calc", "KAI_scale")]

              
df24$date <- as.Date(parse_date_time(df24$fecha, 
                                     orders = c("Ymd", "d-m-y", "ymd", "b-Y", "dmy"),
                                     truncated = 2))
df24$date <- floor_date(df24$date, "month") + days(14)

c <- as.data.frame(df24) %>%
  mutate(year = year(date),
         month = month(date)) %>%
  filter(year > 2020) %>%
  group_by(year, month) %>%
  mutate(KAI_scale = KAI_calc/max(KAI_calc)) %>% 
  dplyr::select(Id, year, month, KAI_scale)
df24 <- merge(df24, c, by = "Id")
df24 <- df24[, c("Id", "year", "month", "length", "KAI_calc", "KAI_scale")]

df_IL <- rbind(df18,df23,df24)


if(!(dir.exists("observation_data/IberLince_conejo_census/"))) {dir.create("observation_data/IberLince_conejo_census/", recursive = T)}
write.csv(as.data.frame(df_IL), file.path("observation_data", "IberLince_conejo_census", "IberLince_Conejos_relative_monthly_KAI.csv"))
writeVector(df_IL, file.path("observation_data", "IberLince_conejo_census", "transects.shp"), overwrite=T)










