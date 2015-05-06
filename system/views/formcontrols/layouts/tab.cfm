<cfscript>
	id                 = args.id                 ?: CreateUUId();
	active             = args.active             ?: false;
	description        = args.description        ?: "";
	content            = args.content            ?: "";
	defaultI18nBaseUri = args.defaultI18nBaseUri ?: "";

	if ( Len( Trim( description ) ) ) {
		description = translateResource( uri=description, defaultValue=translateResource( uri=args.defaultI18nBaseUri & description, defaultValue=description ) );
	} elseif ( Len( Trim( args.id ) ) ) {
		description = translateResource( uri=defaultI18nBaseUri & "tab.#id#.description", defaultValue="" );
	} else {
		description = "";
	}
</cfscript>

<cfoutput>
	<div id="tab-#id#" class="tab-pane<cfif active> active</cfif>">
		<cfif Len( Trim( description ) )>
			<p>#description#</p>
		</cfif>

		#content#
	</div>
</cfoutput>