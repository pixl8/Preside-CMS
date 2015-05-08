FeatureService
==============

.. contents::
    :depth: 2
    :local:



Overview
--------

**Full path:** *preside.system.services.features.FeatureService*

The Feature Service provides an API to preside's configured features.
This allows other systems within PresideCMS to check the enabled statusof enabled
status of features before proceeding to provide a page or perform some action

Public API Methods
------------------

.. _featureservice-isfeatureenabled:

IsFeatureEnabled()
~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function isFeatureEnabled( required string feature, string siteTemplate )

Returns whether or not the passed feature is currently enabled

Arguments
.........

============  ======  ========  ===============================================================================================
Name          Type    Required  Description                                                                                    
============  ======  ========  ===============================================================================================
feature       string  Yes       name of the feature to check                                                                   
siteTemplate  string  No        current active site template - can be used to check features that can be site template specific
============  ======  ========  ===============================================================================================
