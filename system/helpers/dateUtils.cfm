<cffunction name="rssDateFormat" access="public" returntype="string" output="false">
	<cfargument name="date"     type="date"   required="true" />
	<cfargument name="timezone" type="string" required="false" default="GMT" /><cfsilent>

	<cfreturn DateFormat( arguments.date, "ddd, dd MMM YYYY " ) & TimeFormat( arguments.date, "HH:mm:ss " ) & arguments.timezone />
</cfsilent></cffunction>

<cffunction name="getShortDateFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getShortDateFormatMask() />
</cfsilent></cffunction>

<cffunction name="getShortDate" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" /><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getShortDate( arguments.date ) />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDateFormatMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatDayMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDateFormatDayMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatMonthMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDateFormatMonthMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatYearMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDateFormatYearMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatDayMonthMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDateFormatDayMonthMask() />
</cfsilent></cffunction>

<cffunction name="getLongDate" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" />
	<cfargument name="includeOrdinal" type="boolean" required="false" default="false" /><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getLongDate( arguments.date, arguments.includeOrdinal ) />
</cfsilent></cffunction>

<cffunction name="getDateRange" access="public" returntype="string" output="false">
	<cfargument name="date1" type="date" required="true" />
	<cfargument name="date2" type="date" required="true" />
	<cfargument name="showYear" type="boolean" required="false" default="false" />
	<cfargument name="includeOrdinal" type="boolean" required="false" default="false" /><cfsilent>

	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getDateRange( arguments.date1, arguments.date2, arguments.showYear, arguments.includeOrdinal ) />
</cfsilent></cffunction>

<cffunction name="getSplitDate" access="public" returntype="string" output="false">
	<cfargument name="dates" type="array" required="true" />
	<cfargument name="compact" type="boolean" required="false" default="false" />
	<cfargument name="compactThreshold" type="numeric" required="false" default="30" />
	<cfargument name="includeOrdinal" type="boolean" required="false" default="false" /><cfsilent>

	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getSplitDate( arguments.dates, arguments.compact, arguments.compactThreshold, arguments.includeOrdinal ) />
</cfsilent></cffunction>

<cffunction name="getDateDayOrdinal" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" /><cfsilent>
		
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getDateDayOrdinal( arguments.date ) />
</cfsilent></cffunction>

<cffunction name="getSiteLocaleSettings" access="public" returntype="query" output="false"><cfsilent>
	<cfset var dfService = getSingleton( "dateFormatService" ) />
	<cfreturn dfService.getSiteLocaleSettings() />
</cfsilent></cffunction>

<cffunction name="getTimeFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfset var tfService = getSingleton( "timeFormatService" ) />
	<cfreturn tfService.getTimeFormatMask() />
</cfsilent></cffunction>

<cffunction name="roundHours" access="public" returntype="string" output="false">
	<cfargument name="formattedTime" type="string" required="true" /><cfsilent>
	<cfset var tfService = getSingleton( "timeFormatService" ) />
	<cfreturn tfService.roundHours( arguments.formattedTime ) />
</cfsilent></cffunction>