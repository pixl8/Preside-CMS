---
id: assetmanager
title: Working with the Asset Manager
---

## Introduction

PresideCMS provides an asset management system that allows users of the system to upload, and add information about, multimedia files. Files can be organised into a folder tree and folders can be configured with permission rules and upload restrictions.

![Screenshot showing asset manager homepage](images/screenshots/assetmanager.jpg)

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

When making additions and modifications, you may also want to change the appearance of various forms for uploading and editing assets, folders, etc. Reference documentation on those forms can be found below:

* [[form-assetaddform]]
* [[form-assetaddthroughpickerform]]
* [[form-asseteditform]]
* [[form-assetnewversionform]]
* [[form-assetfolderaddform]]
* [[form-assetfoldereditform]]
* [[form-assetstoragelocationaddform]]
* [[form-assetstoragelocationeditform]]

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

### Getting a raw link to an asset

This can be done with:

```luceescript
event.buildLink( 
      assetId    = idOfAsset
    , derivative = "optionalDerivative"
    , versionId  = optionalVersionId
);
```

Here, `assetId` is the ID of the asset who's link we want to build, `derivative` is the name of a configured asset derivative (see below), and `versionId` is the ID of a specific version of an asset.

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

## Configuration

Overall configuration of asset manager behaviour is made in the `settings.assetmanager` struct in your application's `Config.cfc` file. 

Valid keys are:

* **maxFileSize** This controls the default maximum file upload size in MB. The default value is 5MB.
* **types** Configures the allowed file types to be uploaded to the asset manager (see File types, below)
* **derivatives** Configures named derivates (see Derivatives, below)
* **folders** Configures system folders that will always be available in your asset manager (see System folders, below)

An example configuration section for the asset manager (`Config.cfc`):

```luceescript
settings.assetmanager.maxFileSize = 10;

settings.assetmanager.types.video.ogv = { serveAsAttachment=true, mimeType="video/ogg" };

settings.assetmanager.derivatives.leadimage = {
      permissions     = "inherit"
    , inEditor        = true
    , transformations = [ { method="resize", args={ width=800, height=400 } } ]
};

settings.assetmanager.folders.profileImages = {
      label  = "Profile images"
    , hidden = false
    , children = {
            members    = { label="Members"    , hidden=false }
          , nonMembers = { label="Non-Members", hidden=false }
      }
};
```

## File types

Configured file types allows you to specify the filetypes that are uploadable to the asset manager by default. File types are grouped into "super types", for example "image", and the configuration allows you to specify download behaviour and mimetype of each type. The structure of configuration is as follows:

```luceescript
settings.assetmanager.types.supertype.fileextension = {
      serveAsAttachment = trueOrFalse
    , mimetype          = stringMimeType
};
```

Here is an excerpt from the core configuration to give a fuller picture:

```luceescript
settings.assetmanager.types.image = {
      jpg  = { serveAsAttachment=false, mimeType="image/jpeg" }
    , jpeg = { serveAsAttachment=false, mimeType="image/jpeg" }
    , gif  = { serveAsAttachment=false, mimeType="image/gif"  }
    , png  = { serveAsAttachment=false, mimeType="image/png"  }
};

settings.assetmanager.types.document = {
      pdf  = { serveAsAttachment=true, mimeType="application/pdf"    }
    , csv  = { serveAsAttachment=true, mimeType="application/csv"    }
    , doc  = { serveAsAttachment=true, mimeType="application/msword" }
    , dot  = { serveAsAttachment=true, mimeType="application/msword" }

```

### Labelling

In addition to the file type configuration above, you are also able to supply labels for the file types and super types. These are displayed when choosing file type restrictions for uploading to your asset manager folders.

Labels are added in `/i18n/filetypes.properties` and take the form: `{typeOrSuperType}.picker.label=Human readable label`. For example:

```properties
image.picker.label=Image: any type
gif.picker.label=Image: gif
png.picker.label=Image: png
jpg.picker.label=Image: jpg
jpeg.picker.label=Image: jpeg
```

## Derivatives

Derivatives are transformed versions of an asset. This could be a particular crop of a picture, a preview image of a PDF, etc. They are configured in your application's `Config.cfc`, for example:

```luceescript
settings.assetmanager.derivatives.leadImage = {
      permissions     = "inherit"
    , inEditor        = true
    , transformations = [ { method="shrinkToFit", args={ width=800, height=400 } } ]
};
```

Once defined, a derivative can then be used when building a link to an asset and in the core default contexts of `renderAsset()`. For example:

```luceescript
assetUrl = event.buildLink( assetId=myImageId, derivative="leadImage" );
// ...
renderedAsset = renderAsset( assetId=myImageId, args={ derivative="leadImage" } ); 

```

### Configuration options

#### Permissions

The `permissions` configuration option relates to access permissions defined on the core asset and how they should apply to the derivative. Valid values are "inherit" and "public". The default value is "inherit" and this means that the derivative will share the same access permissions as the asset that it is based on. Derivatives with `permissions` set to "public" will have no permissions checking at all, regardless of the permissions set on the base asset.

#### inEditor

A boolean value indicating whether or not the derivative should be selectable by system editors when embedding images in content. Derivatives with this option set to `true` appear in the "Preset" dropdown in the Image picker:

![Screenshot showing 'Preset' picker](images/screenshots/imagepresetpicker.jpg)

The default value is `false`. If set to `true`, you should also supply a human readable label for the derivative in a `i18n/derivatives.properties` file. This can be done using `{derivativeid}.title=Some title`:

```
leadimage.title=Lead image (800x400)
thumbnail.title=Thumbnail (100x100)
```

>>> This feature was introduced in v10.4.0

#### Transformations

An array of configured transformations that the original asset binary will be passed through in order to create a new version. 

A transformation is defined as a CFML structure, with the following keys:

* **method (required)**: Method that matches a method implemented in the [[api-assettransformer]] service object
* **args (optional)**: Structure of arguments passed to the transformation *method*.
* **inputfiletype (optional)**: Only apply this transformation to images of this type. e.g. "pdf".
* **outputfiletype (optional)**: Expected output filetype of the transformation

An example using all of the above arguments, is the admin thumbnail derivative that works for both PDFs and images:

```luceescript
settings.assetmanager.derivatives.adminthumbnail = {
      permissions     = "inherit"
    , inEditor        = false
    , transformations = [
          { method="pdfPreview" , args={ page=1 }, inputfiletype="pdf", outputfiletype="jpg" }
        , { method="shrinkToFit", args={ width=200, height=200 } }
      ]
};
```

## System folders

System folders are pre-defined asset manager folders that will always exist in your asset manager folder structure. They cannot be deleted through the admin UI and can optionally be completely hidden from the UI. They are configured in `Config.cfc`, for example:

```luceescript
settings.assetmanager.folders.profileImages = {
      label  = "Profile images"
    , hidden = false
    , children = {
            memberProfileImages    = { label="Members"    , hidden=false }
          , nonMemberProfileImages = { label="Non-Members", hidden=false }
      }
};
```

The purpose of system folders is to be able to programatically upload assets directly to a named folder that you know will exist. This can be achieved with the [[assetmanagerservice-addasset]] method:

```luceescript
assetManagerService.addAsset(
      fileBinary = uploadedFileBinary
    , fileName   = uploadedFileName
    , folder     = "memberProfileImages"
    , assetData  = { description="Uploaded profile image for #loggedInMemberName#", title=loggedInMemberName }
);
```
>>>> Asset titles must be unique within any given folder. If you are programatically uploading assets to the asset manager, you need to code for this uniqueness to avoid duplicate key errors.

## Storage providers and locations

TODO