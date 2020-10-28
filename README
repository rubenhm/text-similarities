# Similarity between the FOMC minutes and the Summary of Economic Projections 

Rubén Hernández Murillo
October 2020.

## Summary

We strip the text of the FOMC participants' discussion on the outlook and their forecasts and 
calculate the semantic similarity with the FOMC participants' discussion of their forecast in the 
Summary of Economic Projections.
The similarity measure calculated here provides a notion of the correlation of ideas across the two documents.

## Methodology: Text similarity between documents

We calculate embeddings of documents and use cosine similarity to calculate a measure of semantic similarity.
+ An _embedding_ is a representation of a text in a dense vector space (a numeric vector in a high-dimensional space).
+ _Cosine similarity_ is the cosine of the angle formed by a pair of vectors. It is a measure in (0,1) with
larger numbers indicating a smaller angle (more similarity) as the vectors point in a similar direction.

We use the python library [`sentence-transformers`](https://github.com/UKPLab/sentence-transformers) which uses embeddings with BERT with PyTorch. 
Documentation: <https://www.sbert.net/>

## Results

The FOMC Minutes and SEPs exhibit a large degree of similarity in the history of the SEPs (since 2007).
The cosine similarity between pairs of documents at FOMC meetings is at least 0.75.
For comparison, the similarity between the SEPs and the National Summary of the Beige Book 
is much smaller. The similarity between the Minutes and the Beige Book is also smaller between 2007 and late 2016.

Interestingly, since mid-2016, the similarity between the Minutes and the Beige Book appears to be
comparable to the similarity between the Minutes and the SEPs.[^note]

[^note]: The cosine similarity is not a proper distance metric, which may explain why the similarity
between the SEPs and the Beige Book is much smaller.


[[charts/plot_fomc_similarities.png]]


## Replication steps

1. Download data: 
  + [[R/download_fomc_minutes.R]] 
  + [[R/select_minutes_with_sep.R]] 
  + [[R/download_beige_book.R]]
2. Sign up for Google Cloud Computing.
  + Upload PDFs in [[data/minutes_sep_pdf.7z]] to a storage bucket.
  + Activate the Vision AI API.
3. Create a python environment using:
  + [[python/requirements.txt]]
4. Interact with the Vision API using 
  + [[code/gcompfiles.sh]]
5. Process OCR results: 
  + [[python/Process_ocr_results.ipynb]]
6. Prepare data for analysis:
  + [[R/organize_paragraphs.R]]
  + [[R/organize_beige_book.R]]
7. Calculate embeddings and similarity measures:
  + [[python/Calculate_similarities.ipynb]]
8. Generate chart
  + [[R/plot_result.R]]
9. Results:
  + [[data/data-gen/output_json.7z]]
  + [[data/data-gen/big_df.p]]
  + [[data/data-gen/sent_minutes.p]]
  + [[data/data-gen/sent_seps.p]]
  + [[data/data-gen/sent_beigebook.p]]
  + [[data/data-gen/df_simil.p]]
10. Data:
  + [[data/minutes_sep_pdf.7z]]
  + [[data/beige_book_html.7z]]

  
## Attributions

+ We followed this project <https://github.com/kazunori279/pdf2audiobook> in using Google's `Cloud Vision AI`
  to OCR the PDFs of the Minutes/SEPs. This process provides detailed information on the location and size
  of the text in the PDF file used to strip the relevant paragraphs.
