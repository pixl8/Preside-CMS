---
id: csrf
title: CSRF Protection
---

The Preside platform comes with built-in CSRF protection for the admin application and provides APIs for making use of CSRF protection for your front end applications.

For more information on the CSRF attacks and how to prevent them, visit [https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)](https://www.owasp.org/index.php/Cross-Site_Request_Forgery_\(CSRF\)).

## Built in admin protection

The system automatically adds CSRF tokens into action URLs and validates them on request **when the admin coldbox action name ends with 'action'**. For this to work, you must use `event.buildAdminLink(...)` to build your URL. For instance:

```lucee
<form action="#event.buildAdminLink( linkto='dashboard.savePreferencesAction' )#">
<!-- ... -->
</form>
```

>>> You should **always** use `event.buildLink()` or `event.buildAdminLink()` to build your URLs!

## Configuring built-in admin protection

As of Preside 10.9.0, it is possible to either turn off admin CSRF protection entirely, or configure the CSRF token timeout. Both are configured in your application's `Config.cfc` file:

```luceescript
// turn off the feature altogether
settings.features.adminCsrfProtection.enabled = false;

// or, configure a different timeout
settings.csrf.tokenExpiryInSeconds = 60 * 60; // 1 hour expiry (default 20m)
```

## Using APIs for custom CSRF protection in your frontend applications

You can use `event.getCsrfToken()` and `event.validateCsrfToken()` to get and validate tokens in your requests. For example, you may have a custom frontend form that looks like this:

```lucee
<form action="#saveDetailsAction#" method="post">
	<input type="hidden" name="csrfToken" value="#event.getCsrfToken()#">
	<!-- ... -->
</form>
```

Then, in your "saveDetailsAction" handler:

```luceescript
function saveDetails( event, rc, prc ) {
	var requestData = event.getCollectionWithoutSystemVars();

	if ( !event.validateCsrfToken() ) {
		requestData.errorMessage = translateResource( "myapp:invalid.csrf.token.error" );
		
		setNextEvent( url=editDetailsUrl, persistStruct=requestData );
	}
}
```