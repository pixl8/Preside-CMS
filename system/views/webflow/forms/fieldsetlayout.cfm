<!---@feature webflow--->
<cfparam name="args.id"                 default="" />
<cfparam name="args.title"              default="" />
<cfparam name="args.description"        default="" />
<cfparam name="args.content"            default="" />

<cfoutput>
	<cfif args.content.trim().len()>
		<fieldset<cfif Len( Trim( args.id ) )> id="fieldset-#args.id#"</cfif>>
			<cfif Len( Trim( args.title ) )>
				<h3>#args.title#</h3>
			</cfif>
			<cfif Len( Trim( args.description ) )>
				<cfif args.description contains "<p>">
					#args.description#
				<cfelse>
					<p>#args.description#</p>
				</cfif>
			</cfif>

			#args.content#
		</fieldset>
	</cfif>
</cfoutput>