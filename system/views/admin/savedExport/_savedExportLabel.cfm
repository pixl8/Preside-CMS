<cfscript>
	icon        = args.icon        ?: "fa-database";
	label       = args.label       ?: "";
	description = args.description ?: "";
</cfscript>

<cfoutput>
	<div class="row no-padding">
		<div class="col-md-1 text-center">
			<i class='fa-fw fa #icon#'></i>
		</div>

		<div class="col-md-11">
			<strong>#label#</strong>

			<cfif !isEmptyString( description )>
				<p>#description#</p>
			</cfif>
		</div>
	</div>
</cfoutput>