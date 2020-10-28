library(httr)
library(xml2)
library(rvest)
library(magrittr)
library(tibble)
library(dplyr)

# Function to download file from the web
FileDown <- function(url, slug, file, folder){
  #browser()
  url_ = url
  slug_ = slug
  file_ = file
  folder_ = folder
  resp <- httr::GET(url =  url_,
                    path = file.path(slug_, file_),
                    config = httr::config(ssl_verifypeer = FALSE),
                    httr::use_proxy(Sys.getenv('https_proxy')), httr::verbose())
  
  if (resp$status_code == 200) {
    # Write to file
    writeBin(resp$content, con = file.path(folder_,paste0(file_,'.htm')) )
    print("Command succeeded, file written successfully.")
  } else{
    print('Error when downloading file. ')
    paste0('Status code: ', resp$status_code)
  }
  
}


# Function to manipulate the path to the download link
# and call the main download function
# Files can be of any extension
# PDF or html
SlugDown <- function(link, url) {
  #browser()
  stubs <- link %>% strsplit("/") %>% .[[1]]
  n = NROW(stubs)
  file = stubs[n]
  slug = stubs[(n-2):(n-1)] %>% paste0(collapse = "/")
  # Download file
  FileDown(url, slug, file, 'data/data-raw/bb/')
  
}

# Download beige books
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

url  <- 'https://www.minneapolisfed.org/'
slug <- 'beige-book-reports/'

files <- paste0(lubridate::year(dates.bb),'/',format(dates.bb, "%Y-%m"),'-su')
filepaths <- paste0(url,slug, files)

# Download files
invisible(lapply(filepaths, SlugDown, url))

# Download 2016-09 file which has wrong name at the source
link <- 'https://www.minneapolisfed.org/beige-book-reports/2016/2016-06-national-summary'
SlugDown(link, url)


