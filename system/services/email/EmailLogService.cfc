/**
 * The email log service takes care of tracking and listing email activities from the site.
 * @singleton
 * @presideService
 */
component output=false singleton=true displayName="Email log service" {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

	/**
	 * Saves the email activities from the site.
	 * Each element in the query contains `from`, `to`, `subject`, `status`, `htmlBody` and `textBody`.
	 *
	 */
	public void function saveEmailLogs(
		  required string from_address
		, required string to_address
		, required string subject
		, required string status
		,          string text_body
		,          string html_body
	 ) {
		$getPresideObject( "email_logs" ).insertData( data=arguments );
	}

	/**
	 * Returns a query of all the emails logged in the system.
	 * Each element in the query contains `from`, `to`, `subject`, `status`, `htmlBody` and `textBody`.
	 *
	 */
	public query function getEmailLogs() {
		var emailLogs = $getPresideObject( "email_logs" ).selectData();
		return emailLogs;
	}

	/**
	 * Returns a query of selected email.
	 * Each element in the query contains `from`, `to`, `subject`, `status`, `htmlBody` and `textBody`.
	 *
	 */
	public query function getEmailLog( required string id ) {
		var filter       = "email_logs.id = :id";
		var filterParams = { id=arguments.id };
		var emailLog     = $getPresideObject( "email_logs" ).selectData(
			  filter       = filter
			, filterParams = filterParams
		);

		return emailLog;
	}

	/**
	 * Delete the email from the internal log
	 *
	 */
	public void function deleteEmailLog( required string id ) {
		var id = arguments.id;
		$getPresideObject( "email_logs" ).deleteData( filter={ id = id } );
	}

	/**
	 * Clears the internal email log completely
	 *
	 */
	public void function deleteAllEmails( required boolean forceDeleteAll ) {
		$getPresideObject( "email_logs" ).deleteData( forceDeleteAll = arguments.forceDeleteAll );
	}
}