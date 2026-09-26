# Asset Manager

## Configuration

```cfml
// Config.cfc
public void function configure() {
    super.configure();

    // File size limits
    settings.assetmanager.maxFileSize = 10;  // MB, default

    // Add custom file types
    settings.assetmanager.types.document.pdf = {
          serveAsAttachment = true
        , mimeType          = "application/pdf"
    };

    settings.assetmanager.types.video.ogv = {
          serveAsAttachment = false
        , mimeType          = "video/ogg"
    };

    // Image derivatives (auto-generated versions)
    settings.assetmanager.derivatives.leadimage = {
          permissions  = "inherit"       // "inherit" or "public"
        , inEditor     = true            // Selectable in admin editor
        , autoQueue    = [ "image" ]     // Auto-generate for these types
        , transformations = [
              { method="resize", args={ width=1200, height=600, maintainAspectRatio=true } }
          ]
    };

    settings.assetmanager.derivatives.thumbnail = {
          permissions   = "public"
        , inEditor      = false
        , autoQueue     = [ "image" ]
        , transformations = [
              { method="shrinkToFit", args={ width=200, height=200 } }
          ]
    };

    settings.assetmanager.derivatives.pdfpreview = {
          permissions   = "public"
        , autoQueue     = [ "document" ]
        , transformations = [
              { method="pdfPreview", args={ page=1 }, inputfiletype="pdf", outputfiletype="jpg" }
          ]
    };

    // Pre-created folder structure
    settings.assetmanager.folders.profileImages = {
          label    = "Profile Images"
        , hidden   = false
        , children = {
              members    = { label="Members",     hidden=false }
            , nonMembers = { label="Non-Members", hidden=false }
          }
    };

    // Storage paths (typically set in environment config)
    settings.assetmanager.location.public  = ExpandPath( "/uploads/public" );
    settings.assetmanager.location.private = ExpandPath( "/uploads/private" );
    settings.assetmanager.location.trash   = ExpandPath( "/uploads/.trash" );
    settings.assetmanager.location.publicUrl = "//cdn.mysite.com/";

    // Processing queue (v10.11.0+)
    settings.features.assetQueue.enabled          = true;
    settings.features.assetQueueHeartBeat.enabled = true;
    settings.assetmanager.queue.concurrency        = 4;
    settings.assetmanager.queue.batchSize          = 100;
}
```

---

## Image Transformations

Built-in transformation methods:

```cfml
// shrinkToFit — scale to fit within box, maintain aspect ratio
{ method="shrinkToFit", args={ width=200, height=200, quality="highPerformance" } }
// quality options: "highPerformance", "highQuality", "nearest", "bilinear", "bicubic"

// resize — crop/resize to exact dimensions
{ method="resize", args={ width=800, height=400, maintainAspectRatio=true } }

// pdfPreview — render a PDF page as an image
{ method="pdfPreview", args={ page=1 }, inputfiletype="pdf", outputfiletype="jpg" }
```

### Custom Transformation

```cfml
// Config.cfc
settings.assetmanager.derivatives.watermarked = {
      transformations = [
          { method="resize",     args={ width=1200 } }
        , { method="watermark",  args={ opacity=0.3 } }
      ]
};

// /handlers/AssetTransformers.cfc
component {
    property name="imageManipulationService" inject="imageManipulationService";

    private binary function watermark( event, rc, prc, args={} ) {
        // args.asset = binary of the image
        // args.opacity = from derivative config
        var img = ImageNew( args.asset );
        // ... apply watermark logic
        var result = ImageGetBlob( img, "jpg" );
        return result;
    }
}
```

---

## Using Assets in Preside Objects

```cfml
// Single image
property name="profile_image" relationship="many-to-one" relatedTo="asset"
    allowedTypes="image";

// Multiple files
property name="attachments" relationship="many-to-many" relatedTo="asset"
    allowedTypes="document,pdf";

// In admin form (auto-resolved from property):
// <field binding="my_object.profile_image" />

// Explicit form control:
// <field name="hero_image" control="assetPicker" allowedTypes="image"
//        multiple="false" maxFileSize="5" />
```

---

## Building Asset URLs

```cfml
// Basic asset URL
event.buildLink( assetId=myRecord.profile_image )

// With derivative
event.buildLink( assetId=myRecord.profile_image, derivative="thumbnail" )

// Specific version
event.buildLink( assetId=myRecord.profile_image, versionId=versionId )

// From a service (PresideSuperClass):
var url = $buildLink( assetId=assetId, derivative="thumbnail" )
```

---

## Rendering Assets

```cfm
<!-- In views: -->
#renderAsset(
      assetId    = myRecord.profile_image
    , context    = "mainContent"          // Context for derivative selection
    , args       = { derivative="leadimage", class="hero-image", alt="Page hero" }
)#
```

### Configuring renderAsset Contexts

```cfml
// Config.cfc
settings.assetmanager.assetContexts.mainContent = {
      derivatives = [ "leadimage", "thumbnail" ]
    , defaultDerivative = "leadimage"
};
```

---

## Custom Storage Providers

```cfml
// /services/fileStorage/S3StorageProvider.cfc
component implements="preside.system.services.fileStorage.StorageProvider" {

    public any function init(
          required string accessKey
        , required string secretKey
        , required string bucketName
        , required string region
    ) {
        variables.s3 = createS3Client( argumentCollection=arguments );
        return this;
    }

    public binary function getObject( required string path ) {
        return variables.s3.getObject( bucket=variables.bucketName, key=arguments.path );
    }

    public string function putObject(
          required binary object
        , required string path
        ,          string mimeType = ""
        ,          boolean isPrivate = false
    ) {
        variables.s3.putObject(
              bucket  = variables.bucketName
            , key     = arguments.path
            , body    = arguments.object
            , acl     = arguments.isPrivate ? "private" : "public-read"
        );
        return arguments.path;
    }

    public boolean function deleteObject( required string path ) {
        variables.s3.deleteObject( bucket=variables.bucketName, key=arguments.path );
        return true;
    }

    public boolean function objectExists( required string path ) {
        return variables.s3.objectExists( bucket=variables.bucketName, key=arguments.path );
    }

    public string function getObjectUrl( required string path ) {
        return "https://#variables.bucketName#.s3.amazonaws.com#arguments.path#";
    }
}

// Register provider in Config.cfc:
settings.storageProviders.s3 = {
    class = "app.services.fileStorage.S3StorageProvider"
};

// Form for admin UI config: /forms/storage-providers/s3.xml
```

---

## Asset Manager Service

```cfml
property name="assetManagerService" inject="assetManagerService";

// List derivatives
var derivatives = assetManagerService.listDerivatives();
var editorDerivs = assetManagerService.listEditorDerivatives();

// Queue derivative generation
assetManagerService.queueAssetDerivatives(
      assetId    = assetId
    , derivative = "thumbnail"
);

// Get asset metadata
var asset = assetManagerService.getAssetData( assetId );
// Returns struct: { id, title, filename, type, filesize, ... }

// Get asset dimensions (image)
var dimensions = assetManagerService.getAssetDimensions(
      id             = assetId
    , derivativeName = "thumbnail"
);
// Returns: { width=200, height=150 }

// Upload an asset programmatically
var assetId = assetManagerService.addAsset(
      filePath       = tmpFilePath
    , fileName       = "myfile.pdf"
    , folder         = folderIdOrSlug
    , assetData      = { title="My Document", description="..." }
);
```

---

## File Download Interception

Control access to private/protected assets:

```cfml
// /interceptors/AssetAccessControl.cfc
component extends="coldbox.system.Interceptor" {

    property name="websiteLoginService" inject="provider:websiteLoginService";
    property name="permService"         inject="provider:websitePermissionService";

    public void function configure() {}

    public void function preDownloadFile( event, interceptData ) {
        var storageProvider = event.getValue( "storageProvider", "" );

        if ( storageProvider == "privateAssets" ) {
            if ( !websiteLoginService.isLoggedIn() ) {
                event.accessDenied( reason="LOGIN_REQUIRED" );
            }

            var userId = websiteLoginService.getLoggedInUserId();
            if ( !permService.hasPermission( permissionKey="assets.access", userId=userId ) ) {
                event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
            }
        }
    }
}
```

---

## Asset Picker Form Control Options

```xml
<field name="hero_image"
       control="assetPicker"
       allowedTypes="image"
       multiple="false"
       maxFileSize="5"
       label="Hero Image" />

<field name="docs"
       control="assetPicker"
       allowedTypes="document,pdf"
       multiple="true"
       maxFiles="10"
       label="Documents" />
```
