# Permissions: Admin CMS & Website Users

## CMS Admin Permissions

### Hierarchy: Permissions → Roles → Groups → Users

### 1. Define Permissions & Roles in Config.cfc

```cfml
public void function configure() {
    super.configure();

    // Flat permissions:
    settings.adminPermissions.blog = [ "navigate", "add", "edit", "delete" ];

    // Nested permissions (produces blog.posts.add, blog.posts.edit, etc.):
    settings.adminPermissions.blog = {
          posts      = [ "navigate", "add", "edit", "delete" ]
        , categories = [ "navigate", "add", "edit", "delete" ]
    };

    // Define a role (collection of permission keys, supports wildcards + negation):
    settings.adminRoles.blogEditor = [
          "blog.*"         // All blog permissions
        , "!blog.*.delete" // Except delete
        , "cms.navigate"   // Plus navigate CMS
    ];

    // Extend an existing role:
    settings.adminRoles.administrator = settings.adminRoles.administrator ?: [];
    settings.adminRoles.administrator.append( "blog.*" );
}
```

### 2. i18n

```properties
# /i18n/permissions.properties
blog.navigate.title=Access Blog section
blog.navigate.description=Permission to access blog management

blog.posts.add.title=Create Blog Posts
blog.posts.add.description=Ability to create new blog posts

# /i18n/roles.properties
blogEditor.title=Blog Editor
blogEditor.description=Manage blog posts and categories (no delete)
blogEditor.group=content

roleGroup.content.title=Content Management
```

### 3. Check Permissions

**In handlers/views:**
```cfml
// Simple check
if ( !hasCmsPermission("blog.posts.add") ) {
    event.adminAccessDenied();
}

// Contextual check (e.g. per-folder, per-record)
if ( !hasCmsPermission(
      permissionKey = "assetManager.folders.upload"
    , context       = "assetmanagerfolders"
    , contextKeys   = [ currentFolderId ]
) ) {
    event.adminAccessDenied();
}
```

**In services (PresideSuperClass):**
```cfml
$hasAdminPermission( "blog.posts.add" )
$hasAdminPermission( permissionKey="blog.posts.add", userId=someUserId )
```

**In views (conditionally show UI):**
```cfm
<cfif hasCmsPermission("blog.posts.add")>
    <a href="#addPostUrl#">Add Post</a>
</cfif>
```

### 4. Contextual Permissions UI Viewlet

Render a permission management form for a specific context:

```cfm
#renderViewlet( event="admin.permissions.contextPermsForm", args={
      permissionKeys      = [ "blog.posts.*", "!blog.posts.delete" ]
    , context             = "blogcategory"
    , contextKey          = categoryId
    , saveAction          = event.buildAdminLink(linkTo="blog.savePermsAction", queryString="id=#categoryId#")
    , cancelAction        = event.buildAdminLink(linkTo="blog.manage", queryString="id=#categoryId#")
} )#
```

### 5. Admin Permission Service

```cfml
property name="adminPermissionService" inject="adminPermissionService";

// Check permission
adminPermissionService.hasPermission( permissionKey="blog.add", userId=userId )

// List roles for display
adminPermissionService.listRoles()                // array of role structs
adminPermissionService.listRolesWithGroup()       // grouped struct

// User groups
adminPermissionService.listUserGroups( userId=userId )
adminPermissionService.userHasAssignedRoles( userId=userId, roles=["blogEditor"] )

// Context permissions
adminPermissionService.getContextPermissions(
      context        = "blogcategory"
    , contextKeys    = [ categoryId ]
    , permissionKeys = [ "blog.posts.*" ]
)

adminPermissionService.syncContextPermissions(
      context             = "blogcategory"
    , contextKey          = categoryId
    , permissionKey       = "blog.posts.add"
    , grantedToGroups     = [ groupId1 ]
    , deniedToGroups      = [ groupId2 ]
)
```

### 6. System Users (Bypass All Checks)

```cfml
// Config.cfc
settings.system_users = "sysadmin,developer";
// Users with these login IDs bypass all permission checks
```

---

## Website User Permissions

Separate from CMS permissions — governs access to frontend website resources.

### 1. Define Website Permissions

```cfml
// Config.cfc
settings.websitePermissions.comments = [ "add", "edit", "delete" ];
settings.websitePermissions.documents = [ "download", "upload" ];
// Core built-ins: pages.access, assets.access
```

```properties
# /i18n/permissions.properties
comments.add.title=Add Comments
comments.add.description=Ability to post comments

documents.download.title=Download Documents
documents.download.description=Access to download protected documents
```

### 2. Website User Objects

- **`website_user`** — Login, email, BCrypt-hashed password
- **`website_benefit`** — User groups (the singular is "benefit", plural is "benefits")
- **`website_applied_permission`** — Grants/denies for users/benefits

### 3. Check Website Permissions

**In handlers/views:**
```cfml
// Simple
if ( !hasWebsitePermission("comments.add") ) {
    event.accessDenied();
}

// Contextual
if ( !hasWebsitePermission(
      permissionKey = "comments.edit"
    , context       = "commentthread"
    , contextKeys   = [ threadId ]
) ) {
    event.accessDenied();
}
```

**In views:**
```cfm
<cfif hasWebsitePermission("comments.add")>
    <a href="#addCommentUrl#">Add Comment</a>
</cfif>
```

**In services:**
```cfml
property name="websitePermService" inject="websitePermissionService";

websitePermService.hasPermission(
      permissionKey = "documents.download"
    , userId        = websiteLoginService.getLoggedInUserId()
)
```

### 4. Website Login Service

```cfml
property name="websiteLoginService" inject="websiteLoginService";

// Login
var success = websiteLoginService.login(
      loginId            = rc.email
    , password           = rc.password
    , rememberLogin       = IsTrue( rc.rememberMe ?: "" )
    , rememberExpiryInDays = 30
);

// Check status
websiteLoginService.isLoggedIn()          // boolean
websiteLoginService.isAutoLoggedIn()      // boolean (from "remember me")
websiteLoginService.isImpersonated()      // boolean (admin impersonating)

// Get user
websiteLoginService.getLoggedInUserId()   // string
websiteLoginService.getLoggedInUserDetails()  // query

// Logout
websiteLoginService.logout();
```

### 5. Password Policy

```cfml
// Config.cfc
settings.passwordPolicies.website = {
      minLength      = 8
    , minUpperCase   = 1
    , minNumbers     = 1
    , minSymbols     = 0
};
```

---

## Quick Reference: Admin vs Website Permissions

| Aspect | Admin (CMS) | Website Users |
|--------|-------------|---------------|
| Checking in handler | `hasCmsPermission("key")` | `hasWebsitePermission("key")` |
| Login check | `$isAdminUserLoggedIn()` | `$isWebsiteUserLoggedIn()` |
| Access denied | `event.adminAccessDenied()` | `event.accessDenied()` |
| Service | `adminPermissionService` | `websitePermissionService` |
| Config key | `settings.adminPermissions` | `settings.websitePermissions` |
| Roles | `settings.adminRoles` | N/A (uses benefits/groups) |
| User groups | Admin User Groups | `website_benefit` object |
