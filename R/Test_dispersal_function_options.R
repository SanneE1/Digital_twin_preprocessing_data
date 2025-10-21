# Function to test basic dispersal function and get some rough estimates for parameters that makes sense based on some literature
# planning on doing more extensive parameter selection with the full rabbit model in pascal


library(dplyr)
library(ggplot2)

# #--------------------------------------
# # First function tested
# #--------------------------------------
# 
# disp_p <- function(dist, dens, lambda = 1, sigma = 2) {
#   
#   exp(-lambda * dens) / ((1 + dist)^sigma)
#   
# }
# 
# # check results for different distances with stable densities
# df <- expand.grid(x = c(-3:3), y = c(-3:3)) %>% rowwise() %>%
#   mutate(dist = max(c(abs(x), abs(y))),
#          dens = 10) %>%
#   tidyr::expand_grid(., sigma = seq(0,4, length.out = 20)) %>%
#   mutate(disp_1 = disp_p(dist, dens, sigma = sigma)) %>% 
#   ungroup() %>% group_by(sigma) %>%
#   mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T))
# 
# # probability to move to the different cells
# ggplot(df, aes(x = x, y = y, fill = disp_1_s)) +
#   geom_tile() +
#   scale_fill_continuous(type = "viridis") + 
#   facet_wrap(vars(sigma))
# 
# # probability to move to the different "rings"
# ggplot(df, aes(x = dist, y = disp_1_s, color = sigma, group = sigma)) +
#   stat_summary(fun = sum, geom = "line", position = "dodge") +
#   scale_color_continuous(type = "viridis")
#   
#   
# # check effect of density with equal distances
# df1 <- data.frame(dist = 1,
#          dens = c(0:15)) %>%
#   tidyr::expand_grid(., lambda = seq(-1,5, length.out = 30)) %>%
#   mutate(disp_1 = disp_p(dist, dens, lambda = lambda)) %>% 
#   ungroup() %>% group_by(lambda) %>%
#   mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T))
# 
# # probability to move to the different cells
# ggplot(df1, aes(x = dens, y = disp_1_s, color = lambda)) +
#   geom_point() +
#   scale_color_continuous(type = "viridis")
# 
# # --------------------------------------
# # Test a different function
# # --------------------------------------
# 
# disp_p1 <- function(dist, dens, dens_opt = 3, lambda = 1, sigma = 2) {
# 
#   exp(-lambda * (dens - dens_opt)^2) / ((1 + dist)^sigma)
# 
# }
#   
# 
# # check results for different distances with stable densities
# df2 <- expand.grid(x = c(-3:3), y = c(-3:3)) %>% rowwise() %>%
#   mutate(dist = max(c(abs(x), abs(y))),
#          dens = 10) %>%
#   tidyr::expand_grid(., sigma = seq(0,4, length.out = 20)) %>%
#   mutate(disp_1 = disp_p1(dist, dens, sigma = sigma)) %>% 
#   ungroup() %>% group_by(sigma) %>%
#   mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T))
# 
# # probability to move to the different cells
# ggplot(df2, aes(x = x, y = y, fill = disp_1_s)) +
#   geom_tile() +
#   scale_fill_continuous(type = "viridis") + 
#   facet_wrap(vars(sigma))
# 
# # probability to move to the different "rings"
# ggplot(df2, aes(x = dist, y = disp_1_s, color = sigma, group = sigma)) +
#   stat_summary(fun = sum, geom = "line", position = "dodge") +
#   scale_color_continuous(type = "viridis")
# 
# 
# # check effect of density with equal distances
# df3 <- data.frame(dist = 1,
#                   dens = c(0:15)) %>%
#   tidyr::expand_grid(., lambda = seq(0,3, length.out = 30)) %>%
#   mutate(disp_1 = disp_p1(dist, dens, lambda = lambda)) %>% 
#   ungroup() %>% group_by(lambda) %>%
#   mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T))
# 
# # probability to move to the different cells
# ggplot(df3, aes(x = dens, y = disp_1_s, color = lambda)) +
#   geom_point() +
#   scale_color_continuous(type = "viridis")


#--------------------------------------
# Starting values for parameters 
#--------------------------------------
# 
# dens_opt = 3
# lambda = 0.1
# sigma = 2.5

disp_prob <- function(dist, dens, dens_opt = 3, lambda = 0.001, sigma = 1) {
  
  exp(-lambda * (dens - dens_opt)^2) / ((1 + dist)^sigma)
  
}

# Distance probability
data.frame(dist = c(0:5), dens = 3) %>%
  mutate(disp_1 = disp_prob(dist, dens)) %>%
  mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T)) %>%
  ggplot(.) +
  geom_line(aes(x = dist, y = disp_1_s)) +
  theme_minimal(base_size = 16) +
  ylab("probability of \nmoving to cell") + xlab("# of cells distance")

# Accounting for more cells with more distance
expand.grid(x = c(-5:5), y = c(-5:5)) %>% rowwise() %>%
  mutate(dist = max(c(abs(x), abs(y))),
         dens = 3) %>%
  mutate(disp_1 = disp_prob(dist, dens)) %>% 
  ungroup() %>% 
  mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T)) %>%
  ggplot(., aes(x = dist, y = disp_1_s)) +
  stat_summary(fun = sum, geom = "line") +
  theme_minimal(base_size = 16) +
  ylab("probability of \nmoving to distance") + xlab("# of cells distance")

# dispersal at same distance with different densities
data.frame(dist = 1, dens = c(0:15)) %>%
  mutate(disp_1 = disp_prob(dist, dens)) %>%
  mutate(disp_1_s = disp_1 / sum(disp_1, na.rm = T)) %>%
  ggplot(.) +
  geom_line(aes(x = dens, y = disp_1_s)) +
  theme_minimal(base_size = 16) +
  ylab("probability of \nmoving to cell") + xlab("Rabbit abundance in cell")







  