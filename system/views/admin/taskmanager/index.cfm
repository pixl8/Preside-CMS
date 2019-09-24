<cfscript>
	taskGroups        = prc.taskGroups      ?: [];
	activeTaskGroup   = prc.activeTaskGroup ?: 1;
	tasksEnabled      = IsTrue( prc.autoRunningEnabled ?: false );

	canRunTasks       = hasCmsPermission( "taskmanager.run"          );
	canToggleActive   = tasksEnabled && hasCmsPermission( "taskmanager.toggleactive" );
	canConfigure      = hasCmsPermission( "taskmanager.configure" );
	canViewLogs       = hasCmsPermission( "taskmanager.viewlogs"     );
	showActionsColumn =  canRunTasks || canToggleActive || canViewLogs;

</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "taskmanager.configure" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="taskmanager.configure" )#" data-global-key="c">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-cogs"></i>
					#translateResource( uri="cms:taskmanager.configure.btn" )#
				</button>
			</a>
		</cfif>
	</div>

	<cfif tasksEnabled>
		<div class="alert alert-info">
			<p>
				<i class="fa fa-check fa-lg"></i>
				#translateResource( 'cms:taskmanager.tasksenabled.message' )#
			</p>
		</div>
	<cfelse>
		<div class="alert alert-danger">
			<p>
				<i class="fa fa-warning fa-lg"></i>
				#translateResource( 'cms:taskmanager.tasksdisabled.message' )#
			</p>
		</div>
	</cfif>

	<cfif taskGroups.len() gt 1>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<cfloop array="#taskGroups#" index="i" item="group">
					<li<cfif i==activeTaskGroup> class="active"</cfif>>
						<a data-toggle="tab" href="##group-tab-#i#" class="task-manager-tab" data-tab-id="#group.slug#">
							<i class="fa fa-fw #group.iconClass#"></i>
							#group.title# (#group.stats.total#)
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>

	<cfloop array="#taskGroups#" index="i" item="group">
		<cfif taskGroups.len() gt 1>
			<div id="group-tab-#i#" class="tab-pane<cfif i==activeTaskGroup> active</cfif>">
		</cfif>

		<table class="table table-striped table-hover">
			<thead>
				<tr>
					<th>#translateResource( "cms:taskmanager.table.header.task" )#</th>
					<th>#translateResource( "cms:taskmanager.table.header.schedule" )#</th>
					<th>#translateResource( "cms:taskmanager.table.header.lastrun" )#</th>
					<th>#translateResource( "cms:taskmanager.table.header.nextrun" )#</th>
					<th>#translateResource( "cms:taskmanager.history.table.header.timetaken" )#</th>
					<cfif showActionsColumn>
						<th>#translateResource( "cms:taskmanager.table.header.actions" )#</th>
					</cfif>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
				<cfloop array="#group.tasks#" index="i" item="task">
					<tr class="clickable" data-context-container="1">
						<td title="#htmlEditFormat( task.description )#">
							#renderContent( 'boolean', task.enabled, [ "adminDataTable", "admin" ] )#
							&nbsp;
							#task.name#
						</td>
						<td>
							<cfif IsTrue( task.isScheduled )>
								#task.schedule#
							<cfelse>
								<em class="grey">#translateResource( "cms:taskmanager.task.schedule.disabled" )#</em>
							</cfif>
						</td>
						<td>
							<cfif task.is_running>
								<i class="fa fa-rotate-right grey"></i>
								&nbsp;
								<em>#translateResource( "cms:taskmanager.table.task.running" )#</em>
								&ndash;
								<a href="#event.buildAdminLink( linkTo="taskManager.viewLog", queryString='id=#task.taskHistoryId#')#">
									#translateResource( "cms:taskmanager.table.task.viewlog" )#
								</a>

							<cfelse>
								#renderContent( 'boolean', task.was_last_run_success, [ "adminDataTable", "admin" ] )#
								&nbsp;
								#renderContent( 'datetime', task.last_ran )#
							</cfif>
						</td>
						<td>
							<cfif tasksEnabled && task.enabled>
								<cfif IsTrue( task.isScheduled )>
									#renderContent( 'datetime', task.next_run )#
								<cfelse>
									<em class="grey">#translateResource( "cms:taskmanager.task.schedule.disabled" )#</em>
								</cfif>
							<cfelse>
								<em class="grey">#translateResource( "cms:taskmanager.table.task.disabled" )#</em>
							</cfif>
						</td>
						<td>
							<cfif IsTrue( task.was_last_run_success )>
								#renderField( object='taskmanager_task_history', property="time_taken" , data=task.last_run_time_taken , context=[ "taskhistory", "admindatatable", "admin" ] )#
							</cfif>
						</td>
						<cfif showActionsColumn>
							<td>
								<div class="action-buttons btn-group">
									<cfif canViewLogs>
										<a href="#event.buildAdminLink( linkTo='taskmanager.history', queryString='task=' & task.task_key )#" data-context-key="h">
											<i class="fa fa-fw fa-file-text-o green"></i>
										</a>
									</cfif>

									<cfif canConfigure>
										<cfif IsTrue( task.isScheduled )>
											<a href="#event.buildAdminLink( linkTo='taskmanager.configureTask', queryString='task=' & task.task_key )#" data-context-key="c">
												<i class="fa fa-fw fa-cog grey"></i>
											</a>
										<cfelse>
											<a disabled><i class="fa fa-fw fa-cog grey disabled"></i></a>
										</cfif>
									</cfif>

									<cfif canToggleActive>
										<cfif task.enabled>
											<a href="#event.buildAdminLink( linkTo='taskmanager.disableTaskAction', queryString='task=' & task.task_key )#" data-context-key="p">
												<i class="fa fa-fw fa-pause red"></i>
											</a>
										<cfelse>
											<a href="#event.buildAdminLink( linkTo='taskmanager.enableTaskAction', queryString='task=' & task.task_key )#" data-context-key="p">
												<i class="fa fa-fw fa-play green"></i>
											</a>
										</cfif>
									</cfif>

									<cfif canRunTasks>
										<cfif task.is_running>
											<a href="#event.buildAdminLink( linkTo='taskmanager.killRunningTaskAction', queryString='task=' & task.task_key )#" data-context-key="k" class="confirmation-prompt" title="#HtmlEditFormat( translateResource( 'cms:taskmanager.killtask.prompt' ) )#">
												<i class="fa fa-fw fa-plug red"></i>
											</a>
										<cfelse>
											<a href="#event.buildAdminLink( linkTo='taskmanager.runTaskAction', queryString='task=' & task.task_key )#" data-context-key="r">
												<i class="fa fa-fw fa-rotate-right blue"></i>
											</a>
										</cfif>
									</cfif>
								</div>
							</td>
						</cfif>
					</tr>
				</cfloop>
			</tbody>
		</table>

		<cfif taskGroups.len() gt 1>
			</div>
		</cfif>
	</cfloop>
	<cfif taskGroups.len() gt 1>
			</div>
		</div>
	</cfif>
</cfoutput>