---
id: "imagemanipulationservice-pdfpreview"
title: "pdfPreview()"
---


## Overview




```luceescript
public binary function pdfPreview(
      required binary asset      
    ,          string scale      
    ,          string resolution 
    ,          string format     
    ,          string pages      
    ,          string transparent
)
```

Generates an image from the first page of the provided PDF binary

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>asset</td><td>binary</td><td>Yes</td><td>Binary of the PDF</td></tr><tr><td>scale</td><td>string</td><td>No</td><td>Size of the thumbnail relative to the source page. The value represents a percentage from 1 through 100.</td></tr><tr><td>resolution</td><td>string</td><td>No</td><td>Image quality used to generate thumbnail images</td></tr><tr><td>format</td><td>string</td><td>No</td><td>File type of thumbnail image output</td></tr><tr><td>pages</td><td>string</td><td>No</td><td>Page or pages in the source PDF document on which to perform the action. You can specify multiple pages and page ranges as follows: "1,6-9,56-89,100, 110-120".</td></tr><tr><td>transparent</td><td>string</td><td>No</td><td>(format="png" only) Specifies whether the image background is transparent or opaque</td></tr></tbody></table></div>