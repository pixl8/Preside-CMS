<!---@feature datamanagerWorkflow--->
<cfscript>
	diagramUrl = args.diagramUrl ?: "";
	history    = args.history ?: [];
	workflowId = args.workflowId ?: "";
	logDate    = args.history[ 1 ].dateCreated ?: "";
</cfscript>
<cfoutput>
	<div class="row">
		<div class="col-md-7">
			<div class="panel">
				<div class="panel-heading">
					<h4 class="panel-title grey">
						<i class="fa fa-fw fa-code-fork"></i>
						#translateResource( "datamanagerWorkflow:viewtab.workflow.diagram.panel.title" )#
					</h4>
				</div>
				<div class="panel-body">
					<img src="#diagramUrl#" />
				</div>
			</div>
		</div>
		<div class="col-md-5">
			<div class="panel">
				<div class="panel-heading">
					<h4 class="panel-title grey">
						<i class="fa fa-fw fa-clock-o"></i>
						#translateResource( "datamanagerWorkflow:viewtab.workflow.history.panel.title" )#
					</h4>
				</div>
				<div class="panel-body">
					<cfif not ArrayLen( history )>
						<p class="light-grey"><em>TODO: no transition history to show empty state here...</em></p>
					<cfelse>
						<div class="timeline-container">
							#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
							<div class="timeline-items">
								<cfloop array="#history#" item="ha" index="i">
									<cfif DateDiff( "d", ha.datecreated, logDate )>
										<cfset logDate = ha.datecreated />
										</div>
										#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
										<div class="timeline-items">
									</cfif>
									#renderView( view="/admin/datamanagerWorkflow/_historicAction", args={ workflowId=workflowId, action=ha } )#
								</cfloop>
							</div>
						</div>
					</cfif>
				</div>
			</div>
		</div>
	</div>
</cfoutput>