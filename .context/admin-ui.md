# Admin UI: Data Manager, Applications & Navigation

## Data Manager

Data Manager provides automatic CRUD admin UI for any Preside Object.

### Enable for an Object

```cfml
/**
 * @datamanagerEnabled              true
 * @datamanagerGroup                blog
 * @labelfield                      title
 * @datamanagerGridFields           title,author,published,datecreated
 * @datamanagerSortableFields       title,datecreated
 * @datamanagerSearchFields         title,body
 * @datamanagerDefaultSortOrder     datecreated desc
 * @datamanagerAllowedOperations    read,add,edit,delete,clone,viewversions
 * @datamanagerAllowDrafts          true
 * @datamanagerModalView            true
 * @datamanagerTreeView             true
 * @datamanagerTreeParentProperty   parent_category
 * @datamanagerTreeSortOrder        sort_order
 */
component {
    property name="title" type="string" dbtype="varchar" maxlength="200" required=true;
}
```

**Allowed operations:** `read`, `add`, `edit`, `batchedit`, `delete`, `batchdelete`, `clone`, `viewversions`

### i18n for Data Manager

```properties
# /i18n/preside-objects/blog_post.properties
title=Blog Posts
title.singular=Blog Post
description=Manage blog posts
iconclass=fa-pencil

field.title.title=Title
field.title.help=The blog post title
field.title.placeholder=Enter title

field.published.title=Published
field.published.listing.title=Pub?    # Short column heading
```

### Data Manager Groups

```properties
# /i18n/preside-objects/groups/blog.properties
title=Blog
description=Blog content management
iconclass=fa-comments
```

### Form Conventions

| Form | Path |
|------|------|
| Default (add + edit) | `/forms/preside-objects/{objectName}.xml` |
| Add only | `/forms/preside-objects/{objectName}/admin.add.xml` |
| Edit only | `/forms/preside-objects/{objectName}/admin.edit.xml` |
| Quick-add modal | `/forms/preside-objects/{objectName}/admin.quickadd.xml` |
| Quick-edit modal | `/forms/preside-objects/{objectName}/admin.quickedit.xml` |
| Clone | `/forms/preside-objects/{objectName}/admin.clone.xml` |
| Translate | `/forms/preside-objects/_translation_{objectName}/admin.edit.xml` |

### Data Manager Customization Handler

Create `/handlers/admin/datamanager/{objectName}.cfc` to override Data Manager behaviour:

```cfml
component extends="preside.system.base.AdminHandler" {

    // Override form names
    private string function getEditRecordFormName( event, rc, prc, args={} ) {
        return "preside-objects.blog_post.admin.edit.#args.record.status#";
    }

    // Intercept before/after operations
    private void function preEditRecordAction( event, rc, prc, args={} ) {
        // Runs before save
    }

    private void function postEditRecordAction( event, rc, prc, args={} ) {
        // Runs after save — args.recordId available
        clearSearchIndex( args.recordId );
    }

    private void function preAddRecordAction( event, rc, prc, args={} ) {}
    private void function postAddRecordAction( event, rc, prc, args={} ) {}
    private void function preDeleteRecordAction( event, rc, prc, args={} ) {}
    private void function postDeleteRecordAction( event, rc, prc, args={} ) {}

    // Customise grid query
    private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
        args.extraFilters = args.extraFilters ?: [];
        args.extraFilters.append({ filter={ author=event.getAdminUserId() } });
    }

    // Custom action buttons per record
    private array function getExtraRecordActionsForGridListing( event, rc, prc, args={} ) {
        return [{
              link      = event.buildAdminLink( linkTo="blog.preview", queryString="id=#args.record.id#" )
            , title     = "Preview"
            , iconClass = "fa-eye"
            , target    = "_blank"
        }];
    }

    // Draft preview buttons
    private array function getDraftPreviewActionButtons( event, rc, prc, args={} ) {
        return [{
              title     = "Preview on site"
            , link      = event.buildLink( linkTo="blog.view", queryString="id=#args.recordId#&draft=true" )
            , iconClass = "fa-globe"
            , target    = "_blank"
        }];
    }
}
```

---

## Admin Applications

Multiple separate admin applications can coexist (e.g. main CMS + Events Manager):

```cfml
// Config.cfc
settings.adminApplications.append({
      id                 = "ems"
    , feature            = "ems"
    , accessPermission   = "ems.access"
    , defaultEvent       = "admin.ems.index"
    , activeEventPattern = "^admin\.ems\..*"
    , layout             = "ems"               // Uses /layouts/ems.cfm
});

settings.features.ems = { enabled=true };
settings.adminPermissions.ems = [ "access" ];
settings.adminRoles.eventsManager = [ "ems.*" ];
```

Admin handler for the application:
```cfml
// /handlers/admin/Ems.cfc
component extends="preside.system.base.AdminHandler" {

    public void function preHandler( event, action, eventArguments ) {
        super.preHandler( argumentCollection=arguments );
        if ( !isFeatureEnabled("ems") ) { event.notFound(); }
        if ( !hasCmsPermission("ems.access") ) { event.adminAccessDenied(); }
        prc.pageIcon = "fa-calendar";
    }

    public void function index( event, rc, prc ) {
        prc.pageTitle = "Events Manager";
        event.setView( "admin/ems/index" );
    }
}
```

---

## Admin Left-Hand Navigation (v10.17.0+)

### Configure Menu Items in Config.cfc

```cfml
settings.adminSideBarItems = [
      "sitetree"
    , "assetmanager"
    , "datamanager"
    , "usermanager"
    , "websiteUserManager"
    , "systemConfiguration"
    , "updateManager"
    , "myCustomItem"      // Add custom items
];

settings.adminMenuItems.myCustomItem = {
      feature           = "myFeature"
    , permissionKey     = "myfeature.access"
    , activeChecks      = { handlerPatterns="^admin\\.myfeature\\..*" }
    , buildLinkArgs     = { linkTo="admin.myfeature.index" }
    , gotoKey           = "m"
    , icon              = "fa-star"
    , title             = "myapp:admin.nav.myfeature"
    , subMenuItems      = [ "mySubItem" ]
};

settings.adminMenuItems.mySubItem = {
      activeChecks  = { datamanagerObject="my_object" }
    , buildLinkArgs = { linkTo="datamanager.object", queryString="object=my_object" }
    , title         = "myapp:admin.nav.myobject"
};
```

### Dynamic Menu Item Handler
```cfml
// /handlers/admin/layout/menuitem/myCustomItem.cfc
component {
    private boolean function isActive( args={} ) { return false; }
    private string function buildLink( args={} ) {
        return event.buildAdminLink( linkTo="myfeature.index" );
    }
    private void function prepare( args={} ) {
        // Dynamically add children
        args.subMenuItems.append( getModel("myService").getDynamicNavItems(), true );
    }
}
```

### Legacy Sidebar View (pre-v10.17.0)
```cfm
<!-- /views/admin/layout/sidebar/myfeature.cfm -->
<cfif hasCmsPermission("myfeature.access")>
    <cfoutput>
    #renderView( view="/admin/layout/sidebar/_menuItem", args={
          active  = ReFindNoCase( "^admin\.myfeature", event.getCurrentEvent() )
        , title   = translateResource( "myapp:admin.nav.myfeature" )
        , link    = event.buildAdminLink( linkTo="myfeature.index" )
        , icon    = "fa-star"
    } )#
    </cfoutput>
</cfif>
```

---

## Admin System Configuration Menu

```cfml
// Config.cfc
settings.adminConfigurationMenuItems = [
      "usermanager"
    , "systemConfiguration"
    , "taskmanager"
    , "errorLogs"
    , "auditTrail"
    , "myConfigSection"   // Add custom items
];
```

Legacy view for custom config menu item:
```cfm
<!-- /views/admin/layout/configurationMenu/myConfigSection.cfm -->
<cfif isFeatureEnabled("myFeature") && hasCmsPermission("myfeature.configure")>
    <cfoutput>
    <li>
        <a href="#event.buildAdminLink( linkTo="myfeature.configure" )#">
            <i class="fa fa-fw fa-cog"></i>
            #translateResource("myapp:admin.config.myfeature")#
        </a>
    </li>
    </cfoutput>
</cfif>
```

---

## Admin Handler Conventions

All admin handlers extend `preside.system.base.AdminHandler`:

```cfml
component extends="preside.system.base.AdminHandler" {

    public void function preHandler( event, action, eventArguments ) {
        super.preHandler( argumentCollection=arguments );
        // super.preHandler checks login, sets layout, etc.

        // Add breadcrumb
        event.addAdminBreadCrumb(
              title = translateResource( "myapp:breadcrumb.title" )
            , link  = event.buildAdminLink( linkTo="myfeature.index" )
        );
    }

    public void function index( event, rc, prc ) {
        prc.pageTitle    = translateResource( "myapp:page.title" );
        prc.pageSubTitle = translateResource( "myapp:page.subtitle" );
        prc.pageIcon     = "fa-star";

        event.setView( "admin/myfeature/index" );
    }

    // Action handlers (names must end with "Action" for CSRF protection)
    public void function saveAction( event, rc, prc ) {
        var formData = event.getCollectionForForm( "my.form" );
        var vr       = validateForm( "my.form", formData );

        if ( !vr.validated() ) {
            setNextEvent(
                  url           = event.buildAdminLink( linkTo="myfeature.index" )
                , persistStruct = { validationResult=vr, formData=formData }
            );
        }

        getModel("myService").save( formData );
        setNextEvent( url=event.buildAdminLink( linkTo="myfeature.index" ) );
    }
}
```

### Key Admin Event Methods

```cfml
event.buildAdminLink( linkTo="handler.action", queryString="id=x" )
event.addAdminBreadCrumb( title="Title", link=url )
event.adminAccessDenied()
event.getAdminUserId()
event.isAdminRequest()
hasCmsPermission( "permission.key" )
translateResource( "bundle:key" )
renderViewlet( event="admin.myhandler.myviewlet", args={} )
```

---

## Editable System Settings

Configurable settings stored in DB and editable via the admin:

```cfml
// 1. Form: /forms/system-config/my-settings.xml
// 2. i18n: /i18n/system-config/my-settings.properties
//    name=My Settings
//    description=Configure my feature

// 3. (Optional) Register in system config menu via Config.cfc
```

Retrieve settings:
```cfml
// In handlers/views:
var apiKey = getSystemSetting( category="my-settings", setting="api_key", default="" );

// In services:
var apiKey = $getPresideSetting( "my-settings", "api_key", "default" );
var allSettings = $getPresideCategorySettings( "my-settings" );

// Via WireBox DSL:
property name="apiKey" inject="presidecms:systemsetting:my-settings.api_key";
```
