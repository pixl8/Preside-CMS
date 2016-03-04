---
id: "imagemanipulationservice-shrinktofit"
title: "shrinkToFit()"
---


## Overview




```luceescript
public binary function shrinkToFit(
      required binary  asset  
    , required numeric width  
    , required numeric height 
    ,          string  quality = "highPerformance"
)
```

Shrinks an image to fit within a given width and height, without changing
the images aspect ratio.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>asset</td><td>binary</td><td>Yes</td><td>Binary of the image to transorm</td></tr><tr><td>width</td><td>numeric</td><td>Yes</td><td>Maximum width for the image, in pixels</td></tr><tr><td>height</td><td>numeric</td><td>Yes</td><td>Maximum height for the image, in pixels</td></tr><tr><td>quality</td><td>string</td><td>No (default="highPerformance")</td><td>Resize algorithm quality. Options are: highestQuality, highQuality, mediumQuality, highestPerformance, highPerformance and mediumPerformance</td></tr></tbody></table></div>