# Caching

## CacheBox Configuration

Preside configures CacheBox in `/system/config/Cachebox.cfc`. Override in `/application/config/Cachebox.cfc`:

```cfml
// /application/config/Cachebox.cfc
component extends="preside.system.config.Cachebox" {

    public void function configure() {
        super.configure( argumentCollection=arguments );

        // Customise page cache
        cacheBox.caches.PresidePageCache.properties.maxObjects         = 50000;
        cacheBox.caches.PresidePageCache.properties.objectDefaultTimeout = 3600;
        cacheBox.caches.PresidePageCache.properties.evictionPolicy      = "LFU";

        // Add custom cache
        cacheBox.caches.MyFeatureCache = {
              provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
            , properties = {
                  maxObjects           = 1000
                , objectDefaultTimeout = 300
                , evictionPolicy       = "LFU"
                , objectStore          = "ConcurrentStore"
              }
        };
    }
}
```

## Built-in Cache Names

| Cache Name | Purpose |
|------------|---------|
| `default` | General object cache |
| `template` | ColdBox template cache |
| `DefaultQueryCache` | Query result cache |
| `PermissionsCache` | Admin permission cache |
| `PresidePageCache` | Full rendered page cache |
| `PresideRequestCache` | Per-request transient cache |

## Using a Cache in a Service

```cfml
component {
    property name="cache" inject="cachebox:MyFeatureCache";

    function getExpensiveData( required string key ) {
        var cached = cache.get( arguments.key );
        if ( !IsNull( cached ) ) {
            return cached;
        }

        var data = _doExpensiveWork( arguments.key );
        cache.set( arguments.key, data, 300 );  // 300 second TTL
        return data;
    }

    function clearCache( required string key ) {
        cache.clear( arguments.key );
    }

    function clearAllCache() {
        cache.clearAll();
    }
}
```

## Query Caching in selectData

```cfml
// Queries are cached by default
blogPostDao.selectData( useCache=true )

// Custom cache timeout (seconds)
blogPostDao.selectData( useCache=true, cacheTimeout=600 )

// Disable caching
blogPostDao.selectData( useCache=false )
```

## Clearing Caches

Via reload tokens:
```
/?fwReinitCaches=true         # Clear all caches
/?fwReinitDbSync=true         # Sync DB + clear object caches
/?fwReinitObjects=true        # Reload object definitions
```

Programmatically:
```cfml
// Clear the query cache
cacheBox.getCache("DefaultQueryCache").clearAll();

// Clear specific cache key
cacheBox.getCache("PresidePageCache").clear("/about-us/");
```

---

## Full Page Caching

Caches entire rendered HTML pages. Serves cached HTML without executing CFML on subsequent requests.

### Enable

```cfml
// Config.cfc
settings.features.fullPageCaching.enabled = true;

// Optional: also cache for logged-in users
settings.features.fullPageCachingForLoggedInUsers.enabled = true;

// Limit what PRC data is saved with cache entry (reduces memory)
settings.fullPageCaching.limitCacheData = true;
settings.fullPageCaching.limitCacheDataKeys.prc = [
      "_site"
    , "presidePage"
    , "currentLayout"
    , "__presideInlineJs"
    , "_presideUrlPath"
];
```

### Disable Caching Per Request

```cfml
// In a handler or widget:
event.cachePage( false );            // Disable for this request
event.preventPageCache();           // Alternative

// Set custom TTL
event.setPageCacheTimeout( 3600 );  // Seconds

// In a widget annotation:
/** @cacheable false */
private string function index( event, rc, prc, args={} ) { ... }
```

### Delayed Viewlets (Personalised Regions)

Viewlets marked `delayed=true` are rendered AFTER the cached page is served, allowing personalised content to be injected into cached pages:

```cfm
<!-- In a layout or view: -->

<!-- This renders from cache if available: -->
<div class="page-content">
    #renderViewlet( event="page-types.standard.index", args=args )#
</div>

<!-- This always executes fresh, even on cached pages: -->
<div class="user-greeting">
    #renderViewlet( event="widgets.UserGreeting", args={}, delayed=true )#
</div>

<!-- Navigation with access-restricted items: -->
#renderViewlet( event="core.navigation.mainNavigation", delayed=true )#
```

The delayed viewlets mechanism:
1. Page HTML is served from cache
2. Placeholders are left for delayed viewlets
3. Delayed viewlets are then executed and output is inserted

### Full Page Cache Bypass Conditions

The page cache is automatically bypassed when:
- Request is a POST
- URL contains `fwreinit` or other reload params
- `event.cachePage( false )` has been called
- Widget or handler has `@cacheable false`
- Admin user is viewing the page (unless `fullPageCachingForLoggedInUsers` is enabled)

---

## Request Cache

Short-lived per-request cache to avoid duplicate DB calls within a single request:

```cfml
component {
    property name="requestCache" inject="cachebox:PresideRequestCache";

    function getCurrentUser() {
        var cached = requestCache.get( "currentUser" );
        if ( !IsNull(cached) ) { return cached; }

        var user = userService.getLoggedInUser();
        requestCache.set( "currentUser", user );
        return user;
    }
}
```

---

## CKEditor Template Cache

Static assets (CSS, JS) are fingerprinted by default. During development, reload them:
```
/?fwReinitStatic=true
```

Or enable auto-reload in developer mode:
```cfml
settings.developerMode = { reloadStatic=true };
```
