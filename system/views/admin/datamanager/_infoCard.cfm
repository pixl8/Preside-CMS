<!---@feature admin--->
<cfscript>
	args.col1            = args.col1 ?: [];
	args.col2            = args.col2 ?: [];
	args.col3            = args.col3 ?: [];
	args.infoDescription = args.infoDescription ?: "";
	args.infoColSizes    = args.infoColSizes ?: [ 4, 4, 4 ];
</cfscript>

<cfoutput>
	<div class="view-record-detail-card">
		<cfif args.infoDescription.len()>
			#args.infoDescription#
			<hr>
		</cfif>

		<div class="row">
			<cfloop from="1" to="3" index="i">
				<cfif args.infoColSizes[ i ]>
					<div class="col-md-#args.infoColSizes[ i ]#">
						<ul class="list-unstyled">
							<cfloop array="#args[ 'col#i#' ]#" index="n" item="item">
								<li>#item#</li>
							</cfloop>
						</ul>
					</div>
				</cfif>
			</cfloop>
		</div>
	</div>
</cfoutput>