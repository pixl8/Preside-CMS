---
id: presidesuperclass
title: Using the super class
---

PresideCMS comes with its own suite of service objects that you can use in your application just like any of your application's own service objects. In order to make it easy to access the most common core services, we created the [[api-presidesuperclass]] that can be injected into your service objects simply by adding the `@presideService` annotation to your service CFC file:

```luceescript
/**
 * @presideService
 */
component {

    function init() {
        return this;
    }

    // ...
}
// or
component presideService {

    function init() {
        return this;
    }

    // ...
}
```

>>> Service CFCs that declare themselves as Preside Services **must** implement an `init()` method, even if it does nothing but `return this;`.

Once your service has been flagged as being a "Preside Service", it will instantly have a number of core methods available to it such as `$getPresideObject()` and `$isFeatureEnabled()`. e.g.

```luceescript
public boolean function updateProfilePicture( required string pictureFilePath ) {
    if ( $isWebsiteUserLoggedIn() && !$isWebsiteUserImpersonated() ) {
        return $getPresideObject( "website_user" ).updateData(
              id   = $getWebsiteLoggedInUserId()
            , data = { profile_picture = arguments.pictureFilePath }
        );
    }

    return false;
}
```

For a full reference of all the methods available, see [[api-presidesuperclass]].

>>> You will notice that we have prefixed all the function names in the Super Class with `$`. This is to make name conflicts less likely and to indicate that the methods have been injected into your object.
