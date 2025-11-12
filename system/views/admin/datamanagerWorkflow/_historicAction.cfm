<!---@feature datamanagerWorkflow--->
<cfscript>
	flowI18n   = "datamanagerWorkflow.#args.workflowId#:";
	stepI18n   = Len( args.action.step ) ? "#flowI18n#step.#args.action.step#" : "#flowI18n#initial";
	actionI18n = stepI18n & ".action.#args.action.action#";
</cfscript>
<cfoutput>
	<div class="timeline-item clearfix" data-date="#args.action.datecreated#">
		<div class="timeline-info">
			<span class="label label-info label-sm">#TimeFormat( args.action.datecreated, "HH:mm" )#</span>
		</div>
		<div class="widget-box transparent">
			<div class="widget-header widget-header-small">
				<h5 class="widget-title smaller">
					<i class="fa fa-fw #translateResource( uri="#actionI18n#.iconClass", defaultResult="fa-play" )#"></i>

					#translateResource( uri="#actionI18n#.title", defaultValue=args.action.action )#
				</h5>

				<cfif Len( args.action.triggered_by_admin_user )>
					<span class="widget-toolbar no-border">
						#renderContent( "adminUser", args.action.triggered_by_admin_user, "admindatatable" )#
					</span>
				<cfelse>
					<!--- todo: render web user or system view --->
				</cfif>
			</div>

			<div class="widget-body">
				<div class="widget-main">
					<cfif ArrayLen( args.action.transitions )>
						<ul class="list-unstyled">
							<cfloop array="#args.action.transitions#" item="t">
								<li>
									<strong>#translateResource( uri=flowI18n & "step.#t.step#.title", defaultValue=t.step )#</strong>:
									<strike>#renderEnum( t.old_status, "cfflowstepstatus" )#</strike>
									&rarr;
									#renderEnum( t.status, "cfflowstepstatus" )#
								</li>
							</cfloop>
						</ul>
					</cfif>
				</div>
			</div>
		</div>
	</div>
</cfoutput>