# REST API Framework

## Configuration

```cfml
// Config.cfc
settings.rest.path = "/api";  // Default — all REST APIs under /api/

// CORS per API:
settings.rest.apis[ "/my-api/v1" ] = {
      corsEnabled        = true
    , corsAllowedOrigins = [ "*" ]
    , corsAllowedHeaders = [ "Authorization", "Content-Type" ]
};
```

---

## Resource Handlers

REST resources live in `/handlers/rest-apis/{api-name}/{version}/`.

### Basic Resource

```cfml
// /handlers/rest-apis/my-api/v1/Events.cfc

/**
 * @restUri /events/,/events/{id}/
 */
component {

    property name="eventDao" inject="presidecms:object:event";

    // Maps to GET /api/my-api/v1/events/ and GET /api/my-api/v1/events/{id}/
    private void function get( string id="" ) {
        if ( Len( Trim( arguments.id ) ) ) {
            var record = eventDao.selectData(
                  selectFields = [ "id", "title", "start_date", "location" ]
                , filter       = { id=arguments.id }
            );
            if ( !record.recordCount ) {
                restResponse.setStatus( 404, "Not Found" ).noData();
                return;
            }
            restResponse.setData( QueryGetRow( record, 1 ) ).setStatus( 200 );
        } else {
            var records = eventDao.selectData(
                  selectFields = [ "id", "title", "start_date" ]
                , filter       = { published=true }
                , orderBy      = "start_date asc"
            );
            restResponse.setData( QueryToArray( records ) ).setStatus( 200 );
        }
    }

    // Maps to POST /api/my-api/v1/events/
    private void function post() {
        var data = deserializeJSON( getHttpRequestData().content );
        var newId = eventDao.insertData( data=data );

        restResponse
            .setData({ id=newId })
            .setStatus( 201, "Created" )
            .setHeader( "Location", "/api/my-api/v1/events/#newId#/" );
    }

    // Maps to PUT /api/my-api/v1/events/{id}/
    private void function put( required string id ) {
        var data = deserializeJSON( getHttpRequestData().content );
        eventDao.updateData( data=data, filter={ id=arguments.id } );
        restResponse.setStatus( 200 ).noData();
    }

    // Maps to DELETE (method name doesn't match HTTP verb — use @restVerb)
    /**
     * @restVerb DELETE
     */
    private void function deleteEvent( required string id ) {
        eventDao.deleteData( filter={ id=arguments.id } );
        restResponse.setStatus( 200 ).noData();
    }
}
```

URL pattern: `/api/{api-name}/{version}/{restUri}`
→ `/api/my-api/v1/events/` or `/api/my-api/v1/events/abc123/`

---

## restResponse Object

```cfml
restResponse.setData( myStruct )              // Response body (auto-serialized to JSON)
restResponse.setData( queryToArray( query ) ) // Arrays work too
restResponse.noData()                         // No response body
restResponse.setStatus( 200, "OK" )           // HTTP status code + message
restResponse.setStatus( 404, "Not Found" )
restResponse.setStatus( 422, "Unprocessable Entity" )
restResponse.setHeader( "X-Custom-Header", "value" )
restResponse.setMimeType( "application/json" )  // Default
restResponse.setRenderer( "myCustomRenderer" )
restResponse.setError(
      errorCode = "INVALID_INPUT"
    , message   = "The submitted data is invalid"
    , detail    = { field="title", issue="required" }
)
```

---

## restRequest Object

```cfml
restRequest.getUser()    // Authenticated user ID (set by auth provider)
restRequest.getApi()     // API identifier (e.g. "/my-api/v1")
restRequest.finish()     // Stop processing, send current response
```

---

## Authentication

Auth providers live at `/handlers/rest/auth/{providerId}.cfc`.

### Token-Based Auth Provider

```cfml
// /handlers/rest/auth/token.cfc
component {

    property name="apiAuthService" inject="apiAuthService";

    // Return the user ID if authenticated, or empty string
    private string function authenticate() {
        var headers     = getHttpRequestData( false ).headers;
        var authHeader  = headers.Authorization ?: "";

        if ( !authHeader.startsWith("Bearer ") ) {
            return "";
        }

        var token  = Mid( authHeader, 8, Len(authHeader) );
        var userId = apiAuthService.getUserByToken( token );

        if ( !Len( userId ) ) {
            restResponse.setStatus( 401, "Unauthorized" );
            restRequest.finish();
        }

        return userId;
    }
}
```

### Configuring Auth Per API

```cfml
// Config.cfc
settings.rest.apis[ "/my-api/v1" ] = {
    authProvider = "token"  // References /handlers/rest/auth/token.cfc
};
```

### Accessing Authenticated User

```cfml
private void function get( string id="" ) {
    var currentUserId = restRequest.getUser();
    // Returns empty string if not authenticated
}
```

---

## Interception Points

```cfml
component extends="coldbox.system.Interceptor" {
    public void function configure() {}

    // At start of every REST request
    public void function onRestRequest( event, interceptData ) {
        // interceptData.restRequest, interceptData.restResponse
    }

    // On unhandled exception
    public void function onRestError( event, interceptData ) {
        // interceptData.error, interceptData.restRequest, interceptData.restResponse
        restResponse.setStatus( 500, "Server Error" )
            .setError( errorCode="INTERNAL_ERROR", message=interceptData.error.message );
    }

    // When no matching resource found
    public void function onMissingRestResource( event, interceptData ) {
        restResponse.setStatus( 404, "Not Found" ).noData();
    }

    // Before/after invoking the resource action
    public void function preInvokeRestResource( event, interceptData ) {}
    public void function postInvokeRestResource( event, interceptData ) {}
}
```

---

## ETag Caching

GET and HEAD responses automatically support ETag-based caching:
- Response includes `ETag` header (hash of response data)
- If client sends `If-None-Match` header matching ETag → returns `304 Not Modified`

No code needed; handled automatically by the framework.

---

## URL Structure

```
/api/{api-name}/{version}/{restUri}

Examples:
GET  /api/my-api/v1/events/
GET  /api/my-api/v1/events/abc123/
POST /api/my-api/v1/events/
PUT  /api/my-api/v1/events/abc123/
DELETE /api/my-api/v1/events/abc123/

GET  /api/my-api/v1/events/abc123/attendees/
POST /api/my-api/v1/events/abc123/attendees/
```

The `@restUri` annotation supports multiple patterns and path params:
```cfml
/**
 * @restUri /events/,/events/{id}/,/events/{id}/attendees/
 */
component { ... }
```

Path parameter names must match function argument names:
```cfml
private void function get( string id="", string attendeeId="" ) { ... }
```

---

## Error Handling

```cfml
// Return validation errors:
private void function post() {
    var data = deserializeJSON( getHttpRequestData().content );
    var vr   = validateForm( "my.form", data );

    if ( !vr.validated() ) {
        restResponse.setStatus( 422, "Unprocessable Entity" ).setError(
              errorCode = "VALIDATION_ERROR"
            , message   = "The submitted data failed validation"
            , detail    = vr.getErrors()
        );
        return;
    }
    // ... create record
}

// Not found:
if ( !record.recordCount ) {
    restResponse.setStatus( 404, "Not Found" ).noData();
    return;
}

// Unauthorized:
if ( !restRequest.getUser().len() ) {
    restResponse.setStatus( 401, "Unauthorized" ).noData();
    restRequest.finish();
}

// Forbidden:
if ( !hasPermission( restRequest.getUser(), "events.delete" ) ) {
    restResponse.setStatus( 403, "Forbidden" ).noData();
    return;
}
```
