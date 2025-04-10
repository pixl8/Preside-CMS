<!---@feature formbuilder--->
<cfscript>
	label      = args.label      ?: "";
	pageNumber = args.pageNumber ?: 1;
	pageTotal  = args.pageTotal  ?: 1;
</cfscript>

<cfoutput>
	<cfif pageNumber eq 1>
		<div class="formbuilder-page">
	<cfelse>
			<div>
				<button type="button">Prev</button>
				<button type="button">Next</button>
			</div>
		</div>

		<div class="formbuilder-page">
	</cfif>

	<cfif not isEmptyString( label )>
		<h2 class="formbuilder-page-heading">#pageNumber#  #label#</h2>
	</cfif>
</cfoutput>