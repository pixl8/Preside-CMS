<cfscript>
	topic = rc.topic ?: "";

	dateFrom    = rc.dateFrom ?: "";
	dateTo      = rc.dateTo   ?: "";
	topic       = rc.topic    ?: "";
	filtered    = Len( Trim( dateFrom & dateTo & topic) ) > 0;

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = "admin_notification_consumer"
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=notifications.getNotificationsForAjaxDataTables&topic=#topic#&dateFrom=#dateFrom#&dateTo=#dateTo#" )
		, useMultiActions = true
		, allowSearch     = false
	} );

	gridFields = [ { name="topic", sortable=true }, { name="datecreated", sortable=true }, { name="data", sortable=false } ];
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "notifications.configure" )>
			<button data-toggle="dropdown" class="btn btn-sm btn-default pull-right inline">
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
				<button class="btn btn-sm btn-default">
					<i class="fa fa-cog"></i>
					#translateResource( "cms:notifications.personal.preferences.btn" )#
				</button>
			</a>
		</cfif>

		<a class="pull-right inline" href="##filter-form" data-toggle="collapse">
			<button class="btn btn-info btn-sm">
				<i class="fa fa-filter"></i>
				#translateResource( "cms:toggle.filter.btn")#
			</button>
		</a>
	</div>

	<cfif filtered>
		<p class="alert alert-info">
			<i class="fa fa-fw fa-filter"></i> #translateResource( uri="cms:notifications.filtered.message" )#
			<span class="pull-right">
				<a href="#event.buildAdminLink( linkTo='notifications' )#">#translateResource( "cms:notifications.filtered.clear.filter" )#</a>
				|
				<a href="##filter-form" data-toggle="collapse">#translateResource( "cms:notifications.filtered.show.filter" )#</a>
			</span>
		</p>
	</cfif>

	<div class="collapse" id="filter-form">
		<form class="form-horizontal" method="get" action="">
			#renderForm(
				  formName = "notifications.filter"
				, context  = "admin"
			)#

			<br>

			<div class="row">
				<div class="col-md-offset-2">
					<a href="##filter-form" data-toggle="collapse">
						<i class="fa fa-fw fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>

					&nbsp;

					<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
						<i class="fa fa-fw fa-check bigger-110"></i>
						#translateResource( "cms:ok.btn" )#
					</button>
				</div>
			</div>
		</form>
	</div>

	<div class="table-responsive">
		<form id="multi-action-form" class="form-horizontal multi-action-form" method="post" action="#event.buildAdminLink( linkTo='notifications.multiAction' )#">
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

			<div class="form-actions multi-action-buttons" id="multi-action-buttons">
				<button class="btn btn-danger confirmation-prompt" type="submit" name="dismiss" disabled="disabled" data-global-key="d" title="#translateResource( 'cms:notifications.multidiscard.prompt' )#">
					<i class="fa fa-trash-o bigger-110"></i>
					#translateResource( 'cms:notifications.dismiss.btn' )#
				</button>

				<button class="btn" type="submit" name="read" disabled="disabled" data-global-key="r">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( 'cms:notifications.read.btn' )#
				</button>
			</div>
		</form>
	</div>
</cfoutput>