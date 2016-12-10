<cfscript>
	topics        = prc.topics ?: [];
	subscriptions = prc.subscriptions ?: [];
	activeTab     = rc.topic ?: "general";

	formId      = "preferences-form";
	isTopicForm = Len( Trim( rc.topic ?: "" ) );
	if ( isTopicForm ) {
		savedSubscription = prc.subscription ?: {};
		formAction = event.buildAdminLink( linkTo='notifications.saveTopicPreferencesAction' );
	} else {
		formAction = event.buildAdminLink( linkTo='notifications.savePreferencesAction' );
	}
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li<cfif activeTab eq "general"> class="active"</cfif>>
				<cfset link = activeTab eq "general" ? "##" : event.buildAdminLink( linkTo="notifications.preferences" ) />
				<a href="#link#">
					<i class="fa fa-fw fa-cogs"></i>
					#translateResource( "cms:notifications.preferences.general.tab" )#
				</a>
			</li>

			<cfloop array="#topics#" index="i" item="topicId">
				<cfif subscriptions.find( topicId )>
					<li<cfif activeTab eq topicId> class="active"</cfif>>
						<cfset link = activeTab eq topicId ? "##" : event.buildAdminLink( linkTo="notifications.preferences", queryString="topic=#topicId#" ) />
						<a href="#link#">
							<i class="fa fa-fw #translateresource( "notifications.#topicId#:iconClass")#"></i>
							#translateresource( "notifications.#topicId#:title")#
						</a>
					</li>
				</cfif>
			</cfloop>
		</ul>

		<div class="tab-content">
			<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#formAction#">
				<cfif isTopicForm>
					<input type="hidden" name="topic" value="#rc.topic#">
				</cfif>

				#renderForm(
					  formName          = isTopicForm ? "notifications.topic-preferences" : "notifications.preferences"
					, formId            = formId
					, savedData         = isTopicForm ? savedSubscription : { subscriptions=subscriptions.toList() }
					, validationResult  = rc.validationResult ?: ""
				)#

				<div class="form-actions row">
					<div class="col-md-offset-2">
						<a href="#event.buildAdminLink( linkTo='notifications' )#" class="btn btn-default" data-global-key="c">
							<i class="fa fa-reply bigger-110"></i>
							#translateResource( "cms:cancel.btn" )#
						</a>

						<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
							<i class="fa fa-check bigger-110"></i>
							#translateResource( "cms:save.btn" )#
						</button>
					</div>
				</div>
			</form>
		</div>
	</div>


</cfoutput>