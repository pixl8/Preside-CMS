---
id: assetmanager
title: Working with the asset manager
---

## Introduction

PresideCMS provides an asset management system that allows users of the system to upload, and add information about, multimedia files. Files can be organised into a folder tree and folders can be configured with permission rules and upload restrictions.

![Screenshot showing asset manager homepage](images/screenshots/assetmanager.jpg)

## Data model

The metadata and folder structure of your assets are all stored in your application's database using [[dataobjects]]. The objects and their relationships are modelled below:

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

Here, `assetId` is the ID of the asset whose link we want to build, `derivative` is the name of a configured asset derivative (see below), and `versionId` is the ID of a specific version of an asset.

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

settings.assetmanager.location.public    = ExpandPath( "/uploads/public" );
settings.assetmanager.location.private   = ExpandPath( "/uploads/private" );
settings.assetmanager.location.trash     = ExpandPath( "/uploads/.trash" );
settings.assetmanager.location.publicUrl = "//static.mysite.com/";
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

For more information on image transformations, see [[transformations]].

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

The asset manager allows you to define and use multiple storage locations. For example, you might have a shared drive on your server for private documents, and an Amazon Cloudfront CDN for your public images. Once your locations have been configured, you are then able to map folders in the asset manager to different locations.

![Screenshot of storage location selection](images/screenshots/storagelocationselection.jpg)

### Storage providers

The system works with a concept of storage *providers*. The core system implements a single 'file storage' provider for you to use. Custom storage providers can be created by creating a CFC that adheres to the core [[api-storageprovider]] interface and by supplying configuration forms that can be used by administrators of the system to configure an instance of your provider.

Defining a custom provider is as follows:

#### 1. Create a CFC file

Create a CFC that implements the [[api-storageprovider]] interface, i.e.

```luceescript
compoment implements="preside.system.services.fileStorage.StorageProvider" {
    // ...
}
```

You will need to thoroughly read the [[api-storageprovider|interface documentation]] and be sure to implement each method appropriately. In addition, you will almost certainly want to implement an `init()` constructor method to take any configuration that your provider requires (i.e. security credentials, etc.).

#### 2. Declare the provider in config

You must declare the storage provider in your application's `Config.cfc` file, this is simply mapping an ID to a CFC path:

```luceescript
settings.storageProviders.myProvider = {
    class = "app.services.filestorage.MyProvider"
};
```

Here we declare a provider named "myProvider", whose CFC file lives at "app.services.filestorage.MyProvider".

#### 3. Provide a configuration form for the provider

You must provide a configuration form for the provider. This will be used by administrators when managing a specific storage location that uses your provider. By convention, this is expected to live at `/forms/storage-providers/{providerid}.xml`. In our example above, the form would live at `/forms/storage-providers/myProvider.xml`. The form fields defined here must map to arguments passed to your custom provider CFC's init() method.

>>> The form definition will be merged with either [[form-assetstoragelocationaddform]] or [[form-assetstoragelocationeditform]] depending on whether a storage location is being added or edited.

For example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="storage-providers.filesystem:">
    <tab id="default">
        <fieldset id="filesystem">
            <field sortorder="10" name="rootDirectory"  control="textinput" required="true" />
            <field sortorder="20" name="trashDirectory" control="textinput" required="true" />
        </fieldset>
    </tab>
</form>
```

#### 4. Provider i18n resources to describe the provider and its configuration

By convention, you must create a `.properties` file at `/i18n/storage-providers/{providerid}.properties`. For example: `/i18n/storage-providers/myProvider.properties`. It should contain `title`, `description` and `iconclass` keys to describe the provider itself plus any keys for describing form fields, etc. For example:

```properties
title=File system
description=The file system storage provider stores files in the local file system. Suitable for sites without any clustering requirements.
iconclass=fa-folder

field.rootDirectory.title=Root path
field.rootDirectory.placeholder=e.g. /uploads/assets
field.trashDirectory.title=Trash path
field.trashDirectory.placeholder=e.g. /uploads/.trash

error.creating.directory=The directory, {1}, does not exist and could not be created. Error: {2}. Please note, you must supply full directory paths
```

### Default location

The asset manager system works out of the box without the need to configure any storage locations through the UI. For this, it uses a default configured storage provider through Wirebox. The core configuration of this provider is located at `/system/config/Wirebox.cfc` and looks like this:

```luceescript
map( "assetStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
    .initArg( name="rootDirectory"   , value=settings.assetmanager.storage.public    )
    .initArg( name="privateDirectory", value=settings.assetmanager.storage.private   )
    .initArg( name="trashDirectory"  , value=settings.assetmanager.storage.trash     )
    .initArg( name="rootUrl"         , value=settings.assetmanager.storage.publicUrl );
```

#### Overriding the default storage location

This can be done in two ways. Firstly, you could change `settings.assetmanager.storage` settings to point to different physical paths (or full mapped ftp/s3/etc Lucee paths). This might be a mounted shared drive for example, or just a directory outside of the webroot (recommended). This can also be achieved with environment variables, for example:

```
# env vars:
PRESIDE_assetmanager.storage.public=sftp://user:pass@server.com/public
PRESIDE_assetmanager.storage.private=sftp://user:pass@server.com/private
PRESIDE_assetmanager.storage.trash=sftp://user:pass@server.com/.trash
PRESIDE_assetmanager.storage.publicUrl=//static.mysite.com
```


The second option would be to manually configure an entirely different Storage provider that maps to "assetStorageProvider". This would be done in your site's `/config/Wirebox.cfc` file, for example:

```luceescript
component extends="preside.system.config.WireBox" {

    public void function configure() {
        super.configure();

        var settings = getColdbox().getSettingStructure();

        if ( IsBoolean( settings.myProvider.enabled ?: "" ) && settings.myProvider.enabled ) {

            map( "assetStorageProvider" ).asSingleton().to( "app.services.fileStorage.MyProvider" ).noAutoWire()
                .initArg( name="apiKey"    , value=settings.myProvider.apiKey                 )
                .initArg( name="uploadPath", value=settings.myProvider.uploadPath & "/assets" )
                .initArg( name="trashPath" , value=settings.myProvider.uploadPath & "/.trash" )
                .initArg( name="rootUrl"   , value=settings.myProvider.rootUrl                );

        }
    }

}
```

>>> You should consider that your application may run in multiple environments and need to be able to configure these settings per environment. Using the technique above that uses ColdBox settings to configure your provider could help with that as these are able to be set per environment (see the [ColdBox documentation](http://wiki.coldbox.org/wiki/ConfigurationCFC.cfm#environments) for further details). If you're super smart and have beautifully setup environments, you could use environment variables to setup the settings, making your default storage provider configuration truly portable.