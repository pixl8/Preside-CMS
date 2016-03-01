---
id: "imagemanipulationservice-resize"
title: "resize()"
---


## Overview




```luceescript
public binary function resize(
      required binary  asset              
    ,          numeric width               = 0
    ,          numeric height              = 0
    ,          string  quality             = "highPerformance"
    ,          boolean maintainAspectRatio = false
)
```

Resizes an image

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>asset</td><td>binary</td><td>Yes</td><td>Binary of the image to resize</td></tr><tr><td>width</td><td>numeric</td><td>No (default=0)</td><td>New width, in pixels</td></tr><tr><td>height</td><td>numeric</td><td>No (default=0)</td><td>New height, in pixels</td></tr><tr><td>quality</td><td>string</td><td>No (default="highPerformance")</td><td>Resize algorithm quality. Options are: highestQuality, highQuality, mediumQuality, highestPerformance, highPerformance and mediumPerformance</td></tr><tr><td>maintainAspectRatio</td><td>boolean</td><td>No (default=false)</td><td>Whether or not maintain the aspect ratio of the image (if true, an autocrop may be applied if the aspect ratio of the resize differs from the source image)</td></tr></tbody></table></div>