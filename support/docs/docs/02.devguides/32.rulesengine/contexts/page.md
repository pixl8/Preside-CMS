---
id: rulesenginecontexts
title: Rules engine contexts
---

## Creating custom contexts

Rules engine contexts are created and defined in `Config.cfc`, should have `i18n` label entries in `/i18n/rules/contexts.properties` and optionally provide a convention based handler for getting the context payload.


## Config.cfc definition

Here is the core configuration in `Config.cfc$configure()` for contexts:

```luceescript
settings.rulesEngine = { contexts={} };
settings.rulesEngine.contexts.webrequest = { subcontexts=[ "user", "page" ] };
settings.rulesEngine.contexts.page       = { object="page" };
settings.rulesEngine.contexts.user       = { object="website_user" };
``` 

### Contexts with subcontexts

Notice how the `webrequest` context is made up of two subcontexts, `page` and `user`. In theory, this can be endlessly nested, though the practical uses of that may be limited. The idea here is that contexts like `webrequest` want payloads from other sources such as page, currently logged-in user, and perhaps form builder form submission (in the future).

### Context object

If a context defines an object, it is expected that this context should work with _filters_ that are saved against the object. Also, it is expected that the payload for the context be a structure with a single key whose name is the object. e.g. the payload for `user` context should look like this:

```luceescript
userContext = { 
	website_user = {
		  id           = '...'
		, display_name = 'bob'
		, ...
	} 
}
```

If no object is defined, and the name of the context is an existing object, the context name will be used as a default.

## i18n labelling

i18n properties for contexts live at `/i18n/rules/contexts.properties` and look like this:

```properties
webrequest.title=Web request
webrequest.description=Conditions that apply to a web page request (includes user and web page expressions)
webrequest.iconClass=fa-globe

page.title=Web page
page.description=Conditions that apply to a site tree page
page.iconClass=fa-file-o

user.title=User
user.description=Conditions that apply to a user
user.iconClass=fa-user
```

Each context should have a `title`, `description` and `iconclass` key prefixed with `{contextid}.`.

## Handler

To supply the logic for retrieving a context payload when evaluating a condition, you must implement a handler at `/handlers/rules/contexts/{contextId}.cfc`. e.g. for the `page` context, we implement `/handlers/rules/contexts/Page.cfc`. The handler needs to supply a single method that returns a struct. For example, our core `page` handler looks like this:

```luceescript
/**
 * Handler for the page rules engine context
 *
 */
component {

	private struct function getPayload() {
		return { page = ( prc.presidePage ?: {} ) };
	}

}
```

Notice how we return a struct with a single key, `page`. This is important as it isolates the payload so that we can combine payloads for contexts that consist of multiple other contexts.

