# Load libraries
library(tidyr)
library(dplyr)

library(reticulate)

# Select python environment
use_condaenv('py37_fomc')

# Read pickle file
pd <- import("pandas")
big_df <- pd$read_pickle("data/data-gen/big_df.p")

# Generate doc_id and fix page number
big_df <- big_df %>%
  mutate(doc_id = substr(id, 1,8))


# Find paragraphs with SEP header
big_df <- big_df %>%
  mutate(SEP_header = if_else(text == "Summary of Economic Projections\r\n", 1, 0))

# Now label all pages following SEP header as SEP and previous pages as Minutes
big_df <- big_df %>%
  group_by(doc_id) %>%
  mutate( page_sep = max(as.numeric(page) * SEP_header)) %>%
  mutate( doc_type = if_else(as.numeric(page) < page_sep, "Minutes", "SEP")) %>%
  ungroup()
