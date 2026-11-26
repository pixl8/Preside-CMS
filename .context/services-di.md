# Services, Dependency Injection & PresideSuperClass

## Service Layer Conventions

Services are CFC files in `/services/`. They're auto-discovered and registered as singletons by WireBox.

### Basic Service
```cfml
// /services/BlogService.cfc
/**
 * @presideService true
 * @singleton      true
 */
component {

    public any function init(
        /**
         * @blogPostDao.inject presidecms:object:blog_post
         * @categoryDao.inject presidecms:object:blog_category
         */
        required any blogPostDao,
        required any categoryDao
    ) {
        _setBlogPostDao( arguments.blogPostDao );
        _setCategoryDao( arguments.categoryDao );
        return this;
    }

    public query function listPosts( numeric page=1, numeric perPage=10 ) {
        return _getBlogPostDao().selectData(
              filter    = { published=true }
            , orderBy   = "publish_date desc"
            , startRow  = ((arguments.page-1) * arguments.perPage) + 1
            , maxRows   = arguments.perPage
        );
    }

    // Private getters/setters by convention
    private any function _getBlogPostDao() { return _blogPostDao; }
    private void function _setBlogPostDao( required any dao ) { _blogPostDao = arguments.dao; }
    private any function _getCategoryDao() { return _categoryDao; }
    private void function _setCategoryDao( required any dao ) { _categoryDao = arguments.dao; }
}
```

### Injecting Services into Handlers/Other Services
```cfml
// Via property injection
property name="blogService" inject="blogService";

// Via getModel() in handlers
var service = getModel("blogService");

// Via getInstance() anywhere
var service = getInstance("blogService");
```

---

## PresideSuperClass

Services annotated with `@presideService` get injected with helper methods prefixed `$`. You don't call them on `this` — they're mixed in.

### Declaring a Preside Service

```cfml
/**
 * @presideService
 */
component {
    function init() { return this; }
}

// Equivalent (attribute syntax):
component presideService {
    function init() { return this; }
}
```

### Data Access Methods

```cfml
// Get object DAO
var dao = $getPresideObject( "blog_post" );
var records = dao.selectData( filter={ published=true } );

// Or get the service directly
var objService = $getPresideObjectService();
var records = objService.selectData( objectName="blog_post", filter={ published=true } );
```

### System Settings
```cfml
var apiKey    = $getPresideSetting( category="myapp", setting="api_key", default="" );
var allConfig = $getPresideCategorySettings( category="myapp" );
```

### Authentication
```cfml
// Admin user
$isAdminUserLoggedIn()                  // boolean
$getAdminLoggedInUserId()               // string ID
$getAdminLoggedInUserDetails()          // query row
$hasAdminPermission( "perm.key" )       // boolean

// Website user
$isWebsiteUserLoggedIn()                // boolean
$getWebsiteLoginService().getLoggedInUserId()
```

### Feature Flags
```cfml
$isFeatureEnabled( "myFeature" )                    // boolean
$isFeatureEnabled( "feat1 or (feat2 and feat3)" )   // boolean expression
```

### Email
```cfml
$sendEmail(
      template    = "bookingConfirmation"
    , recipientId = userId
    , args        = { bookingId=bookingId }
);
```

### Audit Trail
```cfml
$audit(
      action   = "blog_post_published"
    , type     = "blog"
    , recordId = postId
    , detail   = { title=post.title }
);
```

### Task Manager
```cfml
// Run a scheduled task immediately
$runTask( taskKey="rebuildSearchIndexes", args={ index="main" } );

// Create an ad-hoc background task
var taskId = createTask(
      event  = "myHandler.longRunningAction"
    , args   = { someArg=someValue }
    , runNow = true
);
```

### i18n
```cfml
$translateResource( "myapp:some.key" )
$translateResource( uri="myapp:some.key", data=[ "John", 5 ] )
```

### Helper Functions (v10.11.0+)
```cfml
// Access all ColdBox helper UDFs via $helpers
$helpers.isTrue( someValue )
$helpers.formatDateTime( myDate )
```

### Getting Other Services
```cfml
$getColdbox()                   // ColdBox controller
$getAdminLoginService()
$getWebsiteLoginService()
$getAdminPermissionService()
$getWebsitePermissionService()
$getEmailService()
$getNotificationService()
$getTaskManagerService()
$getAuditService()
$getContentRendererService()
$getValidationEngine()
$getFeatureService()
$getErrorLogService()
$getI18n()
```

---

## WireBox Injection DSL Reference

| DSL Syntax | What it Injects |
|------------|-----------------|
| `inject="myService"` | Service named `myService` |
| `inject="presidecms:object:blog_post"` | Preside Object DAO for `blog_post` |
| `inject="cachebox:MyCache"` | Named CacheBox cache |
| `inject="coldbox:setting:myKey"` | ColdBox setting value |
| `inject="coldbox:plugin:sessionStorage"` | ColdBox plugin |
| `inject="delayedInjector:myService"` | Lazy-loaded service (resolved on first use) |
| `inject="featureInjection:myFeat:MyService"` | Service only if feature enabled |

**`delayedInjector`** is important for avoiding circular dependency issues. Use it when service A depends on service B which depends on service A.

### Property Injection (alternative to constructor)
```cfml
component {
    property name="blogPostDao" inject="presidecms:object:blog_post";
    property name="cache"       inject="cachebox:BlogCache";

    function init() { return this; }

    function getRecentPosts() {
        return blogPostDao.selectData(
            filter  = { published=true }
        , maxRows = 5
        , orderBy = "datecreated desc"
        );
    }
}
```

### Feature-Dependent Service Injection
```cfml
component {
    property name="searchEngine" inject="featureInjection:elasticSearch:ElasticSearchService";

    function search( required string q ) {
        if ( $isFeatureEnabled("elasticSearch") ) {
            return searchEngine.search( arguments.q );
        }
        return fallbackSearch( arguments.q );
    }
}
```

---

## Custom WireBox Config

```cfml
// /application/config/Wirebox.cfc
component extends="preside.system.config.Wirebox" {

    public void function configure() {
        super.configure();

        // Map a service with constructor args
        map("profileImageStorage")
            .asSingleton()
            .to("preside.system.services.fileStorage.FileSystemStorageProvider")
            .initArg( name="rootDirectory",  value=expandPath("/uploads/profiles") )
            .initArg( name="trashDirectory", value=expandPath("/uploads/.trash") )
            .initArg( name="rootUrl",        value="" );
    }
}
```

---

## Service Pattern: Private Getters/Setters

Preside follows a convention of private `_getXxx()` / `_setXxx()` methods for encapsulation:

```cfml
// Instead of:
variables.myService = arguments.myService;
return variables.myService;

// Use:
private any function _getMyService() {
    return _myService;
}
private void function _setMyService( required any service ) {
    _myService = arguments.service;
}
```

This is a strong codebase convention. Follow it when adding new services.

---

## Transient vs Singleton

By default all services are singletons. For transient (new instance per injection):

```cfml
/**
 * @presideService true
 * @singleton      false
 */
component {
    function init() { return this; }
}
```

Inject transients via `getInstance()` at call time rather than property injection:
```cfml
function doWork() {
    var worker = getInstance("transientWorker");
    worker.process( data );
}
```
