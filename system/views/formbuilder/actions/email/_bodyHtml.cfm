<cfparam name="args.submissionData" type="struct">
<cfparam name="args.adminLink"      type="string">
<cfparam name="args.adminLinkText"  type="string">

<cfoutput>
	<table style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; margin: 0 auto; padding: 0;">
		<tr>
			<th colspan="2" valign="top" style="padding-bottom:18px;font-size:18px;">#renderContent( 'websiteUser', args.submissionData.submitted_by, [ "email" ] )#</th>
		</tr>
		<tr>
			<th style="width:35%;padding-right:5px;" valign="top">#translateResource( "preside-objects.formbuilder_formsubmission:field.datecreated.title")#</th>
			<td valign="top">#renderField( 'formbuilder_formsubmission', 'datecreated', args.submissionData.datecreated )#</td>
		</tr>

		<tr>
			<th style="width:35%;padding-right:5px;" valign="top">#translateResource( "preside-objects.formbuilder_formsubmission:field.form_instance.title")#</th>
			<td valign="top">#renderField( 'formbuilder_formsubmission', 'form_instance', args.submissionData.form_instance )#</td>
		</tr>

		<tr>
			<th style="width:35%;padding-right:5px;" valign="top">#translateResource( "preside-objects.formbuilder_formsubmission:field.ip_address.title")#</th>
			<td valign="top">#renderField( 'formbuilder_formsubmission', 'ip_address', args.submissionData.ip_address )#</td>
		</tr>

		<tr>
			<th style="width:35%;padding-right:5px;" valign="top">#translateResource( "preside-objects.formbuilder_formsubmission:field.user_agent.title")#</th>
			<td valign="top">#renderField( 'formbuilder_formsubmission', 'user_agent', args.submissionData.user_agent )#</td>
		</tr>

		<tr>
			<th colspan="2" valign="top" style="padding-top:36px;padding-bottom:18px;font-size:18px;">#translateResource( "formbuilder:submission.responses.title" )#</th>
		</tr>

		#renderField( 'formbuilder_formsubmission', 'submitted_data', args.submissionData.submitted_data, ["htmlEmail"] )#
	</table>

	<br />
	<hr />
	<br />

	<p><a href="#args.adminLink#">#args.adminLinkText#</a></p>


</cfoutput>