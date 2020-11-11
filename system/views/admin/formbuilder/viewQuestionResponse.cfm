<cfscript>
	prc.pageIcon  = "question";
	prc.pageTitle = prc.response.full_question_text;
	responseArgs  = {
		  responseid   = prc.response.id
		, formId       = prc.response.submission_reference
		, submissionId = prc.response.submission
		, questionId   = prc.response.question
		, itemType     = prc.response.item_type
	};
</cfscript>

<cfparam name="prc.response" type="query">

<cfoutput>
	<table class="table formbuilder-response table-striped">
		<body>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.full_question_text.title")#</th>
				<td>#renderField( 'formbuilder_question', 'full_question_text', prc.response.full_question_text )#</td>
			</tr>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.response.title")#</th>
				<td>
					#renderViewLet( event="renderers.content.formBuilderResponse.default", args=responseArgs )#
				</td>
			</tr>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.submitted_by.title")#</th>
				<td>
					#renderField( 'formbuilder_question_response', 'submitted_by', prc.response.submitted_by )#
				</td>
			</tr>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.is_website_user.title")#</th>
				<td>
					<cfif ( prc.response.is_website_user ) >
						<i class="fa fa-check-circle green" title="Yes"></i>
					<cfelse>
						<i class="fa fa-times-circle red" title="Yes"></i>
					</cfif>
				</td>
			</tr>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.is_admin_user.title")#</th>
				<td>
					<cfif (prc.response.is_admin_user ) >
						<i class="fa fa-check-circle green" title="Yes"></i>
					<cfelse>
						<i class="fa fa-times-circle red" title="Yes"></i>
					</cfif>
				</td>
			</tr>
			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.form_name.title")#</th>
				<td>
					<cfif Len( Trim( prc.response.submission_reference ) ) >
						<a href="#event.buildAdminLink( linkto='formbuilder.manageForm', queryString='id=' & prc.response.submission_reference )#" target="_blank" >
							#renderField( 'formbuilder_form', 'name', prc.response.form_name )#
						</a>
					</cfif>
				</td>
			</tr>

			<cfif Len( Trim( prc.response.submission ) ) >
				<tr>
					<th>#translateResource( "preside-objects.formbuilder_question_response:field.related_answers.title")#</th>
					<td>
						<a href="#event.buildAdminLink( linkto='formbuilder.viewSubmission', queryString='id=' & prc.response.submission )#" target="_blank" data-toggle="bootbox-modal" data-modal-class="full-screen-dialog limited-size">
							View Answers <i class="fa fa-fw fa-external-link"></i>
						</a>
					</td>
				</tr>
			</cfif>

			<tr>
				<th>#translateResource( "preside-objects.formbuilder_question_response:field.datecreated.title")#</th>
				<td>#renderField( 'formbuilder_question_response', 'datecreated', prc.response.datecreated )#</td>
			</tr>
		</body>
	</table>
</cfoutput>
