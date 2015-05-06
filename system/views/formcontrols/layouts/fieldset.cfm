<cfparam name="args.id"                 default="" />
<cfparam name="args.title"              default="" />
<cfparam name="args.description"        default="" />
<cfparam name="args.content"            default="" />
<cfparam name="args.defaultI18nBaseUri" default="" />

<cfscript>
	if ( Len( Trim( args.title ) ) ) {
		title = translateResource( uri=args.title, defaultValue=translateResource( uri=args.defaultI18nBaseUri & args.title, defaultValue=args.title ) );
	} elseif ( Len( Trim( args.id ) ) ) {
		title = translateResource( uri=args.defaultI18nBaseUri & "fieldset.#args.id#.title", defaultValue="" );
	} else {
		title = "";
	}

	if ( Len( Trim( args.description ) ) ) {
		description = translateResource( uri=args.description, defaultValue=translateResource( uri=args.defaultI18nBaseUri & args.description, defaultValue=args.description ) );
	} elseif ( Len( Trim( args.id ) ) ) {
		description = translateResource( uri=args.defaultI18nBaseUri & "fieldset.#args.id#.description", defaultValue="" );
	} else {
		description = "";
	}
</cfscript>
<cfoutput>
	<fieldset<cfif Len( Trim( args.id ) )> id="fieldset-#args.id#"</cfif>>
		<cfif Len( Trim( title ?: "" ) )>
			<h3 class="header smaller lighter green">#title#</h3>
		</cfif>
		<cfif Len( Trim( description ) )>
			<p>#description#</p>
		</cfif>

		#args.content#
	</fieldset>
</cfoutput>