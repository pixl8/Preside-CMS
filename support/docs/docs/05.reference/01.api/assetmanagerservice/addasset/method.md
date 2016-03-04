---
id: "assetmanagerservice-addasset"
title: "addAsset()"
---


## Overview




```luceescript
public string function addAsset(
      required binary fileBinary
    , required string fileName  
    , required string folder    
    ,          struct assetData 
)
```

Adds an asset into the Asset manager. The asset binary will be uploaded to the appropriate storage
location for the given folder.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>fileBinary</td><td>binary</td><td>Yes</td><td>Binary data of the file</td></tr><tr><td>fileName</td><td>string</td><td>Yes</td><td>Uploaded filename (asset type information will be retrieved from here)</td></tr><tr><td>folder</td><td>string</td><td>Yes</td><td>Either folder ID or name of a configured system folder</td></tr><tr><td>assetData</td><td>struct</td><td>No</td><td>Structure of additional data that can be saved against the [[presideobject-asset]] record</td></tr></tbody></table></div>