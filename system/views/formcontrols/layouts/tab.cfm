<cfscript>
	id          = args.id          ?: CreateUUId();
	active      = args.active      ?: false;
	description = args.description ?: "";
	content     = args.content     ?: "";
</cfscript>

<cfoutput>
	<div id="tab-#id#" class="tab-pane<cfif active> active</cfif>">
		<cfif Len( Trim( description ) )>
			<p>#description#</p>
		</cfif>

		#content#
	</div>
</cfoutput>