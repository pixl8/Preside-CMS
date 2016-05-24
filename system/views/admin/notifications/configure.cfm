<cfscript>
	topics             = prc.topics             ?: [];
	selectedTopic      = prc.selectedTopic      ?: "";
	savedConfiguration = prc.topicConfiguration ?: {};
	formId             = "configure-form";
	formAction         = event.buildAdminLink( linkTo="notifications.saveTopicConfigurationAction" );
</cfscript>

<cfoutput>
	<cfif not topics.len()>
		<p><em>#translateResource( 'cms:notifications.configure.notopics.message' )#</em></p>
	<cfelse>
		<p>#translateResource( 'cms:notifications.configure.description' )#</p>

		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<cfloop array="#topics#" index="i" item="topicId">
					<li<cfif selectedTopic eq topicId> class="active"</cfif>>
						<cfset link = selectedTopic eq topicId ? "##" : event.buildAdminLink( linkTo="notifications.configure", queryString="topic=#topicId#" ) />
						<a href="#link#">
							<i class="fa fa-fw #translateresource( "notifications.#topicId#:iconClass")#"></i>
							#translateresource( "notifications.#topicId#:title")#
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
				<div class="alert alert-info">
					<i class="fa fa-fw fa-info-circle fa-lg"></i> #translateresource( "notifications.#selectedTopic#:description")#
				</div>
				<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#formAction#">
					<input type="hidden" name="topic" value="#selectedTopic#">

					#renderForm(
						  formName          = "notifications.topic-global-config"
						, formId            = formId
						, savedData         = savedConfiguration
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
	</cfif>
</cfoutput>