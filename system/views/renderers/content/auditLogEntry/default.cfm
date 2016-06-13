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