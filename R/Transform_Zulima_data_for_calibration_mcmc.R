library(dplyr)
library(readxl)
library(terra)

df <- read_xls("data/original_data/20250131_base_datos_Sanne.xls")

# Transform Pellet count to rabbit abundance (Rabbit/ha)  ---------- is this needed or are the values already tranformed?
# Using results from Fernandez-de-Simon et al., 2011 - table 2 for STA
# Rabbits per ha = 0.004 * pellets  -> r^2 = 0.7
# df$observed_abundance <- df$pellets * 0.004

## Transform points to x & y cell number to link to maps in model
habitat_rast <- rast('data/pre_processed_data/HabitatMap_500_Donana_Fordham_2013.asc')

s <- sf::st_as_sf(data.frame(x = df$UTM_X30, y = df$UTM_Y30), coords = c("x", "y"), crs = "EPSG:32630")
s <- sf::st_transform(s, crs = "EPSG:3035")
s <- sf::st_coordinates(s)

r_df <- data.frame(sim_year = df$year - 1979,
                   Lat = s[,1],
                   Lon = s[,2],
                   col = colFromX(habitat_rast, s[,1]), 
                   row = rowFromY(habitat_rast, s[,2]),
                   observed = df$pellets,
                   presence = df$presencia_pellets) %>%
  arrange(sim_year, col, row)

# There's a few point that fall in the same 500x500 cells, so taking the average of those
r_df_av <- r_df %>%
  group_by(sim_year, col, row) %>%
  summarise(observed = round(mean(observed, na.rm = T), digits = 3))

write.csv(r_df_av, 'data/pre_processed_data/rabbit_observed_for_mcmc.csv', row.names = F)


a <- rasterize(cbind(r_df$Lat, r_df$Lon), habitat_rast, values = r_df$observed)

plot(habitat_rast)
plot(a, add = T, col = rainbow(4), legend = F)





corine_rast <- rast("data/original_data/U2018_CLC2018_V2020_20u1.tif")
corine_rast <- crop(corine_rast, ext(2800000, 2890000, 1678000, 1750000))

presence <- r_df %>%
  group_by(sim_year, Lat, Lon) %>%
  summarise(observed = sum(observed, na.rm = T)) %>%
  filter(observed > 0) %>% 
  ungroup() %>%
  select(Lat, Lon) %>%
  distinct()

n_census <- r_df %>%
  select(Lat, Lon) %>%
  distinct()

hab_1_values <- terra::extract(habitat_rast, cbind(presence$Lat, presence$Lon)) 
table(hab_1_values)

hab_0_values <- terra::extract(habitat_rast, cbind(n_census$Lat, n_census$Lon)) 
table(hab_0_values)



cor_1_values <- terra::extract(corine_rast, cbind(presence$Lat, presence$Lon)) 
table(cor_1_values)

cor_0_values <- terra::extract(corine_rast, cbind(n_census$Lat, n_census$Lon)) 
table(cor_0_values)

