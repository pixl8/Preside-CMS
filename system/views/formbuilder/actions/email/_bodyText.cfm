<cfparam name="args.submissionData" type="struct">
<cfparam name="args.adminLink"      type="string">
<cfparam name="args.adminLinkText"  type="string">

<cfoutput>
==============
#translateResource( "preside-objects.formbuilder_formsubmission:field.submitted_by.title")#: #renderContent( 'websiteUser', args.submissionData.submitted_by, [ "textemail" ] )#
#translateResource( "preside-objects.formbuilder_formsubmission:field.datecreated.title")#: #renderField( 'formbuilder_formsubmission', 'datecreated', args.submissionData.datecreated, [ "textemail"] )#
#translateResource( "preside-objects.formbuilder_formsubmission:field.form_instance.title")#: #renderField( 'formbuilder_formsubmission', 'form_instance', args.submissionData.form_instance, [ "textemail"] )#
#translateResource( "preside-objects.formbuilder_formsubmission:field.ip_address.title")#: #renderField( 'formbuilder_formsubmission', 'ip_address', args.submissionData.ip_address, [ "textemail"] )#
#translateResource( "preside-objects.formbuilder_formsubmission:field.user_agent.title")#: #renderField( 'formbuilder_formsubmission', 'user_agent', args.submissionData.user_agent, [ "textemail"] )#


#translateResource( "formbuilder:submission.responses.title" )#
==============
#renderField( 'formbuilder_formsubmission', 'submitted_data', args.submissionData.submitted_data, ["textemail"] )#

---
#args.adminLinkText#: #args.adminLink#
</cfoutput>