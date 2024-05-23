component extends="preside.system.Bootstrap" {

	super.setupApplication(
		  id                       = "End to End test site"
		, presideSessionManagement = true
	);

	this.datasources[ "preside" ] = {
		  type     : 'MySQL'
		, port     : 3306
		, host     : "127.0.0.1"
		, database : "endtoenddb"
		, username : "root"
		, password : "root"
		, custom   : {
			  characterEncoding : "UTF-8"
			, useUnicode        : true
		  }
	};

}
