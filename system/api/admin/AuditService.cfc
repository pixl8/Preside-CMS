component output="false" extends="preside.system.base.Service" {

<!--- constructor --->
	public any function init() output=false {
		super.init( argumentCollection = arguments );

		return this;
	}

<!--- public methods --->
	public void function log(
		  required string detail
		, required string source
		, required string action
		, required string type
		, required string instance
		, required string userId
	) output=false {
		getPresideObject( "audit_log" ).insertData( {
			  label  = arguments.detail
			, source     = arguments.source
			, action     = arguments.action
			, type       = arguments.type
			, instance   = arguments.instance
			, user       = arguments.userId
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
		} );
	}
}