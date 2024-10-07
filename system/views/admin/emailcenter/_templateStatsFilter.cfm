<!---@feature admin and emailCenter--->
<cfscript>
	templateId = rc.id ?: ( args.templateId ?: "" );
	containerClass = args.containerClass ?: "pull-left";

	dateFrom = "<strong>#DateTimeFormat( args.dateFrom, "yyyy-mm-dd HH:nn" )#</strong>";
	dateTo   = "<strong>#DateTimeFormat( args.dateTo  , "yyyy-mm-dd HH:nn" )#</strong>";

	minDate  = IsDate( args.minDate ?: "" ) ? DateFormat( args.minDate, "yyyy-mm-dd" ) : "";
	maxDate  = IsDate( args.maxDate ?: "" ) ? DateFormat( DateAdd( 'd', 1, args.maxDate ), "yyyy-mm-dd" ) & " 23:59" : "";

	if ( IsDate( args.dateFrom ) && IsDate( args.dateTo ) ) {
		summary = translateResource( uri="cms:emailcenter.stats.filter.summary.from.to", data=[ dateFrom, dateTo ] );
	} else if ( IsDate( args.dateFrom ) ) {
		summary = translateResource( uri="cms:emailcenter.stats.filter.summary.from", data=[ dateFrom ] );
	} else if ( IsDate( args.dateTo ) ) {
		summary = translateResource( uri="cms:emailcenter.stats.filter.summary.to", data=[ dateTo ] );
	} else {
		summary = translateResource( uri="cms:emailcenter.stats.filter.summary", data=[ dateFrom, dateTo ] );
	}

	changeTitle = translateResource( uri="cms:emailcenter.stats.filter.change.link" );
	cancelBtn    = translateResource( uri="cms:cancel.btn" );
	filterButton = translateResource( uri="cms:emailcenter.stats.filter.submit.btn" );

	filterFormAction = event.getCurrentUrl( includeQueryString=false );
</cfscript>

<cfoutput>
	<div class="#containerClass#">
		<p class="grey">
			<i class="fa fa-fw fa-filter"></i>
			#summary#
			&nbsp;
			<a href="##" data-toggle="collapse" data-target="##stats-filter-form">
				<i class="fa fa-fw fa-filter"></i>
				#changeTitle#
			</a>
		</p>

		<div id="stats-filter-form" class="collapse">
			<hr>
			<form id="stats-filter-form-form" action="#filterFormAction#" method="get" class="form form-horizontal">
				<input type="hidden" name="id" value="#templateId#">
				#renderForm(
					  formName       = "email.stats.filter"
					, formId         = "stats-filter-form-form"
					, savedData      = { dateFrom=args.dateFrom, dateTo=args.dateTo }
					, additionalArgs = { fields={ dateFrom={ minDate=minDate, maxDate=maxDate, defaultDate=minDate }, dateTo={ minDate=minDate, maxDate=maxDate, defaultDate=maxDate } } }
				)#

				<div class="row">
					<div class="col-md-2">&nbsp;</div>
					<div class="col-md-10">
						<a href="##" class="btn btn-sm btn-default" data-toggle="collapse" data-target="##stats-filter-form">
							<i class="fa fa-fw fa-reply"></i>
							#cancelBtn#
						</a>
						<button type="submit" class="btn btn-sm btn-success" tabindex="#getNextTabIndex()#">
							<i class="fa fa-fw fa-filter"></i>
							#filterButton#
						</button>
					</div>
				</div>
			</form>
		</div>
	</div>
</cfoutput>