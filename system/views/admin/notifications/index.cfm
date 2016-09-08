<cfscript>
	topic = rc.topic ?: "";
	event.include( "/css/admin/specific/datamanager/object/" );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = "admin_notification_consumer"
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=notifications.getNotificationsForAjaxDataTables&topic=#topic#" )
		, useMultiActions = true
		, allowSearch     = false
	} );

	gridFields = [ { name="topic", sortable=true }, { name="datecreated", sortable=true }, { name="data", sortable=false } ];
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "notifications.configure" )>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-cogs"></i>&nbsp; #translateResource( uri="cms:notifications.preferences.btn" )#
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<li>
					<a href="#event.buildAdminLink( linkTo="notifications.preferences" )#" data-global-key="p">
						<i class="fa fa-fw fa-cog"></i>&nbsp; #translateResource( uri="cms:notifications.personal.preferences.btn" )#
					</a>
				</li>
				<li>
					<a href="#event.buildAdminLink( linkTo="notifications.configure" )#" data-global-key="p">
						<i class="fa fa-fw fa-cogs"></i>&nbsp; #translateResource( uri="cms:notifications.configure.btn" )#
					</a>
				</li>
			</ul>
		<cfelse>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="notifications.preferences" )#" data-global-key="p">
				<button class="btn btn-sm">
					<i class="fa fa-cog"></i>
					#translateResource( "cms:notifications.personal.preferences.btn" )#
				</button>
			</a>
		</cfif>
	</div>

	<div class="table-responsive">
		<form id="multi-action-form" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='notifications.multiAction' )#">
			<input type="hidden" name="multiAction" value="" />

			<table id="object-listing-table-admin_notification_consumer" class="table table-hover object-listing-table">
				<thead>
					<tr>
						<th class="center">
							<label>
								<input type="checkbox" class="ace" />
								<span class="lbl"></span>
							</label>
						</th>
						<cfloop array="#gridFields#" index="field">
							<th data-field="#field.name#" data-sortable="#field.sortable#">#translateResource( uri="preside-objects.admin_notification_consumer:field.#field.name#.title", defaultValue=translateResource( "cms:preside-objects.default.field.#field.name#.title" ) )#</th>
						</cfloop>
						<th>&nbsp;</th>
					</tr>
				</thead>
				<tbody data-nav-list="1" data-nav-list-child-selector="> tr > td :checkbox">
				</tbody>
			</table>

			<div class="form-actions" id="multi-action-buttons">
				<button class="btn btn-danger confirmation-prompt" type="submit" name="dismiss" disabled="disabled" data-global-key="d" title="#translateResource( 'cms:notifications.multidiscard.prompt' )#">
					<i class="fa fa-trash-o bigger-110"></i>
					Dismiss
				</button>

				<button class="btn" type="submit" name="read" disabled="disabled" data-global-key="r">
					<i class="fa fa-check bigger-110"></i>
					Mark as read
				</button>
			</div>
		</form>
	</div>
</cfoutput>