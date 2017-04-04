---
id: rulesenginecontexts
title: Rules engine contexts
---

## Creating custom contexts

Context are loosely defined. They are nothing more than an entry in `Config.cfc` and some resource properties. The contract that says that a particular context expects a particular payload is entirely up to the developer to honour. You can configure a new context and then use the service APIs directly to evaluate conditions against those new contexts.

Here is the core configuration in `Config.cfc$configure()` for contexts:

```luceescript
settings.rulesEngine = { contexts={} };
settings.rulesEngine.contexts.webrequest = { subcontexts=[ "user", "page" ] };
settings.rulesEngine.contexts.page       = {};
settings.rulesEngine.contexts.user       = {};
``` 

Notice how contexts can define an array of subcontexts. This is the full extent of what is configurable in `Config.cfc`. i18n properties for contexts live at `/i18n/rules/contexts.properties` and look like this:

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