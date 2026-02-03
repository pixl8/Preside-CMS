<!---@feature admin--->
<cfscript>
	renderedProps = args.renderedProps ?: [];
	title         = args.title         ?: "";
	iconClass     = args.iconClass     ?: "";
</cfscript>

<cfoutput>
	<div class="widget-box">
		<div class="widget-header">
			<h4 class="widget-title lighter smaller">
				<cfif iconClass.len()>
					<i class="fa fa-fw #iconClass#"></i>
				</cfif>
				#title#
			</h4>
		</div>

		<div class="widget-body">
			<div class="widget-main padding-20">
				<div class="table-responsive-lg">
 					<table class="table table-condensed table-no-header table-non-clickable table-admin-view-record">
 						<tbody>
							<cfloop array="#renderedProps#" item="prop" index="i">
								<tr>
									<cfif isTrue( prop.displayTitle ?: true )>
										<th>#prop.propertyTitle#:</th>
									</cfif>
									<td>#prop.rendered#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</cfoutput>