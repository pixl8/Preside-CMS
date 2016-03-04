<cfparam name="args.submissionData" type="struct">
<cfparam name="args.adminLink"      type="string">
<cfparam name="args.adminLinkText"  type="string">

<cfoutput>
	<div style="border:1px solid ##eee;background-color:##fafafa;padding:10px;">
		<h2>
			#renderContent( 'websiteUser', args.submissionData.submitted_by, [ "admin" ] )#
			<cfif Len( Trim( args.submissionData.submitted_by ) )>
				<a href="#event.buildAdminLink( linkto='websiteUserManager.editUser', queryString='id=' & args.submissionData.submitted_by )#" target="_blank"><i class="fa fa-fw fa-external-link"></i></a>
			</cfif>
		</h2>
		<table class="twelve columns" style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; width: 580px; margin: 0 auto; padding: 0;">
			<tr>
				<th style="width:35%;padding-right:5px;">#translateResource( "preside-objects.formbuilder_formsubmission:field.datecreated.title")#</th>
				<td>#renderField( 'formbuilder_formsubmission', 'datecreated', args.submissionData.datecreated )#</td>
			</tr>

			<tr>
				<th style="width:35%;padding-right:5px;">#translateResource( "preside-objects.formbuilder_formsubmission:field.form_instance.title")#</th>
				<td>#renderField( 'formbuilder_formsubmission', 'form_instance', args.submissionData.form_instance )#</td>
			</tr>

			<tr>
				<th style="width:35%;padding-right:5px;">#translateResource( "preside-objects.formbuilder_formsubmission:field.ip_address.title")#</th>
				<td>#renderField( 'formbuilder_formsubmission', 'ip_address', args.submissionData.ip_address )#</td>
			</tr>

			<tr>
				<th style="width:35%;padding-right:5px;">#translateResource( "preside-objects.formbuilder_formsubmission:field.user_agent.title")#</th>
				<td>#renderField( 'formbuilder_formsubmission', 'user_agent', args.submissionData.user_agent )#</td>
			</tr>
		</table>
	</div>
	<div style="padding:11px;">
		<h2>#translateResource( "formbuilder:submission.responses.title" )#</h2>
		#renderField( 'formbuilder_formsubmission', 'submitted_data', args.submissionData.submitted_data )#

		<br />
		<hr />
		<br />

		<p><a href="#args.adminLink#">#args.adminLinkText#</a></p>
	</div>


</cfoutput>