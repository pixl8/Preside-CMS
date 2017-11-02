<cfscript>
	renderedProps = args.renderedProps ?: [];
	title         = args.title         ?: "";
	iconClass     = args.iconClass     ?: "";
</cfscript>

<cfoutput>
	<div class="col-lg-6">
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

					<dl class="dl-horizontal">
						<cfloop array="#renderedProps#" item="prop" index="i">
							<dt>#prop.propertyTitle#</dt>
							<dd>#prop.rendered#</dd>
						</cfloop>
					</dl>
				</div>
			</div>
		</div>
	</div>
</cfoutput>