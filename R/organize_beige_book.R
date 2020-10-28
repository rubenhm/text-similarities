# Load libraries
library(xml2)
library(rvest)
library(magrittr)
library(tibble)
library(dplyr)
library(tidyr)
library(dplyr)
library(tidytext)

library(reticulate)

# Select python environment
#use_condaenv('py37_fomc')
use_condaenv('gcloud')

# Prepare text for analysis -----------------------------------------------
dates.seps <- c('20071031',
                '20080130',
                '20080430',
                '20080625',
                '20081029',
                '20090128',
                '20090429',
                '20090624',
                '20091104',
                '20100127',
                '20100428',
                '20100623',
                '20101103',
                '20110126',
                '20110427',
                '20110622',
                '20111102',
                '20120125',
                '20120425',
                '20120620',
                '20120913',
                '20121212',
                '20130320',
                '20130619',
                '20130918',
                '20131218',
                '20140319',
                '20140618',
                '20140917',
                '20141217',
                '20150318',
                '20150617',
                '20150917',
                '20151216',
                '20160316',
                '20160615',
                '20160921',
                '20161214',
                '20170315',
                '20170614',
                '20170920',
                '20171213',
                '20180321',
                '20180613',
                '20180926',
                '20181219',
                '20190320',
                '20190619',
                '20190918',
                '20191211',
                '20200610',
                '20200916')

# Calculate date of corresponding beige book, subtract 2 weeks
dates.bb <- as.Date(dates.seps, format = '%Y%m%d') - 14 

# Function to process BB text from html sources
# Input is one html source file.
# Output is a dataframe of a single report by rows
processBBhtml <- function(filepath) {
  bbtext <- xml2::read_html(filepath)
  # Parse into array of paragraphs in plain text
  bb.text <- bbtext %>%
    rvest::html_nodes(x = . , xpath = '//*[@id="i9-l-base"]/div[2]/div/div[2]') %>%
    rvest::html_text(x = .) %>%
    gsub("^.*[bB]ack to [aA]rchive [sS]earch","",.) 
  # Process date
  monthsStr <- c("January","February","March","April","May","June",
                 "July","August","September","October","November",
                 "December")
  # Extract date from document using regex
  expr <- paste0("(",paste0(monthsStr, collapse = "|"),")(\\s+\\d{1,2}\\s*(,|)\\s+\\d{4})")
  m <- regexpr(expr, bb.text)
  m.date <- regmatches(bb.text, m)
  # Remove comma from date string
  m.date <- gsub("\\s+"," ",gsub("\\s*,","",m.date))
  # Change to date format
  m.date <- as.Date(m.date, format = "%B %d %Y")
  # Extract date from filename
  filename <- gsub("^.*/","",filepath)
  r.date <- substr(filename,1,7)
  district <- substr(filename,9,10)
  # Generate tibble
  df <- tibble(district = district, r_date = r.date, date = m.date, filename = filename, text = bb.text)
}


# Parse BB reports for each District
raw.files <- dir("data/data-raw/bb/", recursive = TRUE) %>% 
  tibble(file = .) %>% 
  mutate(file = paste0("data/data-raw/bb/",file))

reports <- lapply(raw.files$file, processBBhtml ) %>% bind_rows()

# Add the date of the Minutes/SEPs
dt <- tibble(
  doc_id = dates.seps, 
  r_date = as.character(format(dates.bb, "%Y-%m")) )

reports <- reports %>%
  left_join(dt)




# # Tokenize into sentences, then into words, then remove stop words
data("stop_words")
tidy_reports <- reports %>%
  select(doc_id, text) %>%
  # Replace line feeds, newline characters
  mutate(text = sub(pattern = '\\r\\n', replacement = ' ', x = text)) %>%
  unnest_tokens(token = "sentences", input = text, output = sentence) %>%
  group_by(doc_id) %>%
  mutate( sentence_id = row_number()) %>%
  unnest_tokens(token = "words", input = sentence, output = word) %>%
  ungroup() %>%
  anti_join(stop_words)
 
# Remove numbers
tidy_reports <- tidy_reports %>%
  filter(!grepl(pattern = '^[0-9\\.+\\-]+$', x = word) )
 
# Join back into sentences
sent_reports <- tidy_reports %>%
  group_by(doc_id, sentence_id) %>%
  summarise(text = paste0(word, collapse = " ") ) %>%
  ungroup()


# Write to pickle file# Write data for python
py_save_object(sent_reports, filename = 'data/data-gen/sent_beigebook.p')

