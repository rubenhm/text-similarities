# Create list of Minutes files that contain an SEP section

library(pdftools)
library(tidyr)
library(magrittr)


# Get list of all the minutes from 2007-2020
files <- list.files(path = 'data/data-raw/' ,pattern = "pdf$", full.names = TRUE)
# Read text files
minutes <- lapply(files, pdf_text)

# Select the files that contain "Summary of Economic Projections"
indexes <- lapply(minutes, function(x) {
  sep <- x %>% stringr::str_detect('Summary of Economic') %>% any()
}) %>% unlist

sep_minutes <- files[indexes]

# Copy files to new location
system('mkdir -p data/minutes_sep')

invisible(lapply(sep_minutes, FUN = function(x) {
  file.copy(from = x, to = sub(pattern = 'data-raw', replacement = 'minutes_sep', x = x))
}))

