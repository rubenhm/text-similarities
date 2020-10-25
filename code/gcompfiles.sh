#!/bin/bash

# https://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash

# Read PDF file names from file and process with gcloud
while IFS="" read -r p || [ -n "$p" ]
do
  echo "Now processing file $p"
  #echo "Extracting date ... "
  dt=$(echo $p | awk -F'/' '{print $4}' | sed  -e 's/fomcminutes//g' | sed -e 's/\.pdf//g')
  echo "Date parsed to $dt"
  gcloud ml vision detect-text-pdf $p  gs://fomc_files/out_$dt
done < list.inputs.txt

# Write JSON output file names to file
gsutil ls -r gs://fomc_files/*json  > list.outputs.txt


# Download output files locally
while IFS="" read -r p || [ -n "$p" ]
do
  gsutil cp  $p  data/data-gen/
done < list.outputs.txt
