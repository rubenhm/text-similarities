library(dplyr)
library(tidyr)
library(ggplot2)
library(reticulate)


# Select python environment
#use_condaenv('py37_fomc')
use_condaenv('gcloud')

# Read pickle file
pd <- import("pandas")
df_simil <- pd$read_pickle("data/data-gen/df_simil.p")

# Define chart theme ------------------------------------------------------
{
titlecolor = '#3a6f8f' # RGB 58 111 143 (for font)
fontcolor = '#414B56'  # RGB 65 75 86
top_left_chart_title_theme = function(font_size = 18, title_color = titlecolor, font_color = fontcolor) {
  ggplot2::theme(plot.title = ggplot2::element_text(size = font_size + 2, face = "bold", color = titlecolor, hjust = 0, vjust = 0),
                 plot.subtitle = ggplot2::element_text(size = font_size, face = "bold", color = fontcolor, hjust = 0, vjust = 0),
                 plot.caption = ggplot2::element_text(color = 'black', size = font_size, hjust = 0, vjust = 0),
                 plot.background = ggplot2::element_blank(),
                 panel.background = ggplot2::element_blank(),
                 legend.background = ggplot2::element_blank(),
                 legend.text = element_text(size = font_size),
                 axis.text.x = element_text(size = font_size - 4),
                 axis.text.y = element_text(size = font_size)
  )
  }
}


# Make date variable
df_simil <- df_simil %>%
  mutate(date = as.Date(doc_id, format = "%Y%m%d"),
         simil_min_sep = unlist(simil_min_sep),
         simil_min_bb  = unlist(simil_min_bb),
         simil_sep_bb  = unlist(simil_sep_bb))

# Make data long format
df_long <- df_simil %>%
  pivot_longer(cols = -c(doc_id, date), names_prefix = "simil_", values_to = "similarity")

short_fmt <- function(x) {
  sprintf("%3.2f",x)
}

date_fmt <- function(x) {
  format(x,"%m/%d/%y")
}



{
  df.chart <- df_long %>%
    select(-doc_id)
  
  dates <- df.chart$date %>% unique()
  
  p.simil <- df.chart %>%
    ggplot(aes(x = date, y = similarity, color = name)) +
    geom_line(aes(group = name),size = 1.2) +
    geom_point(aes(group = name), size = 2) +
    labs(
      title = "Semantic Similarity among the FOMC Minutes, Summary of Economic Projections, and the Beige Book",
      subtitle = "Cosine similarity between pairs of document embeddings",
      caption = paste0("Document embeddings calculated as average of sentence embedding using the Python library",
                       "\nSentence-transformers <https://github.com/UKPLab/sentence-transformers>."),
      x = "FOMC Meeting date",
      y = ""
    ) +
    scale_x_date(breaks = dates[seq(from = 1, by = 4, to = NROW(dates))], labels = date_fmt) + 
    scale_y_continuous(breaks = seq(from = 0.60, to = 1, by = 0.05), labels = short_fmt) +
    theme_light() +
    top_left_chart_title_theme() +
    theme(
      panel.border = element_blank(),
      legend.title = element_blank(),
      legend.position = c(0.8, 0.40),
      panel.grid.minor.x = element_blank()
    )
  
  ggsave(filename = 'charts/plot_fomc_similarities.png', plot = p.simil, width = 16, height = 9)
  }
