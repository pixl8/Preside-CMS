<?xml version="1.0" encoding="UTF-8"?><railo-configuration pw="f76d0a69568e8afa331cc07973d31292f73500ec941a12614c22c16b0e5f7140" version="2.0"><cfabort/>
	<setting cfml-writer="white-space-pref"/>

	<data-sources>
		<data-source allow="511" blob="false" class="org.gjt.mm.mysql.Driver" clob="true" connectionLimit="-1" connectionTimeout="1" custom="useUnicode=true&amp;characterEncoding=UTF-8&amp;allowMultiQueries=true&amp;useLegacyDatetimeCode=true" database="preside_test" dbdriver="MySQL" dsn="jdbc:mysql://{host}:{port}/{database}" host="localhost" metaCacheTimeout="60000" name="preside_test_suite" password="" port="3306" storage="false" username="travis" validate="false"/>
	</data-sources>

	<resources>
    	<resource-provider arguments="case-sensitive:true;lock-timeout:1000;" class="railo.commons.io.res.type.ram.RamResourceProvider" scheme="ram"/>
    	<resource-provider arguments="lock-timeout:10000;" class="railo.commons.io.res.type.s3.S3ResourceProvider" scheme="s3"/>
    </resources>

    <remote-clients directory="{railo-web}remote-client/" log="logs/" log-level="info"/>

	<file-system deploy-directory="{railo-web}/cfclasses/" fld-directory="{railo-web}/library/fld/" temp-directory="{railo-web}/temp/" tld-directory="{railo-web}/library/tld/">
	</file-system>

	<scope client-directory="{railo-web}/client-scope/" client-directory-max-size="100mb" requesttimeout-log="{railo-web}/logs/requesttimeout.log"/>

	<mail log="{railo-web}/logs/mail.log">
	</mail>

	<search directory="{railo-web}/search/" engine-class="railo.runtime.search.lucene.LuceneSearchEngine"/>

	<scheduler directory="{railo-web}/scheduler/" log="{railo-web}/logs/scheduler.log"/>

	<mappings>
		<mapping archive="{railo-web}/context/railo-context.ra" physical="{railo-web}/context/" primary="physical" readonly="yes" toplevel="yes" trusted="true" virtual="/railo-context/"/>
	</mappings>

	<custom-tag>
		<mapping physical="{railo-web}/customtags/" trusted="yes"/>
	</custom-tag>

	<ext-tags>
		<ext-tag class="railo.cfx.example.HelloWorld" name="HelloWorld" type="java"/>
	</ext-tags>

	<component base="/railo-context/Component.cfc" data-member-default-access="public" use-shadow="yes">
	</component>

	<regional/>

	<debugging template="/railo-context/templates/debugging/debugging.cfm"/>

	<application application-log="{railo-web}/logs/application.log" application-log-level="info" cache-directory="{railo-web}/cache/" cache-directory-max-size="100mb" exception-log="{railo-web}/logs/exception.log" exception-log-level="info" trace-log="{railo-web}/logs/trace.log" trace-log-level="info"/>

	<compiler dot-notation-upper-case="false" full-null-support="false" supress-ws-before-arg="true"/>
</railo-configuration>