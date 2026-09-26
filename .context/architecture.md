# Architecture, Config, Extensions & Feature Flags

## Bootstrap & Application Startup

`/system/Bootstrap.cfc` orchestrates startup via `setupApplication()`. Modern apps extend it directly in `Application.cfc`:

```cfml
// /Application.cfc
component extends="preside.system.Bootstrap" {
    this.PRESIDE_APPLICATION_ID = "myapp";
    this.PRESIDE_APPLICATION_RELOAD_TIMEOUT = 1200;
    this.PRESIDE_APPLICATION_RELOAD_LOCK_TIMEOUT = 0;

    super.setupApplication(
          id                       = this.PRESIDE_APPLICATION_ID
        , presideSessionManagement = false  // optional
        , sessionTimeout           = CreateTimeSpan( 0, 0, 40, 0 )
    );
}
```

**Startup sequence:**
1. CF mappings established (`/preside`, `/coldbox`, `/app`, `/assets`, `/logs`)
2. `_fetchInjectedSettings()` — loads `.env`, `.injectedConfiguration`, OS env vars
3. ColdBox initialised via custom Bootstrap
4. WireBox maps all services, interceptors registered
5. `postPresideReload` interception fired

**Key interception points:**
- `prePresideReload` / `postPresideReload`
- `onApplicationStart` / `onApplicationEnd`
- `preProcess` / `postProcess`

---

## Config.cfc

Extends `preside.system.config.Config` and calls `super.configure()`:

```cfml
// /application/config/Config.cfc
component extends="preside.system.config.Config" {
    public void function configure() {
        super.configure();

        // Override ColdBox settings
        coldbox.appName = "My Application";
        coldbox.reinitPassword = "mySecurePassword";

        // Feature flags
        settings.features.myFeature = { enabled=true };

        // Admin permissions
        settings.adminPermissions.myapp = [ "access", "manage" ];
        settings.adminRoles.myRole = [ "myapp.*" ];

        // Navigation
        settings.adminSideBarItems.append( "myFeatureNav" );
    }

    // Environment-specific overrides
    public void function local() {
        settings.showErrors = true;
        settings.autoSyncDb = true;
        settings.developerMode = true;
    }
}
```

### Environment Config Injection

Three mechanisms (processed in order, last wins):

1. **`.env` file** (project root):
   ```
   PRESIDE_syncDb=false
   PRESIDE_forceSsl=true
   ```

2. **JSON file** (`/application/config/.injectedConfiguration`):
   ```json
   { "syncDb": false, "forceSsl": true }
   ```

3. **OS environment variables** with `PRESIDE_` prefix.

Access injected values via `settings.env.myKey`.

### Developer Mode (per-request reload)

```cfml
// In local() method:
settings.developerMode = true;  // Reload everything

// Or selectively:
settings.developerMode = {
      dbSync               = true
    , flushCaches          = true
    , reloadForms          = true
    , reloadStatic         = true
    , reloadI18n           = true
    , reloadPresideObjects = true
    , reloadWidgets        = true
    , reloadPageTemplates  = true
};
```

---

## Directory Structure

```
/application
    /config
        Config.cfc          # Main config (extends preside.system.config.Config)
        LocalConfig.cfc     # Local dev overrides (gitignored)
        Wirebox.cfc         # Custom DI mappings (optional)
        Cachebox.cfc        # Custom cache config (optional)
        Routes.cfm          # Custom URL routes (optional)
    /preside-objects/       # CFC data object definitions
    /handlers/              # ColdBox event handlers
        /admin/             # Admin-area handlers
        /page-types/        # Page type handlers
        /widgets/           # Widget handlers
        /formcontrols/      # Custom form controls
        /renderers/         # Label/content renderers
        /dataExporters/     # Data export handlers
        /email/             # Email template handlers
        /rules/             # Rules engine expressions/contexts
        /Tasks.cfc          # Scheduled task definitions
        /SelectDataViews.cfc # Named data queries
        /DataFilters.cfc    # Named data filters
    /services/              # Business logic CFCs
    /views/                 # CFM view templates
    /forms/                 # XML form definitions
        /preside-objects/   # Forms for data objects
        /page-types/        # Forms for page types
        /widgets/           # Widget config forms
    /i18n/                  # .properties resource bundles
        /preside-objects/   # Object field labels
        /widgets/           # Widget labels
        /email/             # Email template strings
        /roles.properties   # Role names
        /permissions.properties
    /layouts/               # Page layout CFMs
    /helpers/               # UDF helper files
    /extensions/            # Third-party extension packages
    /extensions_app/        # App-local extensions
.env                        # Environment variables (gitignored)
```

---

## Extension System

Extensions are self-contained packages of Preside functionality.

### Extension Structure
```
/my-extension/
    manifest.json           # REQUIRED metadata
    box.json                # CommandBox package metadata
    ModuleConfig.cfc        # Optional: ColdBox module config
    /config
        Config.cfc          # Extension config (configure(config) signature)
        Wirebox.cfc         # Extension DI mappings (configure(binder) signature)
    /preside-objects/       # Data objects
    /handlers/              # Handlers
    /services/              # Services
    /views/                 # Views
    /forms/                 # Form definitions
    /i18n/                  # Resource bundles
```

### manifest.json
```json
{
    "id": "preside-ext-my-extension",
    "title": "My Extension",
    "author": "Company Name",
    "version": "1.0.0+0001",
    "dependsOn": ["preside-ext-another-ext"]
}
```

### Extension Config.cfc
Note: uses `configure(config)` signature, NOT `configure()`:
```cfml
component {
    public void function configure( required struct config ) {
        var settings = config.settings ?: {};

        // Add feature flags
        settings.features.myExtFeature = { enabled=true, dependsOn=["admin"] };

        // Add permissions
        settings.adminPermissions.myext = [ "access", "manage" ];

        // Add interceptors
        config.interceptors.append({
            class = "app.extensions.my-extension.interceptors.MyInterceptor"
        });
    }
}
```

### ColdBox Module in an Extension

Add `ModuleConfig.cfc` to make the extension a ColdBox module. This allows namespaced injection:
```cfml
// ModuleConfig.cfc
component {
    this.cfmapping = "myext";  // Allows: getInstance("myext:MyService")
    this.autoMapModels = true;
    this.modelNamespace = "myext";
}
```

---

## Feature Flags

Feature flags are compile-time switches — they affect which files load, not just runtime behaviour.

### Defining Features
```cfml
// In Config.cfc:
settings.features.myFeature = {
      enabled       = true
    , dependsOn     = [ "admin" ]          // parent features (v10.27+)
    , widgets       = [ "myWidget" ]       // widgets requiring this feature
    , siteTemplates = [ "*" ]              // which site templates expose it
};
```

### Applying Features

**Preside Object:**
```cfml
/** @feature myFeature */
component { ... }

// On a single property:
property name="x" feature="myOtherFeature";
```

**Handler or Service:**
```cfml
/** @feature myFeature || anotherFeature */
component { ... }
```

**View (first line):**
```cfm
<!---@feature myFeature--->
```

**Form element:**
```xml
<form feature="myFeature">
    <tab feature="myFeature">
        <field name="x" feature="myFeature" />
    </tab>
</form>
```

### Feature-Dependent Injection
```cfml
property name="optService" inject="featureInjection:myFeature:OptionalService";

function doThing() {
    if ( $isFeatureEnabled("myFeature") ) {
        optService.doThing();
    }
}
```

### .presideIgnore.json
Optimize startup by skipping disabled-feature files. In `Config.cfc`:
```cfml
// Dev: write the file on startup
settings.ignoreFile.read  = false;
settings.ignoreFile.write = true;

// Prod: read the pre-generated file
settings.ignoreFile.read  = true;
settings.ignoreFile.write = false;
```

---

## WireBox Dependency Injection

### Service Auto-Discovery
Services in `/services/`, extension `/services/`, and `/system/services/` are auto-mapped as singletons.

### Injection Annotations
```cfml
/**
 * @presideService           true   -- injects PresideSuperClass helpers
 * @singleton                true   -- (default anyway)
 * @feature                  myFeat -- only map if feature enabled
 * @nowirebox                true   -- exclude from auto-mapping
 */
component {
    public any function init(
        /**
         * @someService.inject           someService
         * @objectDao.inject             presidecms:object:my_object
         * @cache.inject                 cachebox:MyCache
         * @setting.inject               coldbox:setting:myKey
         * @lazyDep.inject               delayedInjector:otherService
         * @optDep.inject                featureInjection:myFeature:OptService
         */
        required any someService,
        required any objectDao
        // ...
    ) {
        _setSomeService( arguments.someService );
        return this;
    }
}
```

### Custom WireBox Mappings
```cfml
// /application/config/Wirebox.cfc
component extends="preside.system.config.Wirebox" {
    public void function configure() {
        super.configure();

        map("mySpecialService")
            .asSingleton()
            .to("app.services.MySpecialService")
            .initArg( name="rootDir", value=expandPath("/uploads") );
    }
}
```

---

## Interception (Event System)

Register interceptors in `Config.cfc`:
```cfml
settings.interceptors.append({
    class = "app.interceptors.MyInterceptor",
    properties = {}
});
```

Interceptor CFC:
```cfml
component extends="coldbox.system.Interceptor" {
    public void function configure() {}

    public void function postInsertObjectData( event, interceptData ) {
        var objectName = interceptData.objectName ?: "";
        if ( objectName == "blog_post" ) {
            // React to new blog post
        }
    }
}
```

### Key Interception Points
| Category | Points |
|----------|--------|
| App lifecycle | `prePresideReload`, `postPresideReload` |
| DB operations | `preInsertObjectData`, `postInsertObjectData`, `preUpdateObjectData`, `postUpdateObjectData`, `preDeleteObjectData`, `postDeleteObjectData`, `preSelectObjectData`, `postSelectObjectData` |
| Auth | `onLoginSuccess`, `onLoginFailure`, `onLogout` |
| REST | `onRestRequest`, `preInvokeRestResource`, `postInvokeRestResource` |
| Email | `preSendEmail`, `postSendEmail`, `onPrepareEmailSendArguments` |
| Site tree | `preRenderSiteTreePage`, `postRenderSiteTreePage` |
| Form builder | `preFormBuilderFormSubmission`, `postFormBuilderFormSubmission` |
| Config | `preSaveSystemConfig` |
| File download | `preDownloadFile` |
