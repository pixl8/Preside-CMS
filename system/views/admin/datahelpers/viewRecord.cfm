<cfscript>
	leftCol  = args.leftCol  ?: "";
	rightCol = args.rightCol ?: "";
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-md-6">
			#leftCol#
		</div>
		<div class="col-md-6">
			#rightCol#
		</div>
	</div>
</cfoutput>