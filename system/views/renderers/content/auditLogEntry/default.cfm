<cfparam name="args.action"      type="string"/>
<cfparam name="args.detail"      type="string"/>
<cfparam name="args.datecreated" type="date"/>
<cfparam name="args.known_as"    type="string"/>
<cfparam name="args.userLink"    type="string"/>

<cfscript>
	userLink  = '<a href="#args.userLink#">#args.known_as#</a>';
	message   = translateResource( uri="cms:auditTrail.#args.action#.message", data=[ userLink ] );
	iconClass = translateResource( uri="cms:auditTrail.#args.action#.iconClass" );
</cfscript>

<cfoutput>
	<cfif Len( Trim( iconClass ) )>
		<i class="fa fa-fw fa-lg #iconClass#"></i>
	</cfif>
	#message#
</cfoutput>