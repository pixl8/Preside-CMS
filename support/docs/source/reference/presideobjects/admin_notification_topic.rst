Notification
============

Overview
--------

The notification topic object is used to store global configuration for a given notification topic

**Object name:**
    admin_notification_topic

**Table name:**
    psys_admin_notification_topic

**Path:**
    /preside-objects/admin/notifications/admin_notification_topic.cfc

Properties
----------

.. code-block:: java

    property name="topic"                 type="string"  dbtype="varchar" maxlength=200 required=true uniqueindex="topic";
    property name="send_to_email_address" type="string"  dbtype="text"                  required=false;
    property name="save_in_cms"           type="boolean" dbtype="boolean"               required=false default=true;