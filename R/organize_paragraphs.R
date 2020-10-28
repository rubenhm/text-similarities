# Load libraries
library(tidyr)
library(dplyr)
library(tidytext)
library(reticulate)

# Select python environment
#use_condaenv('py37_fomc')
use_condaenv('gcloud')

# Read pickle file
pd <- import("pandas")
big_df <- pd$read_pickle("data/data-gen/big_df.p")


#' Goals:
#' 1. Split into Minutes and SEPs
#' 2. Extract relevant paragraphs from Minutes and SEPs.
#' - Minutes
#'   + Strip the section on Participants' views on the outlook
#'   + Problem: earlier Minutes don't have headings.
#'   + The relevant section in later Minutes is:
#'   + "Participants' Views on Current Conditions and the Economic Outlook"
#'     This section appears after the staff comments and before the votes.
#'     Headings started in 2009. 
#'     Current version of headings started on November 2009 (the last meeting of 2009)
#' - SEPs
#'   + Strip the forecast summaries with the Participant's views
#'   + SEPs don't have sections, but it's all participants' comments
#' 3. Calculate embedding of paragraphs and documents.
#' 4. Calculate similarities between pairs of documents.


# Generate doc_id 
big_df <- big_df %>%
  mutate(doc_id = substr(id, 1,8))


# Find paragraphs with SEP header
big_df <- big_df %>%
  mutate(SEP_header = if_else(text == "Summary of Economic Projections\r\n", 1, 0))

# Now label all pages following SEP header as "SEP" and previous pages as "Minutes"
big_df <- big_df %>%
  group_by(doc_id) %>%
  mutate( page_sep = max(as.numeric(page) * SEP_header)) %>%
  mutate( doc_type = if_else(as.numeric(page) < page_sep, "Minutes", "SEP")) %>%
  ungroup()

# Make copy
dt <- big_df %>%
  select(id, doc_id, doc_type, page, text, chars, avg_word_height, pos_x, pos_y, width, height, area, char_size )

{ # Drop page headers and sort by reading order (by columns)
  
# Drop page headers
dt <- dt %>%
  filter(pos_y > 0.08)

# Now divide into left/right columns and sort within page
# (Sort paragraphs in reading order within page, first column up to down, second column up to down)
# Note: (pos_x, pos_y) are coordinates of the middle of the paragraph
# calculate left edge pos_x by subtracting width/2
dt <- dt %>%
  mutate(x_pos = pos_x - width/2 ) %>%
  group_by(doc_id, page) %>%
  mutate(column_pos = if_else(x_pos < 0.5, 1, if_else(x_pos > 0.5, 2, 0))) %>% 
  ungroup()

# Sort by column top to bottom
dt <- dt %>%
  group_by(doc_id, page) %>%
  arrange(column_pos, pos_y, .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  ungroup()
}

# Clean up Minutes --------------------------------------------------------

{

# Find relevant paragraphs in the Minutes:
# - First appearance of "Participants' Views in 2009+
# - First appearance of "In conjunction" in 2007-2008
dm <- dt %>%
  group_by(doc_id, doc_type) %>%
  mutate( page_min_views_09 = if_else( doc_type == "Minutes" & 
                                       stringr::str_detect(string = text, pattern = "Participants('|’) Views") &
                                       doc_id >= '20090101', page, 0),
          page_min_views_07 = if_else( doc_type == "Minutes" &
                                       stringr::str_detect(string = text, pattern = "(i|I)n conjunction") &
                                       doc_id <  '20090101', page, 0)
  ) %>% 
  ungroup() %>%
  group_by(doc_id, doc_type) %>%
  mutate( page_min_views = case_when(
    doc_id < '20090101' & doc_type == "Minutes" ~ max(page_min_views_07),
    doc_id >='20090101' & doc_type == "Minutes" ~ max(page_min_views_09)
  )) %>% 
  ungroup()

# Drop pages in the Minutes lower than page_min_views
dm <- dm %>%
  group_by(doc_id, doc_type) %>%
  filter( (doc_type == "Minutes" & page >= page_min_views) | (doc_type == "SEP") ) %>%
  ungroup()

# Drop pages after "voted" in the minutes
# Find first instance of "voted"
dm <- dm %>%
  group_by(doc_id, doc_type ) %>%
  mutate(
    page_min_voted_n = if_else( doc_type == "Minutes" & 
                                stringr::str_detect(string = text, pattern = "At the conclusion"),
                              page, NA_real_)
  ) %>%
  ungroup() %>%
  group_by(doc_id, doc_type) %>%
  mutate( 
    page_min_voted = min(page_min_voted_n, na.rm = TRUE)) %>%
  ungroup()

# Drop pages after "voted"
dm <- dm %>%
  group_by(doc_id, doc_type) %>%
  filter( (doc_type == "Minutes" & page <=  page_min_voted) | doc_type == "SEP" ) %>%
  ungroup()


# Clean up Minutes further

# Drop paragraphs prior to "Participant's"  and following "Voted"
dm <- dm %>%
  mutate( para_participants = case_when(
    doc_type == "Minutes" & doc_id <= '20090101' &
      page_min_views_07 == page_min_views ~ rank,
    doc_type == "Minutes" & doc_id > '20090101' &
      page_min_views_09 == page_min_views ~ rank
  ),
  para_voted = case_when(
    doc_type == "Minutes" & 
      page_min_voted_n == page_min_voted  ~ rank
  )
  )

dm <- dm %>%
  group_by(doc_id, doc_type, page) %>%
  mutate( para_participants_rank = max(para_participants, na.rm = TRUE),
          para_voted_rank = min(para_voted, na.rm = TRUE)) %>%
  ungroup()

# Now drop paragraphs within page
dm <- dm %>%
  group_by(doc_id, doc_type, page) %>%
  filter( ((rank >= para_participants_rank & rank <= para_voted_rank) & (doc_type == "Minutes")) | (doc_type == "SEP") ) %>%
  ungroup()


# Now clean up content in Minutes within bounding paragraphs
# Text before "In conjunction" or before "Participants' Views"
# Text after "At the Conclusion" (inclusive)
dm <- dm %>%
  group_by(doc_id, doc_type, page) %>%
  mutate( 
    text2 = case_when( 
      (para_participants == para_participants_rank) & 
        (!is.na(para_participants)) & 
        (!is.na(para_participants_rank)) &
        doc_id <= '20090101' ~ sub(pattern = '.*In conjunction', replacement = 'In conjunction', x = text),
      (para_participants == para_participants_rank) & 
        (!is.na(para_participants)) & 
        (!is.na(para_participants_rank)) &
        doc_id > '20090101' ~ sub(pattern = ".*Participants('|’) Views", replacement = "Participants' Views", x = text),    
      (para_voted == para_voted_rank) &
        (!is.na(para_voted)) &
        (!is.na(para_voted_rank)) ~ sub(pattern = 'At the conclusion.*', replacement = '', x = text),
      TRUE ~ text
    )
  ) %>%
  ungroup() %>%
  select(id, doc_id, doc_type, page, text, text2, everything())

}

# Clean up SEPs -----------------------------------------------------------

{

# Drop page with "Forecast Uncertainty" box, usually the last page.
ds <- dm %>%
  group_by(doc_id, doc_type) %>%
  mutate( page_fct_uncert_n = if_else( doc_type == "SEP" & 
                                         stringr::str_detect(string = text, pattern = "Forecast Uncertainty"), page, 0),
          
  ) %>%
  ungroup() %>%
  group_by(doc_id, doc_type) %>%
  mutate( page_fct_uncert = max(page_fct_uncert_n) ) %>%
  ungroup()

# Drop pages after "Forecast Uncertainty"
ds <- ds %>%
  group_by(doc_id, doc_type) %>%
  filter( (doc_type == "Minutes") | (page <= page_fct_uncert & doc_type == "SEP")) %>%
  ungroup()


# Drop paragraphs after "Forecast Uncertainty"
ds <- ds %>%
  mutate( para_fct_uncert = case_when(
                              doc_type == "SEP"  &
                              page_fct_uncert == page_fct_uncert_n ~ rank
                            )
  )

ds <- ds %>%
  group_by(doc_id, doc_type, page) %>%
  mutate( para_fct_uncert_rank = min(para_fct_uncert, na.rm = TRUE)) %>%
  ungroup()

# Now drop paragraphs within page
ds <- ds %>%
  group_by(doc_id, doc_type, page) %>%
  filter( ((rank <= para_fct_uncert_rank) & (doc_type == "SEP")) | (doc_type == "Minutes") ) %>%
  ungroup()

# Now clean up content in SEPS 
# Drop text after "Forecast Uncertainty" (inclusive)
ds <- ds %>%
  group_by(doc_id, doc_type, page) %>%
  mutate( 
    text3 = case_when( 
      (para_fct_uncert == para_fct_uncert_rank) & 
        (!is.na(para_fct_uncert)) & 
        (!is.na(para_fct_uncert_rank))  ~ sub(pattern = 'Forecast Uncertainty.*', replacement = '', x = text2),
      TRUE ~ text2
    )
  ) %>%
  ungroup() %>%
  select(id, doc_id, doc_type, page, text, text2, text3, everything())


# Drop pages in the SEPs with small font size
ds <- ds %>%
  group_by(doc_id, doc_type) %>%
  filter( (doc_type == "Minutes") | (doc_type == "SEP" & avg_word_height >= 11.5) ) %>%
  ungroup()


# Drop paragraphs with no text
ds <- ds %>%
  filter(stringr::str_detect(string = text3, pattern = '[a-zA-Z]+'))


# Drop paragraphs with small area, these is charts text
ds <- ds %>%
  filter(area >= 0.0001)

# Drop paragraphs in SEPs starting with "Chart" or "Figure" and have small number of characters
ds <- ds %>%
  filter( (!(stringr::str_detect(string = text3, pattern = "^[ ]*(Chart|Figure)") & chars < 120) & doc_type == "SEP") | 
          (doc_type == "Minutes") 
   )


# Drop entire pages with small number of characters in "SEP"
ds <- ds %>%
  group_by(doc_id, doc_type, page) %>%
  mutate( page_chars = sum(chars) ) %>%
  ungroup()

ds <- ds %>%
  filter( (page_chars > 40 & doc_type == "SEP") | (doc_type == "Minutes") )

# Drop paragraphs with small number of characters
ds <- ds %>%
  mutate(text4 = case_when(
    doc_type == "SEP" & stringr::str_detect(text3, "Summary of Economic Projections") ~ text3,
    doc_type == "SEP" & chars < 40 & !stringr::str_detect(text3, "Summary of Economic Projections") ~ "",
    doc_type == "Minutes" ~ text3,
    TRUE                  ~ text3) 
    ) %>% 
  select(-text2, -text3) %>%
select(id, doc_id, doc_type, page, text, text4, everything()) %>%
  filter(text4 != "")

}


# Prepare text for analysis -----------------------------------------------
# + Concatenate all the paragraphs in the Minutes and SEPs for each meeting.
# + Tokenize into sentences
# + Remove numerals
# + Remove stop words
# + Remove punctuation and symbols

minutes <- ds %>%
  filter(doc_type == "Minutes") %>%
  select(doc_id, doc_type, page, rank, text4) %>%
  group_by(doc_id) %>%
  summarise(text = paste0(text4, collapse = "") ) %>%
  ungroup()

seps <- ds %>%
  filter(doc_type == "SEP") %>%
  select(doc_id, doc_type, page, rank, text4) %>%
  group_by(doc_id) %>%
  summarise(text = paste0(text4, collapse = "") ) %>%
  ungroup()


# Tokenize into sentences, then into words, then remove stop words
data(stop_words)

tidy_minutes <- minutes %>%
  # Replace line feeds, newline characters
  mutate(text = sub(pattern = '\\r\\n', replacement = ' ', x = text)) %>% 
  unnest_tokens(token = "sentences", input = text, output = sentence) %>%
  group_by(doc_id) %>%
  mutate( sentence_id = row_number()) %>%
  unnest_tokens(token = "words", input = sentence, output = word) %>%
  ungroup() %>%
  anti_join(stop_words)

tidy_seps <- seps %>%
  # Replace line feeds, newline characters
  mutate(text = sub(pattern = '\\r\\n', replacement = ' ', x = text)) %>% 
  unnest_tokens(token = "sentences", input = text, output = sentence) %>%
  group_by(doc_id) %>%
  mutate( sentence_id = row_number()) %>%
  unnest_tokens(token = "words", input = sentence, output = word) %>%
  ungroup() %>%
  anti_join(stop_words)

# Remove numbers
tidy_minutes <- tidy_minutes %>%
  filter(!grepl(pattern = '^[0-9\\.+\\-]+$', x = word) )
tidy_seps <- tidy_seps %>%
  filter(!grepl(pattern = '^[0-9\\.+\\-]+$', x = word) )

# Join back into sentences
sent_minutes <- tidy_minutes %>%
  group_by(doc_id, sentence_id) %>%
  summarise(text = paste0(word, collapse = " ") ) %>%
  ungroup()

sent_seps <- tidy_seps %>%
  group_by(doc_id, sentence_id) %>%
  summarise(text = paste0(word, collapse = " ") ) %>%
  ungroup()


# Write data for python
py_save_object(sent_minutes, filename = 'data/data-gen/sent_minutes.p')
py_save_object(sent_seps, filename = 'data/data-gen/sent_seps.p')
