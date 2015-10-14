---
id: workingwithuploadedfiles
title: Working with uploaded files
---

PresideCMS comes with its own Digital Asset Manager (see [[assetmanager]]) and in many cases this will meet your document / image uploading needs. However, there are scenarios in which the users of your website will upload files that will not warrant a presence in your asset manager and the following APIs and practices can be used to deal with these cases.

## The storage provider interface

PresideCMS has a concept of a "Storage Provider" and provides an interface at `/system/services/fileStorage/StorageProvider.cfc`. A storage provider is a an API interface to any implementation of a system that can store and serve files. The system provides a concrete implementation using a regular file system which can be found at `/system/services/fileStorage/FileSystemStorageProvider.cfc`. 

>>> The core asset manager system uses storage providers for its file storage.

Distinct storage provider instances can be created through Wirebox by mapping the storage provider class to an id and passing your custom configuration, i.e. the physical directories in which you will store files, or credentials for a CDN API, etc. Below is an example of creating a storage provider instance with your own file path in your application's `Wirebox.cfc` file (`/application/config/Wirebox.cfc`):

```luceescript
component extends="preside.system.config.WireBox" {

    public void function configure() {
        super.configure();

        var settings = getColdbox().getSettingStructure();

        map( "userProfileImageStorageProvider" ).to( "preside.system.services.fileStorage.FileSystemStorageProvider" )
            .initArg( name="rootDirectory" , value=settings.uploads_directory & "/profilePictures" )
            .initArg( name="trashDirectory", value=settings.uploads_directory & "/.trash" )
            .initArg( name="rootUrl"       , value="" );
    }

}
```

>>>>>> Having individual storage provider instances with their own distinct paths is a good way to organise your uploaded files and can provide you with granularity when dealing with permissions, etc.

### Example upload / download code

The following *example* code will upload a file into the storage provider we created in our example above:

```luceescript
property name="storageProvider" inject="userProfileImageStorageProvider";

public string function uploadProfilePicture( 
      required string userId
    , required string fileExtension
    , required binary uploadedImageBinary 
) {
    var filePath = "/#arguments.userId#.#arguments.fileExtension#";
    
    storageProvider.putObject( object=fileBinary, path=filePath );

    return filePath;
}
```

Downloading a file can be done through a specific core route (see [[routing]]), i.e. you can build a link to the direct download / serving of the file. The syntax is as follows:  

```luceescript
var downloadLink = event.buildLink(
      fileStorageProvider = nameOfStorageProvider
    , fileStoragePath     = storagePathAsStoredInStorageProvider
    , filename            = optionalFileNameUserWillSeeWhenDownloading
);
```

So, for the example above, we might have:

```luceescript
var imageUrl = event.buildLink(
      fileStorageProvider = "userProfileImageStorageProvider"
    , fileStoragePath     = user.profileImagePath
);
```

## Applying access control

There is no built in access control for storage providers. However, the download logic served by the core route handler announces three interception points that you can use to inject your own access control logic. The interception points are:

* preDownloadFile
* onDownloadFile
* onReturnFile304

For access control, your most likely choice will be the `preDownloadFile` interception point. An example implementation might look like this:

```luceescript
component extends="coldbox.system.Interceptor" {
   
    // note: important to use Wirebox's 'provider' DSL here to delay
    // injection in our interceptors
    property name="websiteLoginService"    inject="provider:websiteLoginService";
    property name="myAccessControlService" inject="provider:myAccessControlService";

    public void function configure() {}

    public void function preDownloadFile( event, interceptData ) {
        var rc              = event.getCollection();
        var storageProvider = rc.storageProvider ?: "";
        var storagePath     = rc.storagePath     ?: "";
        var filename        = rc.filename        ?: ListLast( storagePath, "/" );

        if ( storageProvider == "myStorageProviderWithAccessControl" ) {
            if ( !websiteLoginService.isLoggedIn() ) {
                event.accessDenied( reason="LOGIN_REQUIRED" );
            }

            var hasAccess   = myAccessControlService.hasAccess(
                  documentPath = storagePath
                , userId       = websiteLoginService.getLoggedInUserId()
            );
            if ( !hasAccess ) {
                event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
            }
        }
    }
}
```


