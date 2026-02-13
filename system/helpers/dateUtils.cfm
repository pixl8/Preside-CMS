<cffunction name="rssDateFormat" access="public" returntype="string" output="false">
	<cfargument name="date"     type="date"   required="true" />
	<cfargument name="timezone" type="string" required="false" default="GMT" /><cfsilent>

	<cfreturn DateFormat( arguments.date, "ddd, dd MMM YYYY " ) & TimeFormat( arguments.date, "HH:mm:ss " ) & arguments.timezone />
</cfsilent></cffunction>

<cffunction name="getShortDateFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getShortDateFormatMask() />
</cfsilent></cffunction>

<cffunction name="getShortDate" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" /><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getShortDate( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getLongDateFormatMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatDayMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getLongDateFormatDayMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatMonthMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getLongDateFormatMonthMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatYearMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getLongDateFormatYearMask() />
</cfsilent></cffunction>

<cffunction name="getLongDateFormatDayMonthMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getLongDateFormatDayMonthMask() />
</cfsilent></cffunction>

<cffunction name="getLongDate" access="public" returntype="string" output="false">
	<cfargument name="date"           type="date"    required="true" />
	<cfargument name="includeOrdinal" type="boolean" required="false" default="false" /><cfsilent>

	<cfreturn getSingleton( "dateFormatService" ).getLongDate( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getDateRange" access="public" returntype="string" output="false">
	<cfargument name="date1"          type="date"    required="true" />
	<cfargument name="date2"          type="date"    required="true" />
	<cfargument name="showYear"       type="boolean" required="false" default="false" />
	<cfargument name="includeOrdinal" type="boolean" required="false" default="false" /><cfsilent>

	<cfreturn getSingleton( "dateFormatService" ).getDateRange( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getSplitDate" access="public" returntype="string" output="false">
	<cfargument name="dates"            type="array"   required="true" />
	<cfargument name="compact"          type="boolean" required="false" default="false" />
	<cfargument name="compactThreshold" type="numeric" required="false" default="30" />
	<cfargument name="includeOrdinal"   type="boolean" required="false" default="false" /><cfsilent>

	<cfreturn getSingleton( "dateFormatService" ).getSplitDate( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getDateDayOrdinal" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" /><cfsilent>
		
	<cfreturn getSingleton( "dateFormatService" ).getDateDayOrdinal( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getSiteLocaleSettings" access="public" returntype="struct" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getSiteLocaleSettings() />
</cfsilent></cffunction>

<cffunction name="getDefaultSettingsForLocale" access="public" returntype="struct" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getDefaultSettingsForLocale() />
</cfsilent></cffunction>

<cffunction name="getTimeFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "timeFormatService" ).getTimeFormatMask() />
</cfsilent></cffunction>

<cffunction name="roundHours" access="public" returntype="string" output="false">
	<cfargument name="formattedTime" type="string" required="true" /><cfsilent>

	<cfreturn getSingleton( "timeFormatService" ).roundHours( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getAdminDateFormatMask" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getSingleton( "dateFormatService" ).getAdminDateFormatMask( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getFormattedAdminDate" access="public" returntype="string" output="false">
	<cfargument name="date" type="date" required="true" /><cfsilent>

	<cfreturn getSingleton( "dateFormatService" ).getFormattedAdminDate( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="getFormattedAdminDateTime" access="public" returntype="string" output="false">
	<cfargument name="dateTime" type="date" required="true" /><cfsilent>

	<cfreturn getSingleton( "dateFormatService" ).getFormattedAdminDateTime( argumentCollection=arguments ) />
</cfsilent></cffunction>