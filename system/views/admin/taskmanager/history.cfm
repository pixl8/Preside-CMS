<!---@feature admin and taskmanager--->
<cfscript>
	task        = rc.task     ?: "";
	history     = prc.history ?: QueryNew( "" );
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

	#objectDataTable(
		  objectName = "taskmanager_task_history"
		, args       = {
			  compact         = true
			, useMultiActions = false
			, allowSearch     = false
			, allowFilter     = false
		  }
	)#
</cfoutput>