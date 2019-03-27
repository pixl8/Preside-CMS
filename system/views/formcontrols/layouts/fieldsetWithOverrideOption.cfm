<cfparam name="args.id"                 default="" />
<cfparam name="args.title"              default="" />
<cfparam name="args.description"        default="" />
<cfparam name="args.content"            default="" />

<cfoutput>
	<fieldset<cfif Len( Trim( args.id ) )> id="fieldset-#args.id#"</cfif>>
		<cfif Len( Trim( args.title ) )>
			<h3 class="header smaller lighter green">#args.title#</h3>
		</cfif>
		<cfif Len( Trim( args.description ) )>
			<p>#args.description#</p>
		</cfif>

		<div class="row">
			<h5 class="blue col-md-1 no-padding-right text-right">#translateResource( "cms:override.option.title" )#</h5>
		</div>
		#args.content#
	</fieldset>
</cfoutput>