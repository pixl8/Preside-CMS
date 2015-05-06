<cfscript>
	tabs               = args.tabs         ?: [];
	content            = args.content      ?: "";
	validationJs       = args.validationJs ?: "";
	formId             = args.formId       ?: "";
	defaultI18nBaseUri = args.defaultI18nBaseUri ?: "";
</cfscript>

<cfoutput>
	<cfif ArrayLen( tabs ) gt 1>
		<div class="tabbable">
			<ul class="nav nav-tabs">
				<cfset active = true />
				<cfloop array="#tabs#" index="tab">
					<cfscript>
						id = tab.id ?: CreateUUId();
						if ( Len( Trim( tab.title ?: "" ) ) ) {
							title = translateResource( uri=tab.title, defaultValue=translateResource( uri=defaultI18nBaseUri & tab.title, defaultValue=tab.title ) );
						} elseif ( Len( Trim( id ) ) ) {
							title = translateResource( uri=defaultI18nBaseUri & "tab.#id#.title", defaultValue="" );
						} else {
							title = "";
						}
					</cfscript>
					<li<cfif active> class="active"</cfif>>
						<a data-toggle="tab" href="##tab-#( id )#">#title#</a>
					</li>
					<cfset active = false />
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>

	#content#

	<cfif ArrayLen( tabs ) gt 1>
			</div>
		</div>
	</cfif>

	<cfif Len( Trim( formId ) ) and Len( Trim( validationJs ))>
		<cfsavecontent variable="validationJs">
			( function( $ ){
				$('###formId#').validate( #validationJs# );
			} )( presideJQuery );
		</cfsavecontent>
		<cfset event.includeInlineJs( validationJs ) />
	</cfif>
</cfoutput>