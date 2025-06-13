with open('input_data/Lynx_input_parameters.txt', 'w') as f:
    f.write('min_rep_age 3\n')
    f.write('max_rep_age 12\n')
    f.write('max_age 16\n')
    f.write('Tsize 2\n')
    f.write('litter_size 1.9\n')
    f.write('litter_size_sd 0.54\n')
    f.write('rep_prob 0.57\n')
    f.write('surv_cub 0.384\n')
    f.write('surv_sub 0.599\n')
    f.write('surv_resident 0.798\n')
    f.write('surv_disperse 0.798\n')
    f.write('surv_disp_rho 5.8\n')
    f.write('surv_old 0.594\n')
    f.write('alpha_steps 0.00027\n')
    f.write('theta_d 0.4\n')
    f.write('theta_delta 0.65\n')
    f.write('delta_theta_long 0.27\n')
    f.write('delta_theta_f 0.1\n')
    f.write('L 6\n')
    f.write('N_d 5\n')
    f.write('beta 0.8\n')
    f.write('gamma 0.09\n')
    f.write('max_years 17\n')
    f.write('n_cycles 3\n')
    f.write('n_months_above_R_threshold 12\n')
    f.write('create_maps 1\n')
    f.write('mapname input_data/maps/Lynx_HabitatMap_500_Donana_Revilla_2015_1.txt\n')
    f.write('mapPops input_data/maps/Lynx_populations_500_IUCN75.txt\n')
    f.write('start_pop_file input_data/Lynx_start_pop_Donana_2002.txt\n')
    f.write('reintro_file input_data/Lynx_reintroduced_ind_donana.txt\n')


with open('input_data/Rabbit_input_parameters.txt', 'w') as f:
    f.write('max_age 82\n')
    f.write('juv_age 4\n')
    f.write('sub_adult_age 6\n')
    f.write('disp_age 5\n')
    f.write('MeanLitSize 3.5\n')
    f.write('SdLitSize 1\n')
    f.write('r_int -2\n')
    f.write('r_dens_effect 3\n')
    f.write('r_second_effect 1\n')
    f.write('r_later_effect 5\n')
    f.write('kCapacity_high 14\n')
    f.write('kCapacity_low 10\n')
    f.write('MortP_at_month_old 0.5\n')
    f.write('s_int 8\n')
    f.write('s_extra_juv 3\n')
    f.write('s_dens_effect 3\n')
    f.write('s_food_effect 20\n')
    f.write('lambda 0.1\n')
    f.write('dens_opt 3\n')
    f.write('sigma 2.5\n')
    f.write('threshold_density_for_lynx 5\n')
    f.write('mapname_rabbit input_data/maps/Rabbit_HabitatMap_test.txt\n')
    f.write('breedname input_data/breeding_months_donana_historic_2002_2018.txt\n')
    f.write('dryname input_data/consecutive_dry_months_donana_historic_2002_2018.txt\n')



## Write some files with dummy variables    
with open('input_data/Lynx_start_pop_donana_2002.txt', 'w') as f:
    f.write('N X Y pop\n')
    f.write('74 95 73 Donana\n')


with open('input_data/Lynx_reintroduced_ind_donana_2002.txt', 'w') as f:
    f.write('Year X Y N_individuals Sex Age\n')
    f.write('2009 95 73 3 f 3\n')
    f.write('2011 95 73 2 f 1\n')
    f.write('2011 95 73 3 m 1\n')
    f.write('2014 95 73 4 f 1\n')
    f.write('2014 95 73 4 m 1\n')




