#!/bin/bash

# https://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash

# Write list of PDF files
gsutil ls -r gs://fomc_files/pdfs > list.inputs.txt

# Read PDF file names from file and process with gcloud
while IFS="" read -r p || [ -n "$p" ]
do
  echo "Now processing file $p"
  #echo "Extracting date from file ... "
  dt=$(echo $p | awk -F'/' '{print $5}' | sed  -e 's/fomcminutes//g' | sed -e 's/\.pdf//g')
  echo "Date parsed to $dt"
  gcloud ml vision detect-text-pdf $p  gs://fomc_files/jsons/out_$dt
 done < list.inputs.txt

# Write list ofJSON output file names to file
# Wait a few minutes after OCR or it will retrieve a partial list
# gsutil ls -r gs://fomc_files/jsons/*json  > list.outputs.txt


# Download OCR output files locally
while IFS="" read -r p || [ -n "$p" ]
do
  gsutil cp  $p  ../data/data-gen/json/
done < list.outputs.txt
