<cfscript>
	diagramUrl      = args.diagramUrl      ?: "";
	objectName      = args.objectName      ?: "";
	instanceHistory = args.instanceHistory ?: "";
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-md-6">
			<div class="panel">
				<div class="panel-heading">
					<h4 class="panel-title grey">
						<i class="fa fa-fw fa-code-fork"></i>
						#translateResource( uri="adminui:webflow.flow.diagram.heading" )#
					</h4>
				</div>
				<div class="panel-body">
					<cfif Len( diagramUrl )>
						<div class="text-center">
							<img src="#diagramUrl#" />
						</div>
					<cfelse>
						<p class="alert alert-warning">
							#translateResource( uri="adminui:webflow.flow.diagram.empty.message" )#
						</p>
					</cfif>
				</div>
			</div>
		</div>

		<div class="col-md-6">
			<div class="panel">
				<div class="panel-heading">
					<h4 class="panel-title grey">
						<i class="fa fa-fw fa-clock-o"></i>
						#translateResource( uri="adminui:webflow.flow.history.heading" )#
					</h4>
				</div>
				<div class="panel-body">
					<cfif Len( instanceHistory )>
						#instanceHistory#
					<cfelse>
						<p class="alert alert-warning">
							#translateResource( uri="adminui:webflow.flow.history.empty.message" )#
						</p>
					</cfif>
				</div>
			</div>
		</div>
	</div>
</cfoutput>