---
id: "api-documentmetadataservice"
title: "Document metadata service"
---


## Overview




The document metadata service provides methods for extracting metadata from documents such as PDFs and word documents.
Its purpose in the context of PresideCMS is for metadata and content extraction from uploaded documents.


In its current form, only the extraction of image EXIF metadata is supported. Extensions such as the Tika extension
can override/extend this service to provide full functionality.<div class="table-responsive"><table class="table table-condensed"><tr><th>Full path</th><td>preside.system.services.assetManager.DocumentMetadataService</td></tr><tr><th>Wirebox ref</th><td>DocumentMetadataService</td></tr><tr><th>Singleton</th><td>Yes</td></tr></table></div>

## Public API Methods

* [[documentmetadataservice-getmetadata]]
* [[documentmetadataservice-gettext]]