<cfscript>
	var contactName = ( args.first_name ?: "" ) & " " & ( args.last_name ?: "" );
</cfscript>

<cfoutput>
	<div class="alert alert-danger">
		<i class="fa fa-fw fa-user"></i>
		Problem syncing member: <strong>#contactName#</strong>. Missing vital information (membership grade, class or email address)
		This member's record will need checking and ammending in CRM.
	</div>

	<div class="well">
		<h4 class="green">Member details:</h4>
		<dl class="dl-horizontal">
			<dt>Name</dt>
			<dd>#contactName#</dd>
			<dt>CRM ID</dt>
			<dd>#( args.crm_id ?: '' )#</dd>
			<dt>Email address:</dt>
			<dd>#( Len( Trim( args.contact_email ?: '' ) ) ? args.contact_email : '<em>No email supplied</em>' )#</dd>
		</dl>
	</div>
</cfoutput>