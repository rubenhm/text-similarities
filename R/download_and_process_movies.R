# Download movie/book reviews from the nytimes API
library(jsonlite)
library(dplyr)
library(tibble)
library(tidytext)
library(reticulate)

# Select python environment
#use_condaenv('py37_fomc')
use_condaenv('gcloud')


# Load New York Times API key
nyt_key = Sys.getenv('NYT_KEY') 

# Dates of Minutes with SEPS
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
                '20200916') %>% as.Date(format = '%Y%m%d')

# Test API
# https://www.storybench.org/working-with-the-new-york-times-api-in-r/

download_movies <- function(date_sep) {
  # Download titles and summaries of movies that opened on the SEP date
  link <- paste0("https://api.nytimes.com/svc/movies/v2/reviews/search.json?opening-date=",
                 date_sep,"&api-key=",nyt_key)
  
  # Call the API
  x <- fromJSON(link)
  
  # Define the dataframe with sentences
  dt <- x$results %>% select(display_title, summary_short)
  dt$doc_id <- format(date_sep, "%Y%m%d")
  
  dt <- dt %>% 
    mutate(movie = paste0(display_title, '. ', summary_short)) %>%
    select(doc_id, movie)
  
  return(dt)
}


# Download data for all SEP dates
movies <- lapply(dates.seps, function(x) {
      #browser()
      # https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
      response = tryCatch({
                    message(paste0("Now attempting API call for date= ", x))
                    dt = download_movies(x)
                 }, 
                    warning = function(w) {
                      message(paste0('Warning downloading date=', x))
                      message('Here is the original warning:')
                      message(w)
                      return(NULL)
                 },
                     error = function(e) {
                      message(paste0('Error downloading date=', x))
                      message('Here is the original error:')
                      message(e)
                      return(NULL) 
                 },
                    finally = {
                      message('Processed API call for date=', x, '...')
                    }
   )
      # Wait 6 seconds before next API call
      # to avoid the 10 requests per minute limit
      Sys.sleep(6)
      return(response)
  }) 

# Check if we hit the requests-per-minute limit 
assertthat::assert_that(!any(unlist(lapply(movies, is.null))))


# Prepare data for analysis -----------------------------------------------

movies <- movies %>% bind_rows()

# # Tokenize into sentences, then into words, then remove stop words
data("stop_words")
tidy_movies <- movies %>% 
  select(doc_id, movie) %>%
  # Replace line feeds, newline characters
  mutate(movie = sub(pattern = '\\r\\n', replacement = ' ', x = movie)) %>%
  unnest_tokens(token = "sentences", input = movie, output = sentence) %>%
  group_by(doc_id) %>%
  mutate( sentence_id = row_number()) %>%
  unnest_tokens(token = "words", input = sentence, output = word) %>%
  ungroup() %>%
  anti_join(stop_words)

# Remove numbers
tidy_movies <- tidy_movies %>%
  filter(!grepl(pattern = '^[0-9\\.+\\-]+$', x = word) )

# Join back into sentences
sent_movies <- tidy_movies %>%
  group_by(doc_id, sentence_id) %>%
  summarise(text = paste0(word, collapse = " ") ) %>%
  ungroup()


# Write to pickle file for python
py_save_object(sent_movies, filename = 'data/data-gen/sent_movies.p')

