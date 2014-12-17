<cfscript>
	topics        = prc.topics ?: [];
	subscriptions = prc.subscriptions ?: [];
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##general-preferences">
					<i class="fa fa-fw fa-cogs"></i>
					#translateResource( "cms:notifications.preferences.general.tab" )#
				</a>
			</li>

			<cfloop array="#topics#" index="i" item="topicId">
				<li>
					<a data-toggle="tab" href="###topicId#-preferences">
						<i class="fa fa-fw #translateresource( "notifications.#topicId#:iconClass")#"></i>
						#translateresource( "notifications.#topicId#:title")#
					</a>
				</li>
			</cfloop>
		</ul>

		<div class="tab-content">
			<div id="general-preferences" class="tab-pane in active">
				<cfset formId = "subscription-preferences" />
				<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#event.buildAdminLink( linkTo='notifications.savePreferencesAction' )#">
					#renderForm(
						  formName          = "notifications.preferences"
						, formId            = formId
						, savedData         = { subscriptions=subscriptions.toList() }
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

			<cfloop array="#topics#" index="i" item="topicId">
				<div id="#topicId#-preferences" class="tab-pane">
					<cfset formId = "#topicId#-subscription-preferences" />
					<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#event.buildAdminLink( linkTo='notifications.saveTopicPreferencesAction' )#">
						<input type="hidden" name="topic" value="#topicId#">

						#renderForm(
							  formName          = "notifications.topic-preferences"
							, formId            = formId
							, savedData         = {}<!--- TODO!! --->
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
			</cfloop>
		</div>
	</div>


</cfoutput>