<cfparam name="prc.log"      type="struct" />
<cfscript>
	hasEmailLoggingFeatureEnabled   = getSystemSetting( 'email', 'enable_email_content_logging', false ) == 1;
	hasEmailContent                 = !isEmpty( ( prc.log.email_content_html ?: "" ) & ( prc.log.email_content_text ?: "" ) );
	hasPermissionToViewEmailContent = hasEmailLoggingFeatureEnabled && hasCmsPermission( "emailCenter.email.view" ) && hasEmailContent;
</cfscript>
<cfoutput>
	<div class="well">
		<h2>#prc.log.subject#</h2>
		<dl class="dl-horizontal">
			<dt>To</dt>
			<dd>#prc.log.recipient#</dd>
			<dt>From</dt>
			<dd>#prc.log.sender#</dd>
			<dt>Template</dt>
			<dd>#prc.log.name#</dd>
		</dl>
	</div>
	<div class="modal-padding-horizontal">
		<div class="tabbable">
			<ul class="nav nav-tabs">
				<li class="active">
					<a data-toggle="tab" href="##tab-activities">
						<i class="fa fa-fw fa-history"></i>&nbsp;Activity logs
					</a>
				</li>
				<cfif hasPermissionToViewEmailContent>
					<li>
						</a><a data-toggle="tab" href="##tab-content">
							<i class="fa fa-fw fa-eye"></i>&nbsp;Email content
						</a>
					</li>
				</cfif>
			</ul>
			<div class="tab-content">
				<div class="tab-pane active" id="tab-activities">
					#renderView( view="admin/emailcenter/logs/_activities", args=args )#
				</div>
				<cfif hasPermissionToViewEmailContent>
					<div class="tab-pane" id="tab-content">
						#renderView( view="admin/emailcenter/logs/_emailContent", args=args )#
					</div>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>