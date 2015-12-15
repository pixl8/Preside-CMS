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

## Integrating assets in your application

### Link to assets in your data model

To reference an asset in your own data model and page types, you should create a relationship property with the `asset` object. For instance, an 'Author' object that has a profile image property:

```luceescript
component {
    // ...
    property name="profile_image" relationship="many-to-one" relatedTo="asset" allowedTypes="image";
    // ...
}
```

Or a "Consultation" object that has many associated documents:

```luceescript
component {
    // ...
    property name="documents" relationship="many-to-many" relatedTo="asset";
    // ...
}
```

### Allow picking of assets in your forms

The [[formcontrol-assetpicker|Asset picker]] form control provides a GUI for selecting and uploading one or more assets in a form. 

![Screenshot showing asset picker](images/screenshots/assetpicker.jpg) 

The form control will *automatically* be used for object properties that have a relationship with the `asset` object. However, you can specify the control directly in a form (for a widget, for example) with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.mywidget:">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            <field name="images" control="assetpicker" allowtypes="png,jpg" maxFileSize="512" multiple="true" />
        </fieldset>
    </tab>
</form>
```

### Render assets in your views

The `renderAsset()` helper function will render the asset referenced by the passed asset ID. It is a proxy to the [[assetrendererservice-renderasset]] method of the [[api-assetrendererservice]]. Usage looks like this:

```lucee
<cfoutput>
    <!-- ... -->
    #renderAsset( 
          assetId = myauthor.profile_image
        , context = "preview"
        , args    = { derivative="authorprofile" }
    )#

    <!-- ... -->
</cfoutput>
```

### Create custom contexts for asset rendering

The [[assetrendererservice-renderasset]] method will choose a viewlet with which to render your asset based on:

1. The type of asset, or "super-type" of the asset
2. The supplied context

The type of the asset is simply its extension. A "super type" is the file type group, i.e. "image", "document", etc. Types and super types are configured in your application's `Config.cfc` file (see below). 

The asset manager will try to use the most specific viewlet it can find to render your asset. For example, if the supplied asset was a *jpg image* and the supplied context was *"thumbnail"*, the system would go through the following viewlet names and use the first available one:

```
renderers.asset.jpg.thumbnail
renderers.asset.image.thumbnail
renderers.asset.jpg.default
renderers.asset.image.default
renderers.asset.default
```

A "banner" context viewlet for images could therefor be implemented as a view at `/application/views/renderers/asset/image/banner.cfm` and look like:

```lucee
<cfscript>
    id       = args.id    ?: "";
    label    = args.label ?: "";
    imageUrl = event.buildLink( assetId=id, derivative="bannerimage" );
</cfscript>
<cfoutput>
    <div class="banner-image">
        <img src="#imageUrl#" alt="#label#" title="#label#" />
    </div>
</cfoutput>
```





## Derivatives

## Configuration


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