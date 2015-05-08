Multilingual Preside Object Service
===================================

.. contents::
    :depth: 2
    :local:



Overview
--------

**Full path:** *preside.system.services.i18n.MultilingualPresideObjectService*

This service exists to provide APIs that make providing support for multilingual
translations of standard preside objects possible in a transparent way. Note: You are
unlikely to need to deal with this API directly.

Public API Methods
------------------

.. _multilingualpresideobjectservice-ismultilingual:

IsMultilingual()
~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function isMultilingual( required string objectName, string propertyName="" )

Returns whether or not the given object and optional property are multilingual
enabled.

Arguments
.........

============  ======  ===============  ===================================================
Name          Type    Required         Description                                        
============  ======  ===============  ===================================================
objectName    string  Yes              Name of the object that we wish to check           
propertyName  string  No (default="")  Optional name of the property that we wish to check
============  ======  ===============  ===================================================


.. _multilingualpresideobjectservice-addtranslationobjectsformultilingualenabledobjects:

AddTranslationObjectsForMultilingualEnabledObjects()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function addTranslationObjectsForMultilingualEnabledObjects( required struct objects )

Performs the magic of creating extra database tables (preside objects) to store the
translations of multilingual enabled objects.

Arguments
.........

=======  ======  ========  ===========================================================
Name     Type    Required  Description                                                
=======  ======  ========  ===========================================================
objects  struct  Yes       Objects as compiled and read by the preside object service.
=======  ======  ========  ===========================================================


.. _multilingualpresideobjectservice-createtranslationobject:

CreateTranslationObject()
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function createTranslationObject( required string objectName, required struct sourceObject )

Returns the meta data for our auto generated translation object based on a given
source object

Arguments
.........

============  ======  ========  =================================
Name          Type    Required  Description                      
============  ======  ========  =================================
objectName    string  Yes       The name of the source object    
sourceObject  struct  Yes       The metadata of the source object
============  ======  ========  =================================


.. _multilingualpresideobjectservice-decoratemultilingualobject:

DecorateMultilingualObject()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function decorateMultilingualObject( required string objectName, required struct object )

Adds utility properties to the multilingual enabled source object
so that its translations can be easily queried

Arguments
.........

==========  ======  ========  =================================
Name        Type    Required  Description                      
==========  ======  ========  =================================
objectName  string  Yes       The name of the source object    
object      struct  Yes       The metadata of the source object
==========  ======  ========  =================================


.. _multilingualpresideobjectservice-mixintranslationspecificselectlogictoselectdatacall:

MixinTranslationSpecificSelectLogicToSelectDataCall()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function mixinTranslationSpecificSelectLogicToSelectDataCall( required string objectName, required array selectFields, required any adapter )

Works on intercepted select queries to discover and replace multilingual
select fields with special IfNull( translation, original ) syntax
to automagically select translations without the developer having to
do anything about it

Arguments
.........

============  ======  ========  ==================================================================================
Name          Type    Required  Description                                                                       
============  ======  ========  ==================================================================================
objectName    string  Yes       The name of the source object                                                     
selectFields  array   Yes       Array of select fields as passed into the presideObjectService.selectData() method
adapter       any     Yes       Database adapter to be used in generating the select query SQL                    
============  ======  ========  ==================================================================================


.. _multilingualpresideobjectservice-addlanguageclausetotranslationjoins:

AddLanguageClauseToTranslationJoins()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function addLanguageClauseToTranslationJoins( required array tableJoins, required string language, required struct preparedFilter )

Works on intercepted select queries to discover and decorate
joins on translation objects with an additional clause for the
passed in language

Arguments
.........

==============  ======  ========  ============================================================================
Name            Type    Required  Description                                                                 
==============  ======  ========  ============================================================================
tableJoins      array   Yes       Array of table joins as calculated by the SelectData() logic                
language        string  Yes       The language to filter on                                                   
preparedFilter  struct  Yes       The fully prepared and resolved filter that will be used in the select query
==============  ======  ========  ============================================================================


.. _multilingualpresideobjectservice-listlanguages:

ListLanguages()
~~~~~~~~~~~~~~~

.. code-block:: java

    public array function listLanguages( boolean includeDefault=true )

Returns an array of actively supported languages. Each language
is represented as a struct with id, name, native_name, iso_code and default keys

Arguments
.........

==============  =======  =================  ===========================================================
Name            Type     Required           Description                                                
==============  =======  =================  ===========================================================
includeDefault  boolean  No (default=true)  Whether or not to include the default language in the array
==============  =======  =================  ===========================================================


.. _multilingualpresideobjectservice-gettranslationstatus:

GetTranslationStatus()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public array function getTranslationStatus( required string objectName, required string recordId )

Returns an array of actively supported languages as per listLanguages()
with an additional 'status' field indicating the status of the translation
for the given object record

Arguments
.........

==========  ======  ========  ===============================================================================
Name        Type    Required  Description                                                                    
==========  ======  ========  ===============================================================================
objectName  string  Yes       Name of the object that has the record we wish to get the translation status of
recordId    string  Yes       ID of the record we wish to get the translation status of                      
==========  ======  ========  ===============================================================================


.. _multilingualpresideobjectservice-getlanguage:

GetLanguage()
~~~~~~~~~~~~~

.. code-block:: java

    public struct function getLanguage( required string languageId )

Returns a structure of language details for the given language.
If the language is not an actively translatable language,
an empty structure will be returned.

Arguments
.........

==========  ======  ========  =========================
Name        Type    Required  Description              
==========  ======  ========  =========================
languageId  string  Yes       ID of the language to get
==========  ======  ========  =========================


.. _multilingualpresideobjectservice-gettranslationobjectname:

GetTranslationObjectName()
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getTranslationObjectName( required string sourceObjectName )

Returns the name of the given object's corresponding translation object

Arguments
.........

================  ======  ========  ===========
Name              Type    Required  Description
================  ======  ========  ===========
sourceObjectName  string  Yes                  
================  ======  ========  ===========
