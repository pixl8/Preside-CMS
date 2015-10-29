<cfif thisTag.executionMode == "start">
	<cfparam name="attributes.name"     type="string" />
	<cfparam name="attributes.type"     type="string"  default="any" />
	<cfparam name="attributes.field"    type="string"  default="" />
	<cfparam name="attributes.renderer" type="string"  default="" />
	<cfparam name="attributes.editable" type="boolean" default="false" />

	<cfif !IsDefined( "caller.#attributes.name#" )>
		<cfthrow type="presidecms.missing.param" message="The parameter [#attributes.name#] could not be found. If you are renderering a Preside Object View and have just added this parameter - you may need to reload the application to clear the system's caches." />
	<cfelseif attributes.type != "any" && attributes.type.len() && !IsValid( attributes.type, Evaluate( "caller.#attributes.name#" ) )>
		<cfthrow type="presidecms.bad.param" message="The parameter [#attributes.name#] is not of type [#attributes.type#]." />
	</cfif>
</cfif>