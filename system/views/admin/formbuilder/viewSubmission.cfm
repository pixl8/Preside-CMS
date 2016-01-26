<cfparam name="prc.submission" type="query">

<cfoutput>
	<div class="well">
		<h2>
			#renderContent( 'websiteUser', prc.submission.submitted_by, [ "admin" ] )#
			<cfif Len( Trim( prc.submission.submitted_by ) )>
				<a href="#event.buildAdminLink( linkto='websiteUserManager.editUser', queryString='id=' & prc.submission.submitted_by )#" target="_blank"><i class="fa fa-fw fa-external-link"></i></a>
			</cfif>
		</h2>
		<dl class="dl-horizontal">
			<dt>#translateResource( "preside-objects.formbuilder_formsubmission:field.datecreated.title")#</dt>
			<dd>#renderField( 'formbuilder_formsubmission', 'datecreated', prc.submission.datecreated )#</dd>

			<dt>#translateResource( "preside-objects.formbuilder_formsubmission:field.form_instance.title")#</dt>
			<dd>#renderField( 'formbuilder_formsubmission', 'form_instance', prc.submission.form_instance )#</dd>

			<dt>#translateResource( "preside-objects.formbuilder_formsubmission:field.ip_address.title")#</dt>
			<dd>#renderField( 'formbuilder_formsubmission', 'ip_address', prc.submission.ip_address )#</dd>

			<dt>#translateResource( "preside-objects.formbuilder_formsubmission:field.user_agent.title")#</dt>
			<dd>#renderField( 'formbuilder_formsubmission', 'user_agent', prc.submission.user_agent )#</dd>
		</dl>
	</div>
	<div class="modal-padding-horizontal">
		<h2 class="blue">#translateResource( "formbuilder:submission.responses.title" )#</h2>
		#renderField( 'formbuilder_formsubmission', 'submitted_data', prc.submission.submitted_data )#
	</div>
</cfoutput>