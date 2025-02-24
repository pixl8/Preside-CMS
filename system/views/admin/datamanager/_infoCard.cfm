<!---@feature admin--->
<cfscript>
	args.col1            = args.col1 ?: [];
	args.col2            = args.col2 ?: [];
	args.col3            = args.col3 ?: [];
	args.infoDescription = args.infoDescription ?: "";
	args.infoColSizes    = args.infoColSizes ?: [ 4, 4, 4 ];
	args.infoCardStyle   = args.infoCardStyle  ?: "default"; // default, or definitionList
</cfscript>

<cfoutput>
	<div class="view-record-detail-card">
		<cfif Len( args.infoDescription )>
			#args.infoDescription#
			<hr>
		</cfif>

		<div class="row">
			<cfloop from="1" to="3" index="i">
				<cfif args.infoColSizes[ i ]>
					<div class="col-md-#args.infoColSizes[ i ]#">
						<cfif args.infoCardStyle == "definitionList">
							<dl class="info-card-dl">
						<cfelse>
							<ul class="list-unstyled">
						</cfif>

						<cfloop array="#args[ 'col#i#' ]#" index="n" item="item">
							<cfif args.infoCardStyle == "definitionList">
								<dt>#item.title#</dt>
								<dd>#item.value#</dd>
							<cfelse>
								<li>#item#</li>
							</cfif>
						</cfloop>

						<cfif args.infoCardStyle == "definitionList">
							</dl>
						<cfelse>
							</ul>
						</cfif>

					</div>
				</cfif>
			</cfloop>
		</div>
	</div>
</cfoutput>