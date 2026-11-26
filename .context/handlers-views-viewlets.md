# Handlers, Views, Viewlets, Page Types & Widgets

## Handler Conventions

Preside follows ColdBox's handler conventions. Handlers live in `/handlers/`.

```cfml
// /handlers/Blog.cfc
component {

    // Runs before every action in this handler
    public void function preHandler( event, action, eventArguments ) {
        // event  = RequestContext
        // rc     = event.getCollection() — public (URL/form params)
        // prc    = event.getCollection(private=true) — view data
    }

    public void function index( event, rc, prc ) {
        prc.posts      = getModel( "blogService" ).listPosts( page=rc.page ?: 1 );
        prc.totalPages = getModel( "blogService" ).getTotalPages();
        event.setView( "blog/index" );
    }

    public void function post( event, rc, prc ) {
        var postId = rc.id ?: "";
        if ( !Len(Trim(postId)) ) { event.notFound(); }
        prc.post = getModel( "blogService" ).getPost( postId );
        event.setView( "blog/post" );
    }
}
```

### Admin Handler
```cfml
component extends="preside.system.base.AdminHandler" {

    public void function preHandler( event, action, eventArguments ) {
        super.preHandler( argumentCollection=arguments ); // REQUIRED — checks login, sets layout
        event.addAdminBreadCrumb( title="Blog", link=event.buildAdminLink(linkTo="blog") );
    }

    public void function index( event, rc, prc ) {
        prc.pageTitle = "Manage Blog";
        prc.pageIcon  = "fa-pencil";
        event.setView( "admin/blog/index" );
    }

    // Action handlers must end with "Action" for CSRF protection
    public void function savePostAction( event, rc, prc ) { ... }
}
```

### Key Event Object Methods

```cfml
// Views & Rendering
event.setView( "path/to/view" )           // Set view (omit /views/ prefix)
event.setLayout( "layoutName" )           // Override layout
event.noLayout()                          // Render view without layout
event.renderData( type="json", data={} )  // Return JSON/XML/text directly

// URLs
event.buildLink( page=pageId )                       // Site tree page URL
event.buildLink( linkTo="handler.action" )           // Handler URL
event.buildLink( linkTo="handler.action", queryString="id=x" )
event.buildAdminLink( linkTo="handler.action" )      // Admin URL
event.buildLink( assetId=assetId )                   // Asset download URL
event.buildLink( assetId=assetId, derivative="thumb" )

// Request collection
rc.paramName                              // URL/form parameters
prc.paramName                            // Private collection (view data)

// Site tree context
event.getCurrentPageId()
event.getPageProperty( "title" )
event.getPageProperty( "page_type" )
event.isCurrentPageActive()

// Admin context
event.getAdminUserId()
event.isAdminUser()
event.isAdminRequest()

// Errors
event.notFound()                          // 404
event.accessDenied()                      // 403
event.adminAccessDenied()                 // Admin 403

// Breadcrumbs
event.addAdminBreadCrumb( title="Title", link=url )
event.getBreadCrumbs()

// Caching
event.cachePage()                         // Is page being cached? (boolean)
event.cachePage( false )                  // Disable page caching
event.setPageCacheTimeout( 3600 )

// Announcements
announceInterception( "myEvent", { key=value } )
```

---

## Views

Views are CFM files in `/views/`. Accessed as `handler/action.cfm`.

```cfm
<!-- /views/blog/index.cfm -->
<cfparam name="prc.posts" type="query" />
<cfparam name="prc.totalPages" type="numeric" default="1" />

<cfoutput>
<div class="blog-listing">
    <cfloop query="prc.posts">
        <article>
            <h2><a href="#event.buildLink(linkTo='blog.post', queryString='id=#prc.posts.id#')#">
                #HtmlEditFormat(prc.posts.title)#
            </a></h2>
            <p>#prc.posts.teaser#</p>
        </article>
    </cfloop>
</div>
</cfoutput>
```

### Preside Object Views (Data-Driven Views)

Bypass handlers entirely — pass data directly to a view:

```cfm
#renderView(
      view          = "blog/postCard"
    , presideObject = "blog_post"
    , filter        = { published=true }
    , orderBy       = "publish_date desc"
    , maxRows       = 5
)#
```

View declares what fields it needs via `cf_presideparam`:
```cfm
<!-- /views/blog/postCard.cfm -->
<cf_presideparam name="args.title" />
<cf_presideparam name="args.teaser" />
<cf_presideparam name="args.author" field="author.display_name" />
<cf_presideparam name="args.comment_count" field="Count(comments.id)" />

<cfoutput>
<div class="card">
    <h3>#args.title#</h3>
    <p>#args.teaser#</p>
    <small>By #args.author# | #args.comment_count# comments</small>
</div>
</cfoutput>
```

---

## Viewlets

Viewlets are self-contained reusable components — a private handler action + a view.

### Creating a Viewlet

**Handler** (`/handlers/MyHandler.cfc`):
```cfml
component {
    private string function recentPosts( event, rc, prc, args={} ) {
        args.posts = getModel("blogService").getRecent(
              limit    = args.limit ?: 5
            , category = args.category ?: ""
        );
        return renderView( view="/viewlets/recentPosts", args=args );
    }
}
```

**View** (`/views/viewlets/recentPosts.cfm`):
```cfm
<cfparam name="args.posts" type="query" />
<cfoutput>
<ul class="recent-posts">
    <cfloop query="args.posts">
        <li><a href="...">#HtmlEditFormat(args.posts.title)#</a></li>
    </cfloop>
</ul>
</cfoutput>
```

**Usage** (from any view or handler):
```cfm
#renderViewlet( event="myHandler.recentPosts", args={ limit=3, category="news" } )#
```

### View-Only Viewlet

If no handler exists, Preside looks for the view directly. Place at `/views/{event/path}/index.cfm`.

### renderViewlet() Options

```cfml
renderViewlet(
      event         = "handler.action"    // Required
    , args          = { key=value }       // Passed to handler + view
    , cache         = false               // Cache the output
    , cacheTimeout  = 3600                // Cache TTL in seconds
    , cacheKey      = "my-unique-key"     // Custom cache key
    , delayed       = false               // Render after page cache fetch
)
```

---

## Page Types

Page types define custom field groups for site tree pages.

### Structure

```
/preside-objects/page-types/event.cfc   # Data object
/handlers/page-types/event.cfc          # Optional: handler with logic
/views/page-types/event/index.cfm       # Default layout
/views/page-types/event/featured.cfm    # Alternative layout
/forms/page-types/event.xml             # Edit form (optional)
/i18n/page-types/event.properties       # Labels
```

### Data Object

```cfml
// /preside-objects/page-types/event.cfc
/**
 * @allowedParentPageTypes *
 * @allowedChildPageTypes  none
 * @showInSiteTree         true
 */
component {
    // 'page' FK is auto-added (many-to-one to page object)
    property name="start_date" type="date"    dbtype="date"    required=true;
    property name="end_date"   type="date"    dbtype="date"    required=true;
    property name="location"   type="string"  dbtype="varchar" maxLength=200;
    property name="capacity"   type="numeric" dbtype="int";
}
```

### View (View-Only Mode)
```cfm
<!-- /views/page-types/event/index.cfm -->
<cf_presideparam name="args.title"      field="page.title"      editable="true" />
<cf_presideparam name="args.start_date" field="event.start_date" editable="true" />
<cf_presideparam name="args.end_date"   field="event.end_date" />
<cf_presideparam name="args.location"   field="event.location" />

<cfoutput>
<article class="event">
    <h1>#args.title#</h1>
    <p class="dates">#DateFormat(args.start_date)# – #DateFormat(args.end_date)#</p>
    <p class="location">#HtmlEditFormat(args.location)#</p>
</article>
</cfoutput>
```

### Handler (With Logic)
```cfml
// /handlers/page-types/event.cfc
component {
    private string function index( event, rc, prc, args={} ) {
        args.relatedEvents = getModel("eventService").getRelated(
            eventId = event.getCurrentPageId()
        );
        return renderView( view="/page-types/event/index", args=args );
    }
}
```

### i18n Properties
```properties
# /i18n/page-types/event.properties
name=Event Page
description=A page type for events
iconclass=fa-calendar

layout.index=Default
layout.featured=Featured

field.start_date.title=Start Date
field.end_date.title=End Date
```

---

## Widgets

Widgets are user-placeable viewlets inserted in rich text editor fields.

### Structure

```
/forms/widgets/promoBox.xml             # Config form (editable by content editors)
/i18n/widgets/promoBox.properties       # Labels
/handlers/widgets/PromoBox.cfc          # Logic (index + optional placeholder)
/views/widgets/promoBox/index.cfm       # Rendered output
```

### Handler
```cfml
// /handlers/widgets/PromoBox.cfc
component {

    /** @cacheable false */
    private string function index( event, rc, prc, args={} ) {
        // args contains editor-configured values
        return renderView( view="/widgets/promoBox/index", args=args );
    }

    // Optional: customise placeholder shown in the editor
    private string function placeholder( event, rc, prc, args={} ) {
        return "Promo Box: " & HtmlEditFormat( args.title ?: "" );
    }
}
```

### Config Form
```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.promoBox:" categories="default,email">
    <tab id="default">
        <fieldset id="default">
            <field name="title"       control="textinput"  required="true"  />
            <field name="description" control="richeditor"                  />
            <field name="linkUrl"     control="linkPicker"                  />
            <field name="buttonText"  control="textinput"                   />
            <field name="image"       control="assetPicker" allowedTypes="image" />
        </fieldset>
    </tab>
</form>
```

### i18n Properties
```properties
# /i18n/widgets/promoBox.properties
title=Promo Box
description=A promotional content block
iconclass=fa-megaphone
placeholder=Promo Box: {1}

field.title.label=Heading
field.linkUrl.label=Link URL
field.buttonText.label=Button text
field.image.label=Image
```

### Widget Feature Flags & Categories
```cfml
// Config.cfc
settings.features.myFeature = {
    enabled = true,
    widgets = [ "promoBox", "heroSlider" ]  // Widgets only active with this feature
};
```

Filter widget availability in a richeditor field:
```xml
<field name="content" control="richeditor" widgetCategories="content,email" />
```

---

## Routing

### Built-in Routes
| Pattern | Destination |
|---------|-------------|
| `/about-us/team/` | Site tree page (via slug matching) |
| `/admin/...` | Admin handlers via `admin.{handler}.{action}` |
| `/asset/{id}/` | Asset download |
| `/asset/{id}/{derivative}/` | Asset derivative |

### Custom Route Handler
```cfml
// /handlers/routeHandlers/ProfileRouteHandler.cfc
component implements="preside.system.routeHandlers.iRouteHandler" {

    // Match incoming URL
    public boolean function match( required string path, required any event ) {
        return ReFindNoCase( "^/profile/", arguments.path );
    }

    // Translate URL to ColdBox event
    public void function translate( required string path, required any event ) {
        var action = ReReplace( arguments.path, "^/profile/", "" );
        action = ListChangeDelims( action, ".", "/" );
        event.setValue( "event", "profile." & action );
    }

    // For buildLink() to use this handler
    public boolean function reverseMatch( required struct buildArgs, required any event ) {
        return (buildArgs.linkTo ?: "") contains "profile.";
    }

    public string function build( required struct buildArgs, required any event ) {
        return "/profile/" & ListChangeDelims( ListRest(buildArgs.linkTo,"."), "/", "." ) & "/";
    }
}
```

Register in `/application/config/Routes.cfm`:
```cfml
addRouteHandler( getModel("ProfileRouteHandler") );
```

---

## Site Tree Navigation Viewlets

```cfm
<!-- Main navigation -->
#renderViewlet( event="core.navigation.mainNavigation", args={ depth=2 } )#

<!-- Sub-navigation -->
#renderViewlet( event="core.navigation.subNavigation", args={ startLevel=2, depth=3 } )#

<!-- Breadcrumbs -->
#renderViewlet( event="core.navigation.breadCrumbs" )#
```

Add breadcrumb from a handler:
```cfml
event.addBreadCrumb( title="My Section", link=event.buildLink(linkTo="section.index") );
```

Intercept navigation to modify menu items:
```cfml
public void function onGetMainNavigationMenuItems( event, interceptData ) {
    // interceptData.menuItems is an array of menu item structs
    // Add, remove, or modify items here
}
```

---

## Full Page Caching

```cfml
// Config.cfc
settings.features.fullPageCaching.enabled = true;
settings.fullPageCaching.limitCacheData   = true;
settings.fullPageCaching.limitCacheDataKeys.prc = [
      "_site", "presidePage", "currentLayout"
];

// In a handler/widget — disable caching for this request:
event.cachePage( false );
event.setPageCacheTimeout( 3600 );  // Custom TTL

// In a widget — mark as not cacheable:
/** @cacheable false */
private string function index( event, rc, prc, args={} ) { ... }

// Render a viewlet AFTER cache is served (for personalised content):
#renderViewlet( event="widgets.UserGreeting", args=args, delayed=true )#
```

---

## Draft Content

```cfml
// Enable drafts on object:
/**
 * @datamanagerAllowDrafts true
 */
component { ... }

// Or via Data Manager customization handler:
// getDraftPreviewActionButtons(), getDraftVersionLabelOptions(), etc.
```
