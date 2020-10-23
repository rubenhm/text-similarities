# Download FOMC documents

library(httr)
library(xml2)
library(rvest)
library(magrittr)

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
    writeBin(resp$content, con = file.path(folder_,file_) )
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
  slug = stubs[-n] %>% paste0(collapse = "/")
  # Download file
  FileDown(url, slug, file, 'data/data-raw')
  
}


# Download Files of the FOMC Minutes from 1970 through 2007
# Collect links to the Minutes 
url = 'https://www.federalreserve.gov/'
slug = 'monetarypolicy/'
files = paste0(paste('fomchistorical',c(2007:2014),sep = ''), '.htm')
filepaths = paste0(url,slug, files)

# Use lapply functions instead of for loops to process filepaths
invisible(lapply(filepaths, function(flink) {
  #browser()
  siteYear <- xml2::read_html(flink)
  minutesPdfLinks <- siteYear %>%
    rvest::html_nodes('.col-md-6:nth-child(2) p:nth-child(2) a') %>%
    rvest::html_attr('href')
  # Now we select only those links that have the word Minutes
  containsMinutes <- siteYear %>%
    rvest::html_nodes('.col-md-6:nth-child(2) p:nth-child(2) a') %>%
    rvest::html_text() %>% stringr::str_detect('(m|M)inutes')
  minutesPdfLinks <- minutesPdfLinks[containsMinutes]
  url = XML::parseURI(flink)$server %>% paste0('https://', .)
  # Download files in list of links
  invisible(lapply(minutesPdfLinks, SlugDown, url))
})
)

# Download Files of the FOMC Minutes from 2007 through 2014 ------------

# Selectors for the pdf links
listCssA <- list()
listCssA["2007"] = "p:nth-child(3) a:nth-child(3)"
listCssA["2008"] = ".col-md-6 p:nth-child(3) a:nth-child(3)"
listCssA["2009"] = ".col-md-6 p:nth-child(3) a:nth-child(3)"
listCssA["2010"] = ".col-md-6 p:nth-child(3) a:nth-child(3)"
listCssA["2011"] = "p:nth-child(2) a:nth-child(3)"
listCssA["2012"] = "p:nth-child(2) a:nth-child(3)"
listCssA["2013"] = "p:nth-child(2) a:nth-child(3)"
listCssA["2014"] = "p:nth-child(2) a:nth-child(3)"

# Use lapply functions instead of for loops to process filepaths
url = 'https://www.federalreserve.gov/'
slug = 'monetarypolicy/'
files = paste0(paste('fomchistorical',c(2007:2014),sep = ''), '.htm')
filepaths = paste0(url,slug, files)
invisible(lapply(filepaths, function(flink) {
  #browser()
  # Extract year from link
  year <- stringr::str_extract(flink, '[0-9]{4}')
  # Read link
  siteYear <- xml2::read_html(flink)
  minutesPdfLinks <- siteYear %>%
      rvest::html_nodes(listCssA[[year]])  %>%
    rvest::html_attr('href')
  url = XML::parseURI(flink)$server %>% paste0('https://', .)
  # Download files in list of links
  invisible(lapply(minutesPdfLinks, SlugDown, url))
})
)

# Download Files of the FOMC Minutes from 2015 through 2020 ------------


# Selectors for current meetings
current_selector <- '.fomc-meeting__minutes a:nth-child(3)'
current_link <- 'https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm'
siteYear <- xml2::read_html(current_link)
minutesPdfLinks <- siteYear %>%
  rvest::html_nodes(current_selector)  %>%
  rvest::html_attr('href')
url = XML::parseURI(current_link)$server %>% paste0('https://', .)
# Download files in list of links
invisible(lapply(minutesPdfLinks, SlugDown, url))
