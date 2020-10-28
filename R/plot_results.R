library(dplyr)
library(tidyr)
library(ggplot2)
library(reticulate)


# Select python environment
#use_condaenv('py37_fomc')
use_condaenv('gcloud')

# Read pickle files
pd <- import("pandas")
df_cosine <- pd$read_pickle("data/data-gen/df_cosine.p")
df_euclid <- pd$read_pickle("data/data-gen/df_euclid.p")
df_pearsn <- pd$read_pickle("data/data-gen/df_pearsn.p")


# Define chart theme ------------------------------------------------------
{
titlecolor = '#3a6f8f' # RGB 58 111 143 (for font)
fontcolor = '#414B56'  # RGB 65 75 86
top_left_chart_title_theme = function(font_size = 18, title_color = titlecolor, font_color = fontcolor) {
  ggplot2::theme(plot.title = ggplot2::element_text(size = font_size + 2, face = "bold", color = titlecolor, hjust = 0, vjust = 0),
                 plot.subtitle = ggplot2::element_text(size = font_size, face = "bold", color = fontcolor, hjust = 0, vjust = 0),
                 plot.caption = ggplot2::element_text(color = 'black', size = font_size - 6, hjust = 0, vjust = 0),
                 plot.background = ggplot2::element_blank(),
                 panel.background = ggplot2::element_blank(),
                 legend.background = ggplot2::element_blank(),
                 legend.text = element_text(size = font_size),
                 axis.text.x = element_text(size = font_size - 4),
                 axis.text.y = element_text(size = font_size)
  )
  }
}


# Prepare data for charts -------------------------------------------------

# Make date variable
df_cosine <- df_cosine %>%
  mutate(date = as.Date(doc_id, format = "%Y%m%d"))
df_euclid <- df_euclid %>%
  mutate(date = as.Date(doc_id, format = "%Y%m%d"))
df_pearsn <- df_pearsn %>%
  mutate(date = as.Date(doc_id, format = "%Y%m%d"))

# Make data long format
df_chart_cosine <- df_cosine %>%
  select(-doc_id) %>%
  pivot_longer(cols = -c(date), names_prefix = "cosine_", values_to = "similarity") %>%
  mutate( docs = case_when(
    name == "min_sep"  ~ "Minutes — SEPs",
    name == "min_beb"  ~ "Minutes — Beige Book",
    name == "min_mov"  ~ "Minutes — Movie Summaries",
    name == "sep_beb"  ~ "SEPs — Beige Book",
    name == "sep_mov"  ~ "SEPs — Movie Summaries",
    name == "beb_mov"  ~ "Beige Book — Movie Summaries"
  )) %>% select(-name)

df_chart_euclid <- df_euclid %>%
  select(-doc_id) %>%
  pivot_longer(cols = -c(date), names_prefix = "euclid_", values_to = "similarity") %>%
  mutate( docs = case_when(
    name == "min_sep"  ~ "Minutes — SEPs",
    name == "min_beb"  ~ "Minutes — Beige Book",
    name == "min_mov"  ~ "Minutes — Movie Summaries",
    name == "sep_beb"  ~ "SEPs — Beige Book",
    name == "sep_mov"  ~ "SEPs — Movie Summaries",
    name == "beb_mov"  ~ "Beige Book — Movie Summaries"
  )) %>% select(-name)


df_chart_pearsn <- df_pearsn %>%
  select(-doc_id) %>%
  pivot_longer(cols = -c(date), names_prefix = "pearsn_", values_to = "similarity") %>%
  mutate( docs = case_when(
    name == "min_sep"  ~ "Minutes — SEPs",
    name == "min_beb"  ~ "Minutes — Beige Book",
    name == "min_mov"  ~ "Minutes — Movie Summaries",
    name == "sep_beb"  ~ "SEPs — Beige Book",
    name == "sep_mov"  ~ "SEPs — Movie Summaries",
    name == "beb_mov"  ~ "Beige Book — Movie Summaries"
  )) %>% select(-name)


short_fmt <- function(x) {
  sprintf("%3.2f",x)
}

date_fmt <- function(x) {
  format(x,"%m/%d/%y")
}


dates <- df_chart_cosine$date %>% unique()


# Cosine similarity -------------------------------------------------------

{
  
  p.cosine.fomc <- df_chart_cosine %>% 
    filter( !stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity among the FOMC Minutes, Summary of Economic Projections, \nand the Beige Book",
      subtitle = "Cosine similarity between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.35),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_cosine_fomc.png', plot = p.cosine.fomc, width = 16, height = 9)

  p.cosine.movies <- df_chart_cosine %>% 
    filter( stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity between the FOMC Minutes, Summary of Economic Projections, \nthe Beige Book, and Movie Summaries",
      subtitle = "Cosine similarity between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.8),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_cosine_movies.png', plot = p.cosine.movies, width = 16, height = 9)
  
}



# Euclidean similarity ----------------------------------------------------


{
  
  p.euclid.fomc <- df_chart_euclid %>% 
    filter( !stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity among the FOMC Minutes, Summary of Economic Projections, \nand the Beige Book",
      subtitle = "Euclidean similarity between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• Euclidean similarity is calculated as 1 - d(x,y), where d is Euclidean distance, normalized by (|x|+|y|).",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.35),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_euclid_fomc.png', plot = p.euclid.fomc, width = 16, height = 9)
  
  p.euclid.movies <- df_chart_euclid %>% 
    filter( stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity between the FOMC Minutes, Summary of Economic Projections, \nthe Beige Book, and Movie Summaries",
      subtitle = "Euclidean similarity between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• Euclidean similarity is calculated as 1 - d(x,y), where d is Euclidean distance, normalized by (|x|+|y|).",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.8),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_euclid_movies.png', plot = p.euclid.movies, width = 16, height = 9)
  
}




# Pearson correlation -----------------------------------------------------
{
  
  p.pearsn.fomc <- df_chart_pearsn %>% 
    filter( !stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity among the FOMC Minutes, Summary of Economic Projections, \nand the Beige Book",
      subtitle = "Pearson correlation between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.35),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_pearsn_fomc.png', plot = p.pearsn.fomc, width = 16, height = 9)
  
  p.pearsn.movies <- df_chart_pearsn %>% 
    filter( stringr::str_detect(docs,'Movie') ) %>%
    ggplot(aes(x = date, y = similarity, color = docs)) +
    geom_line(aes(group = docs),size = 1.2) +
    geom_point(aes(group = docs), size = 2) +
    labs(
      title = "Semantic Similarity between the FOMC Minutes, Summary of Economic Projections, \nthe Beige Book, and Movie Summaries",
      subtitle = "Pearson correlation between pairs of document embeddings",
      caption = paste0("Notes:", 
                       "\n• Document embeddings calculated with the Sentence-transformers library,",
                       "<https://github.com/UKPLab/sentence-transformers>.",
                       "\n• The Beige Book is released about two weeks before each FOMC meeting.",
                       "\nSources:",
                       "\n• Minutes and SEPs were collected from <https://www.federalreserve.gov/monetarypolicy/fomc_historical.htm>.",
                       "\n• Beige Books were collected from <https://www.minneapolisfed.org/region-and-community/regional-economic-indicators/beige-book-archive>.",
                       "\n• Movie summaries are for the movies that opened on the date of the FOMC meeting, ",
                       " collected with the New York Times API <https://developer.nytimes.com/>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.0, to = 1, by = 0.1), 
                       labels = short_fmt, limits = c(0,1)) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.8),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_pearsn_movies.png', plot = p.pearsn.movies, width = 16, height = 9)
  
}

