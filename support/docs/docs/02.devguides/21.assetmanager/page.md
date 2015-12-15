---
id: assetmanager
title: Working with the Asset Manager
---

## Introduction

PresideCMS provides an asset management system that allows users of the system to upload, and add information about, multimedia files. Files can be organised into a folder tree and folders can be configured with permission rules and upload restrictions.

![Screenshot showing asset manager homepage](images/screenshots/assetmanager.jpg) 

This system can be tailored to your application's needs in the same ways that the rest of PresideCMS can be extended and customized.

## Data model

The metadata and folder structure of your assets are all stored in your application's database using [[presidedataobjects]]. The objects and their relationships are modelled below:

![Asset manager database model](images/diagrams/asset_manager_erd.png)

These objects can all be modified to take on requirements of your application. See the links below for reference documentation on each object:

* [[presideobject-asset_storage_location]]
* [[presideobject-asset_folder]]
* [[presideobject-asset]]
* [[presideobject-asset_version]]
* [[presideobject-asset_derivative]]
* [[presideobject-asset_meta]]

## Rendering assets

## Derivatives

## Configuration

## Integrating assets in forms and data model



This page will serve as your guide on configuring image derivatives on your application. To start with, please open the file /website/config/Config.cfc then copy the code below:


```luceescript
private struct function _getConfiguredAssetDerivatives() {
	var derivatives  = super._getConfiguredAssetDerivatives();

	derivatives.homebanner = {
		  permissions = "inherit"
		, inEditor    = true
		, transformations = [
			  { method="Resize", args={ width=1900, height=800, maintainaspectratio=true } }
		  ]
	};


	return derivatives;
}
```


### Derivatives Options

You can pass the following arguments to the derivatives:

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>


            <tr>
                <td>`permissions`</td>
                <td>Please set the permission to inherit if you want the derivatives be used anywhere in the application, this is a required paramater. Default:'inherit'</td>
            </tr>

            <tr>
                <td>`inEditor`</td>
                <td>Please set the inEditor to true if you want the derivatives setting to become available on the editor. Default:'false'</td>
            </tr>

        </tbody>
    </table>
</div>

### i18n Settings

You can chanage the name/label of derivatives via i18n/derivatives.properties using this format: derivativeName.title = Desired Name


```luceescript

adminThumbnail.title=Admin thumbnail
icon.title=Icon thumbnail

```

>>> This feature was first introduced in PresideCMS v10.3.7. The details below do not apply for older versions of the software.