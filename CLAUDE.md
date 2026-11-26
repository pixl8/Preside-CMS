# Preside CMS — LLM Agent Context

Preside CMS is an open-source, enterprise-grade CMS built on **ColdBox MVC** and **CFML (Lucee)**. It adds a rich data layer, admin console, permissioning, multi-site support, and extensibility on top of ColdBox.

- **Docs site**: https://docs.preside.org/
- **Docs source**: `~/code/elf/Preside-Documentation/docs/`
- **System source**: `/home/dom/code/elf/Preside-CMS/system/`
- **Application code**: typically `/application/` relative to webroot

## Topic Context Files

Detailed reference for each topic lives in `.context/`:

| File | Covers |
|------|--------|
| [architecture.md](.context/architecture.md) | Bootstrap, Config.cfc, extensions, feature flags, reload, DI |
| [data-objects.md](.context/data-objects.md) | Preside Objects ORM: properties, relationships, CRUD API, filters, versioning |
| [forms-validation.md](.context/forms-validation.md) | Forms XML, field controls, inheritance, validation framework |
| [admin-ui.md](.context/admin-ui.md) | Data Manager, admin applications, left-hand menu, system menu |
| [handlers-views-viewlets.md](.context/handlers-views-viewlets.md) | Handlers, views, viewlets, page types, widgets, routing |
| [services-di.md](.context/services-di.md) | Service layer, WireBox DI, PresideSuperClass |
| [permissions.md](.context/permissions.md) | CMS admin permissions, website user permissions |
| [i18n.md](.context/i18n.md) | Resource bundles, translateResource, multilingual content |
| [task-manager.md](.context/task-manager.md) | Scheduled tasks, ad-hoc background tasks, progress tracking |
| [email.md](.context/email.md) | Email layouts, system templates, recipient types, service providers |
| [rest-api.md](.context/rest-api.md) | REST resources, routing, auth, response handling |
| [asset-manager.md](.context/asset-manager.md) | Assets, derivatives, storage providers, transformations |
| [rules-engine.md](.context/rules-engine.md) | Conditions, filter expressions, contexts, field types |
| [caching.md](.context/caching.md) | CacheBox config, full-page caching, delayed viewlets |
| [misc.md](.context/misc.md) | Auditing, notifications, sessions, migrations, health checks, CSRF, XSS, workflow |

## Key Architectural Concepts (Quick Reference)

### Technology Stack
- **Runtime**: Lucee CFML (5.2.9+)
- **Framework**: ColdBox MVC + WireBox DI + CacheBox
- **ORM**: Custom Preside Objects (not Hibernate)
- **Language**: CFML / CFScript (Lucee dialect)

### Application Layout
```
/application
    /config/Config.cfc      # Extends preside.system.config.Config
    /preside-objects/       # Data object CFCs
    /handlers/              # ColdBox event handlers
    /services/              # Business logic (WireBox singletons)
    /views/                 # CFM view templates
    /forms/                 # XML form definitions
    /i18n/                  # .properties resource bundles
    /layouts/               # Page layout CFMs
    /extensions/            # Third-party extensions
    /extensions_app/        # App-local extensions
.env                        # Environment variables (PRESIDE_ prefix)
```

### CFML Syntax Note
Preside uses **Lucee CFML**. Code is written in CFScript (`.cfc` files) or tag-based (`.cfm` views). CFScript syntax:
```cfml
component {
    function init() { return this; }
    function myMethod( required string arg1, string arg2="" ) {
        var localVar = "value";
        return localVar;
    }
}
```

### The `$` Prefix Convention
Services marked `@presideService` get injected with helper methods prefixed `$`:
```cfml
$getPresideObject( "my_object" )       // get DAO
$getPresideSetting( "cat", "key" )     // system settings
$isFeatureEnabled( "featureName" )     // feature flags
$hasAdminPermission( "perm.key" )      // permissions
$audit( action="x", type="y" )         // audit trail
$sendEmail( template="x", args={} )    // send email
```

### Config Inheritance
```
preside.system.config.Config   ← base
    └── /application/config/Config.cfc  ← app overrides
        └── /application/config/LocalConfig.cfc  ← local dev
```
Environment variables override via `.env` (prefix `PRESIDE_`) or `/application/config/.injectedConfiguration`.

### Reload URLs
```
/?fwreinit=true            # Full reload
/?fwReinitCaches=true      # Clear caches only
/?fwReinitDbSync=true      # Sync DB + reload objects
/?fwReinitForms=true       # Reload form definitions
/?fwReinitI18n=true        # Reload i18n bundles
```

### WireBox Injection DSL
```cfml
property name="myService"      inject="myService";
property name="myObject"       inject="presidecms:object:my_object";
property name="cacheProv"      inject="cachebox:MyCache";
property name="setting"        inject="coldbox:setting:myKey";
property name="lazyService"    inject="delayedInjector:someService";
property name="featureService" inject="featureInjection:myFeature:MyService";
```

### i18n URI Format
```
bundle:key.path
# e.g.:
cms:sitetree.title
preside-objects.blog_post:field.title.title
system-config.email:tab.smtp.title
```

### Feature Flags
```cfml
// Define in Config.cfc
settings.features.myFeature = { enabled=true, dependsOn=["admin"] };

// Check anywhere
if ( isFeatureEnabled( "myFeature" ) ) { ... }        // handlers/views
if ( $isFeatureEnabled( "myFeature" ) ) { ... }       // services

// Apply to objects/handlers/views
/** @feature myFeature */
component { ... }
```
