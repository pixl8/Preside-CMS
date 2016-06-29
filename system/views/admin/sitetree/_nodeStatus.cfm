<cfparam name="args.embargo_date" />
<cfparam name="args.expiry_date"  />
<cfparam name="args.active"       />
<cfparam name="args.is_draft"     />
<cfparam name="args.has_drafts"   />

<cfscript>
	usesDateRestrictions = IsDate( args.embargo_date ) || IsDate( args.expiry_date );
	outOfDate            = ( IsDate( args.embargo_date ) && args.embargo_date > Now() ) || ( IsDate( args.expiry_date ) && args.expiry_date < Now() );
	isDraft              = IsTrue( args.is_draft );
	hasDrafts            = IsTrue( args.has_drafts );

	if ( isDraft ) {
		redClass   = greenClass = "light-grey";
	} else {
		redClass   = "red";
		greenClass = "green";
	}

</cfscript>

<cfoutput>
	<cfif IsTrue( args.active )>
		<i class="fa fa-fw fa-check-circle #greenClass#"></i>
	<cfelse>
		<i class="fa fa-fw fa-times-circle #redClass#"></i>
	</cfif>

	<cfif usesDateRestrictions>
		<i class="fa fa-fw fa-clock-o <cfif outOfDate>#redClass#<cfelse>#greenClass#</cfif>" title="#DateTimeFormat(args.embargo_date)# to #DateTimeFormat(args.expiry_date)#"></i>
	</cfif>

	<cfif isDraft>
		#translateResource( "cms:sitetree.page.status.draft" )#
	<cfelse>
		#translateResource( "cms:sitetree.page.status.published" )#
	</cfif>

	<cfif hasDrafts && !isDraft>
		&nbsp; <em class="light-grey">#translateResource( "cms:sitetree.page.status.has.drafts" )#</em>
	</cfif>
</cfoutput>