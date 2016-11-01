<cfscript>
	task        = rc.task ?: "";
	history     = prc.history ?: QueryNew('');
	canRunTasks = hasCmsPermission( "taskmanager.run" );
	isRunning   = history.recordCount && IsFalse( history.complete[1] );
</cfscript>

<cfoutput>
	<cfif canRunTasks>
		<div class="top-right-button-group">
			<a id="run-task-btn" class="pull-right inline btn btn-info btn-sm<cfif isRunning> btn-disabled</cfif>" href="#event.buildAdminLink( linkTo="taskmanager.runTaskAction", queryString="task=#task#" )#" data-global-key="r" <cfif isRunning> disabled</cfif>>
				<i class="fa fa-rotate-right"></i>
				#translateResource( uri="cms:taskmanager.run.btn" )#
			</a>
		</div>
	</cfif>

	<table class="table table-striped table-hover">
		<thead>
			<tr>
				<th>#translateResource( "cms:taskmanager.history.table.header.success" )#</th>
				<th>#translateResource( "cms:taskmanager.history.table.header.daterun" )#</th>
				<th>#translateResource( "cms:taskmanager.history.table.header.timetaken" )#</th>
				<th>#translateResource( "cms:taskmanager.history.table.header.log" )#</th>
			</tr>
		</thead>
		<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			<cfloop query="history">
				<tr class="clickable" data-context-container="1">
					<td>
						<cfif IsTrue( history.complete )>
							#renderField( object='taskmanager_task_history', property="success"    , data=history.success    , context=[ "taskhistory", "admindatatable", "admin" ] )#
						<cfelse>
							<i class="fa fa-refresh grey"></i>
						</cfif>

					</td>
					<td>#renderField( object='taskmanager_task_history', property="datecreated", data=history.datecreated, context=[ "taskhistory", "admindatatable", "admin" ] )#</td>
					<td>
						<cfif IsTrue( history.complete )>
							#renderField( object='taskmanager_task_history', property="time_taken" , data=history.time_taken , context=[ "taskhistory", "admindatatable", "admin" ] )#
						<cfelse>
							<i class="fa fa-refresh grey"></i>
							<em>#renderField( object='taskmanager_task_history', property="time_taken" , data=( DateDiff( 's', history.datecreated, Now() ) * 1000 ), context=[ "taskhistory", "admindatatable", "admin" ] )#</em>
						</cfif>
					</td>
					<td>
						<a href="#event.buildAdminLink( linkTo='taskmanager.log', queryString='id=#history.id#' )#" data-context-key="l">
							<i class="fa fa-file-text-o fa-fw"></i>
							#translateResource( "cms:taskmanager.history.viewlog.link" )#
						</a>
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfoutput>