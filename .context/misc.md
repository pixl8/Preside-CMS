# Miscellaneous: Auditing, Notifications, Sessions, Migrations, Health Checks, CSRF, XSS, Workflow

## Auditing

### Log Audit Events

```cfml
// In a handler:
event.audit(
      action   = "blog_post_published"
    , type     = "blog"
    , recordId = postId
    , detail   = { title=post.title, publishedBy=event.getAdminUserId() }
);

// In a service (PresideSuperClass):
$audit(
      action   = "api_token_used"
    , type     = "api"
    , recordId = tokenId
    , detail   = { endpoint=endpoint }
);
```

### Audit i18n

```properties
# /i18n/auditlog/blog.properties
title=Blog Management
iconClass=fa-pencil

blog_post_published.title=Published blog post
blog_post_published.message={1} published the blog post "{2}"
blog_post_published.iconClass=fa-check green

blog_post_deleted.title=Deleted blog post
blog_post_deleted.message={1} deleted the blog post "{2}"
blog_post_deleted.iconClass=fa-trash red
```

`{1}` = linked admin user name (auto-resolved), `{2}` etc = from `detail` struct.

### Custom Audit Renderer

```cfml
// /handlers/renderers/auditLogEntry/Blog.cfc
component {
    private string function datatable( event, rc, prc, args={} ) {
        return "Post " & HtmlEditFormat( args.detail.title ?: "" ) & " was " & args.action;
    }

    private string function full( event, rc, prc, args={} ) {
        return renderView( view="/renderers/auditLogEntry/blog/full", args=args );
    }
}
```

---

## Notifications

In-app and email notifications for admin users.

### Register Topic

```cfml
// Config.cfc
settings.notificationTopics.append( "bookingCompleted" );
```

```properties
# /i18n/notifications/bookingCompleted.properties
title=Booking Completed
description=Raised when a customer completes a booking
iconClass=fa-calendar-check-o
```

### Raise a Notification

```cfml
property name="notificationService" inject="notificationService";

notificationService.createNotification(
      topic = "bookingCompleted"
    , type  = "INFO"              // "INFO", "WARNING", or "ALERT"
    , data  = { bookingId=newBookingId }
);
```

### Notification Renderers

```cfml
// /handlers/renderers/notifications/BookingCompleted.cfc
component {

    property name="bookingService" inject="bookingService";

    // Brief listing view
    private string function datatable( event, rc, prc, args={} ) {
        var booking = bookingService.getBooking( args.data.bookingId ?: "" );
        return "Booking #HtmlEditFormat( booking.reference )# completed";
    }

    // Detailed view
    private string function full( event, rc, prc, args={} ) {
        args.booking = bookingService.getBooking( args.data.bookingId ?: "" );
        return renderView( view="/renderers/notifications/bookingCompleted/full", args=args );
    }

    // Email subject
    private string function emailSubject( event, rc, prc, args={} ) {
        return "New booking completed: " & (args.data.bookingId ?: "");
    }

    // Email body
    private string function emailHtml( event, rc, prc, args={} ) {
        args.booking = bookingService.getBooking( args.data.bookingId ?: "" );
        return renderView( view="/renderers/notifications/bookingCompleted/emailHtml", args=args );
    }

    private string function emailText( event, rc, prc, args={} ) {
        var booking = bookingService.getBooking( args.data.bookingId ?: "" );
        return "Booking #booking.reference# completed.";
    }
}
```

### Gritter Toast Notifications (Admin UI)

```cfml
// In a handler after an action:
getPlugin("messageBox").info( "Record saved successfully!" );
getPlugin("messageBox").error( "Failed to save record." );
getPlugin("messageBox").warning( "Record saved with warnings." );
```

Configure position in `Config.cfc`:
```cfml
settings.adminNotificationsPosition = "bottom-right";  // top-left, top-right, bottom-left, bottom-right
settings.adminNotificationsSticky   = true;
```

---

## Session Management

### Default (Lucee Sessions)
Standard CFML session management. Configured in `Application.cfc`:
```cfml
super.setupApplication(
      id             = "myapp"
    , sessionTimeout = CreateTimeSpan( 0, 0, 40, 0 )  // 40 minutes
);
```

### Preside Session Management (DB-backed)
For stateless/containerised deployments:
```cfml
super.setupApplication(
      id                       = "myapp"
    , presideSessionManagement = true
);
```

### Stateless Requests
Requests matching these patterns bypass session handling:
```cfml
super.setupApplication(
      id                         = "myapp"
    , statelessUrlPatterns       = [ "^https?://[^/]+/api/.*" ]
    , statelessUserAgentPatterns = [ "CFSCHEDULE", "bot\b", "spider\b" ]
);
```

### Session Storage Plugin
```cfml
property name="sessionStorage" inject="coldbox:plugin:sessionStorage";

sessionStorage.setVar( "key", value );
var val = sessionStorage.getVar( "key", defaultValue );
sessionStorage.deleteVar( "key" );
```

---

## Custom DB Migrations

One-time data migration scripts that run on application startup.

### Migration Handler

```cfml
// /handlers/dbmigrations/2024-03-15_addDefaultBlogCategories.cfc
component {

    // Runs synchronously on startup (blocking)
    private void function run( event, rc, prc ) {
        var categoryDao = $getPresideObject( "blog_category" );

        if ( !categoryDao.dataExists( filter={ slug="uncategorised" } ) ) {
            categoryDao.insertData( data={
                  label = "Uncategorised"
                , slug  = "uncategorised"
            } );
        }
    }

    // Optional: runs ~1 minute after startup (non-blocking)
    private void function runAsync( event, rc, prc ) {
        _slowDataMigration();
    }

    // Optional (v10.20.0+): Only run if condition is met
    private boolean function isEnabled() {
        return isFeatureEnabled( "blog" );
    }
}
```

**Naming convention:** `YYYY-MM-DD_descriptiveName.cfc` — migrations run in alphabetical order.
**Each migration must be idempotent** (safe to re-run: check before inserting, use upsert patterns).

---

## System Alerts

Admin alerts for configuration/system issues.

### Alert Check Handler

```cfml
// /handlers/admin/systemAlerts/CheckEmailConfig.cfc
component {

    private void function runCheck( required systemAlertCheck check ) {
        var settings = $getPresideCategorySettings( "email" );

        if ( !Len( Trim( settings.smtp_server ?: "" ) ) ) {
            check.fail();
            check.setLevel( "critical" );   // "critical", "warning", or "advisory"
            check.setData({ message="SMTP server is not configured" });
        }
    }

    // Optional: render alert detail in admin UI
    private string function render( event, rc, prc, args={} ) {
        return renderView( view="/admin/systemAlerts/checkEmailConfig/render", args=args );
    }

    private boolean function runAtStartup() { return true; }

    private string function schedule() { return "0 0 */6 * * *"; }  // Every 6 hours

    private array function watchSettingsCategories() { return [ "email" ]; }

    private string function defaultLevel() { return "warning"; }
}
```

```properties
# /i18n/systemAlerts/checkEmailConfig.properties
title=Email Configuration Check
```

### Trigger Alert Check Programmatically

```cfml
// In services/handlers:
runSystemAlertCheck( type="CheckEmailConfig" );
runSystemAlertCheck( type="CheckDataMappings", reference=recordId, async=true );
```

### SystemAlertCheck Methods

```cfml
check.fail()
check.pass()
check.setLevel( "critical" | "warning" | "advisory" )
check.setData( { customData="value" } )
check.passes()      // boolean
check.fails()       // boolean
check.getType()
check.getReference()
check.getTrigger()  // "startup", "settings", "schedule", "code", "rerun"
```

---

## Health Checks

Periodic checks of external service availability.

### Configure

```cfml
// Config.cfc
settings.healthcheckServices.ElasticSearch = {
    interval = CreateTimeSpan( 0, 0, 0, 30 )  // Every 30 seconds
};
settings.healthcheckServices.RabbitMQ = {
    interval = CreateTimeSpan( 0, 0, 1, 0 )   // Every 1 minute
};
```

### Handler

```cfml
// /handlers/healthcheck/ElasticSearch.cfc
component {
    property name="elasticSearchService" inject="elasticSearchService";

    private boolean function check() {
        try {
            return elasticSearchService.ping();
        } catch ( any e ) {
            return false;
        }
    }
}
```

### Check Status in Code

```cfml
// In handlers/views:
if ( isUp("elasticSearch") ) {
    prc.results = elasticSearchService.search( rc.q );
} else {
    prc.results = fallbackSearch( rc.q );
}

// In services (PresideSuperClass):
if ( $isDown("elasticSearch") ) {
    return fallbackSearch( arguments.q );
}
```

---

## CSRF Protection

### Admin Protection (Automatic)
Admin action handlers (names ending in `Action`) are automatically CSRF-protected. No code needed.

```cfml
// This is protected automatically:
public void function savePostAction( event, rc, prc ) { ... }
```

Configure:
```cfml
settings.features.adminCsrfProtection.enabled = true;  // Default
settings.csrf.tokenExpiryInSeconds = 3600;              // Default: 1200 (20min)
```

### Frontend CSRF Protection

```cfm
<!-- In form: -->
<form method="post" action="#postUrl#">
    <input type="hidden" name="csrfToken" value="#event.getCsrfToken()#">
    <!-- ... -->
</form>
```

```cfml
// In action handler:
function saveDetails( event, rc, prc ) {
    if ( !event.validateCsrfToken() ) {
        setNextEvent(
              url           = editUrl
            , persistStruct = { error="Invalid security token. Please try again." }
        );
    }
    // ... proceed with save
}
```

---

## XSS Protection (AntiSamy)

Automatically sanitises HTML submitted through rich text fields.

```cfml
// Config.cfc
settings.antiSamy.enabled                  = true;   // Default: on
settings.antiSamy.policy                   = "preside"; // Recommended
settings.antiSamy.bypassForAdministrators  = false;  // Default: false

// Available policies:
// "preside" (recommended, Preside-specific)
// "antisamy" (default AntiSamy)
// "tinymce"
// "ebay"
// "myspace"
// "slashdot"
```

---

## Workflow System (v10.29+)

### DataManager Workflow

Define workflows in YAML and attach to Data Manager objects:

```yaml
# /workflows/datamanager/article_publishing.yml
version: 1.0.0
workflow:
  id: article_publishing

  initialActions:
  - id: create
    result:
      activateSteps: [ "draft" ]

  steps:
  - id: draft
    actions:
    - id: submit_for_review
      result:
        activateSteps: [ "in_review" ]

  - id: in_review
    actions:
    - id: approve
      permission:
        key: articles.publish
      result:
        activateSteps: [ "published" ]
        appendState:
          published: true
    - id: reject
      form: preside-objects.article.reject
      result:
        activateSteps: [ "draft" ]

  - id: published
  - id: archived
```

```cfml
// Object with workflow:
/**
 * @datamanagerEnabled              true
 * @datamanagerWorkflowEnabled      true
 * @datamanagerWorkflowDefaultFlow  article_publishing
 * @datamanagerGridFields           title,datamanager_workflow_status,published,datecreated
 */
component {
    property name="title"     type="string" dbtype="varchar" maxlength="200";
    property name="published" type="boolean" dbtype="boolean" default=false control="none";
}
```

```properties
# /i18n/datamanagerWorkflow/article_publishing.properties
title=Article Publishing Workflow

step.draft.title=Draft
step.in_review.title=In Review
step.published.title=Published

step.draft.action.submit_for_review.title=Submit for Review
step.draft.action.submit_for_review.iconClass=fa-paper-plane

step.in_review.action.approve.title=Approve & Publish
step.in_review.action.approve.iconClass=fa-check
step.in_review.action.reject.title=Send Back for Revision
step.in_review.action.reject.iconClass=fa-times
```

### Workflow Action Handlers

```cfml
// /handlers/admin/datamanager/article.cfc
component extends="preside.system.base.AdminHandler" {

    private function canApprove( event, rc, prc, args={}, wfInstance ) {
        return hasCmsPermission( "articles.publish" );
    }

    private function preApprove( event, rc, prc, args={}, wfInstance ) {
        // Called before approve action executes
        var state = wfInstance.getState();
        wfInstance.appendState({ approvedBy=event.getAdminUserId() });
    }

    private function postApprove( event, rc, prc, args={}, wfInstance ) {
        // Called after approve action completes
        notificationService.createNotification(
              topic = "articlePublished"
            , type  = "INFO"
            , data  = { articleId=args.recordId }
        );
    }
}
```

### Webflow (Multi-Step Frontend Forms)

```yaml
# /workflows/webflows/registration.yml
version: 1.0.0
webflow:
  id: registration
  singleton: false  # Separate instance per user session
  steps:
  - id: personal_details
  - id: contact_details
  - id: confirmation
    finish: true
```

```cfm
<!-- Render in a view: -->
#renderWebflow( "registration" )#
```

```cfml
// /handlers/webflow/Registration.cfc
component {

    private string function personal_details( event, rc, prc, args={}, wfInstance ) {
        return renderView( view="/webflow/registration/personalDetails", args=args );
    }

    private void function personal_detailsAction(
          event, rc, prc, args={}
        , wfInstance
        , persistData        // Struct that persists between steps
        , validationResult   // Add errors to prevent advancing
    ) {
        if ( !Len( Trim( rc.firstName ?: "" ) ) ) {
            validationResult.addError( "firstName", "First name is required" );
        }
        if ( !validationResult.validated() ) { return; }

        persistData.firstName = rc.firstName;
        persistData.lastName  = rc.lastName;
    }
}
```
