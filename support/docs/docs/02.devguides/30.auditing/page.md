---
id: auditing
title: Using the audit trail system
---

As of v10.7.0, PresideCMS comes with an audit trail system that allows you to log the activity of your admin users and display that activity in the admin:

![Screenshot showing audit trail in action](images/screenshots/auditTrail.png)

## Creating log entries

You can log an activity in one of two ways:

```luceescript
// in a handler
event.audit(
	  action   = "datamanager_translate_record"
	, type     = "datamanager"
	, recordId = recordId
	, detail   = updatedData
);

// from a service using Preside Super class
$audit(
	  action   = "slack_command_executed"
	, type     = "slackcommands"
	, detail   = { command="deploy", commandArgs=commandArgs }
);
```

Both of these methods proxy to the [[auditservice-log]] method of the [[api-auditservice]] (see links for docs).

## Rendering log entries

For an audit log entry to appear in a useful way for the user, you will want to:

1. Provide i18n properties file entries to describe the audit type and action
2. Provide a custom renderer context for either your audit type or action

### i18n

Each audit "type" should have its own `.properties` file that lives at `/i18n/auditlog/{type}.properties`, e.g. `/i18n/auditlog/datamanager.properties`. At a minimum, it should contain a `title` and `iconClass` entry:

```properties
title=Data manager
iconClass=fa-puzzle-piece
```

In addition, for each audit _action_ within the type, you should supply a `{action}.title`, `{action}.message` and `{action}.iconClass` entry:

```properties
title=Data manager
iconClass=fa-puzzle-piece

datamanager_add_record.title=Add record (Data manager)
datamanager_add_record.message={1} created a new {2}, {3}
datamanager_add_record.iconClass=fa-plus-circle green

datamanager_delete_record.title=Delete record (Data manager)
datamanager_delete_record.message={1} deleted {2}, {3}
datamanager_delete_record.iconClass=fa-trash red
```

### Audit log entry renderer

When audit log entries are rendered, the system uses the `AuditLogEntry` content renderer. It uses the audit log _type_ and/or _action_ as the _context_ for the renderer. This means that the audit log entry will be rendered by one of the following viewlets (whichever exists):

* `renderers.content.AuditLogEntry.{action}`
* `renderers.content.AuditLogEntry.{type}`
* `renderers.content.AuditLogEntry.default`

The _default_ context renderer looks like this:

```lucee
<cfparam name="args.type"        type="string"/>
<cfparam name="args.action"      type="string"/>
<cfparam name="args.datecreated" type="date"/>
<cfparam name="args.known_as"    type="string"/>
<cfparam name="args.userLink"    type="string"/>

<cfscript>
	userLink  = '<a href="#args.userLink#">#args.known_as#</a>';
	message   = translateResource( uri="auditlog.#args.type#:#args.action#.message", data=[ userLink ] );
</cfscript>

<cfoutput>
	#message#
</cfoutput>
```

This means that you can use the default renderer if your audit message could look like this:

```properties
myaction.message={1} did some really cool action
```

If you need a more detailed message, for example: you'd like to replay the *slack command* that was entered in a slack command hook, then you can create a _custom_ context for either your audit type or category. e.g.


```lucee
<!-- /views/renderers/content/auditLogEntry/slackcommand.cfm -->
<cfscript>
	action   = args.action   ?: "";
	known_as = args.known_as ?: "";
	detail   = args.detail   ?: {};
	userLink = '<a href="#( args.userLink ?: '' )#">#args.known_as#</a>';
	command  = '<code>/#( detail.command ?: '' )# #( detail.commandArgs ?: '' )#</code>';

	message = translateResource( uri="auditlog.slackcommand:#args.action#.message", data=[ userLink, command ] );
</cfscript>

<cfoutput>#message#</cfoutput>
```

```properties
# /i18n/auditlog/slackcommand.properties
title=Slack commands
iconClass=fa-slack

command_sent.title=Slack command issued
command_sent.message={1} has issued a command from Slack: {2}
command_sent.iconClass=fa-slack blue
```