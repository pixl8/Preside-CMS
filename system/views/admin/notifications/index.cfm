<cfscript>
	event.include( "/css/admin/specific/datamanager/object/" );
	notifications = prc.notifications ?: [];
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="notifications.preferences" )#" data-global-key="p">
			<button class="btn btn-sm">
				<i class="fa fa-cog"></i>
				#translateResource( "cms:notifications.preferences.btn" )#
			</button>
		</a>
	</div>

	<div class="table-responsive">
		<form id="multi-action-form" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='notifications.multiAction' )#">
			<input type="hidden" name="multiAction" value="" />

			<table id="notifications-listing-table" class="table table-hover object-listing-table notifications-listing-table">
				<thead>
					<tr>
						<th>
							<label>
								<input type="checkbox" class="ace" />
								<span class="lbl"></span>
							</label>
						</th>
						<th>#translateResource( 'cms:notifications.table.header.notification' )#</th>
					<th>&nbsp;</th>
					</tr>
				</thead>
				<tbody data-nav-list="1" data-nav-list-child-selector="> tr > td :checkbox">
					<cfloop array="#notifications#" index="i" item="notification">
						<tr class="notification-#LCase( notification.type )#<cfif !notification.read> unread</cfif>">
							<td>
								<label>
									<input name="id" type="checkbox" class="ace" value="#notification.id#">
									<span class="lbl"></span>
								</label>
							</td>
							<td>#renderNotification( topic=notification.topic, data=notification.data, context='datatable' )#</td>
							<td>
								<div class="action-buttons">
									<a class="blue" href="#event.buildAdminLink( linkTo="notifications.view", queryString="id=#notification.id#")#" data-context-key="v">
										<i class="fa fa-eye bigger-130"></i>
									</a>
									<cfif !notification.read>
										<a class="green" href="#event.buildAdminLink( linkTo="notifications.readAction", queryString="id=#notification.id#")#" data-context-key="r">
											<i class="fa fa-check bigger-130"></i>
										</a>
									<cfelse>
										<a class="disabled" disabled="disabled"><i class="fa fa-check bigger-130 grey"></i></a>
									</cfif>
									<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="notifications.dismissAction", queryString="id=#notification.id#")#" data-context-key="d" title="#translateResource( 'cms:notifications.discard.prompt' )#">
										<i class="fa fa-trash bigger-130"></i>
									</a>
								</div>
							</td>
						</tr>
					</cfloop>
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