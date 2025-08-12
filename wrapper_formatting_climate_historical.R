source("R/Format_climate_data_for_rabbit.R")


calculate_BM_cDM(download_location = "data/pre_processed_data/Climate_Donana_500/",
                 year_min = 2002, 
                 year_max = 2018,
                 result_dir = "input_data/climate_donana_historic/",
                 coord_file = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt",
                 temperature_type = "mean")



calculate_BM_cDM(download_location = "data/pre_processed_data/Climate_Peninsula_500/",
                 year_min = 2002, 
                 year_max = 2018,
                 result_dir = "input_data/climate_peninsula_historic/",
                 coord_file = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt",
                 temperature_type = "mean")





