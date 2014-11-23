Notification Service
====================

Overview
--------

**Full path:** *preside.system.services.notifications.NotificationService*

The notifications service provides an API to the PresideCMS administrator notifications system

Public API Methods
------------------

.. _notificationservice-createnotification:

CreateNotification()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function createNotification( required string topic, required string type, required struct data )

Adds a notification to the system.

Arguments
.........

=====  ======  ========  =========================================================================================================================
Name   Type    Required  Description                                                                                                              
=====  ======  ========  =========================================================================================================================
topic  string  Yes       Topic that indicates the specific notification being raised. e.g. 'sync.jobFailed'                                       
type   string  Yes       Type of the notification, i.e. 'INFO', 'WARNING' or 'ALERT'                                                              
data   struct  Yes       Supporting data for the notification. This is used, in combination with the topic, to render the alert for the end users.
=====  ======  ========  =========================================================================================================================


.. _notificationservice-getunreadnotificationcount:

GetUnreadNotificationCount()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public numeric function getUnreadNotificationCount( required string userId )

Returns a count of unread notifications for the given user id.

Arguments
.........

======  ======  ========  ========================================================================
Name    Type    Required  Description                                                             
======  ======  ========  ========================================================================
userId  string  Yes       id of the admin user who's unread notification count we wish to retrieve
======  ======  ========  ========================================================================


.. _notificationservice-getunreadtopics:

GetUnreadTopics()
~~~~~~~~~~~~~~~~~

.. code-block:: java

    public query function getUnreadTopics( required string userId )

Returns counts of unread notifications by topics for the given user

Arguments
.........

======  ======  ========  ===================================================================
Name    Type    Required  Description                                                        
======  ======  ========  ===================================================================
userId  string  Yes       id of the admin user who's unread notifications we wish to retrieve
======  ======  ========  ===================================================================


.. _notificationservice-getnotifications:

GetNotifications()
~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public array function getNotifications( required string userId, numeric maxRows=10, string topic="" )

Returns the latest unread notifications for the given user id. Returns an array of structs, each struct contains id and data keys.

Arguments
.........

=======  =======  ===============  ===================================================================
Name     Type     Required         Description                                                        
=======  =======  ===============  ===================================================================
userId   string   Yes              id of the admin user who's unread notifications we wish to retrieve
maxRows  numeric  No (default=10)  maximum number of notifications to retrieve                        
topic    string   No (default="")                                                                     
=======  =======  ===============  ===================================================================


.. _notificationservice-getnotification:

GetNotification()
~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getNotification( required string id )

Returns a specific notification

Arguments
.........

====  ======  ========  ======================
Name  Type    Required  Description           
====  ======  ========  ======================
id    string  Yes       ID of the notification
====  ======  ========  ======================


.. _notificationservice-rendernotification:

RenderNotification()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function renderNotification( required string topic, required struct data, required string context )

Renders the given notification topic

Arguments
.........

=======  ======  ========  =====================================
Name     Type    Required  Description                          
=======  ======  ========  =====================================
topic    string  Yes       Topic of the notification            
data     struct  Yes       Data associated with the notification
context  string  Yes                                            
=======  ======  ========  =====================================


.. _notificationservice-listtopics:

ListTopics()
~~~~~~~~~~~~

.. code-block:: java

    public array function listTopics( )

Returns array of configured topics

Arguments
.........

*This method does not accept any arguments.*

.. _notificationservice-markasread:

MarkAsRead()
~~~~~~~~~~~~

.. code-block:: java

    public numeric function markAsRead( required array notificationIds, required string userId )

Marks notifications as read for a given user

Arguments
.........

===============  ======  ========  =========================================
Name             Type    Required  Description                              
===============  ======  ========  =========================================
notificationIds  array   Yes       Array of notification IDs to mark as read
userId           string  Yes       The id of the user to mark as read for   
===============  ======  ========  =========================================


.. _notificationservice-dismiss:

Dismiss()
~~~~~~~~~

.. code-block:: java

    public numeric function dismiss( required array notificationIds )

Completely discards the given notifications

Arguments
.........

===============  =====  ========  ======================================
Name             Type   Required  Description                           
===============  =====  ========  ======================================
notificationIds  array  Yes       Array of notification IDs to dismissed
===============  =====  ========  ======================================


.. _notificationservice-getusersubscriptions:

GetUserSubscriptions()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public array function getUserSubscriptions( required string userId )

Get subscribed topics for a user. Returns an array of the topic ids

Arguments
.........

======  ======  ========  =======================================================
Name    Type    Required  Description                                            
======  ======  ========  =======================================================
userId  string  Yes       ID of the user who's subscribed topics we want to fetch
======  ======  ========  =======================================================


.. _notificationservice-saveusersubscriptions:

SaveUserSubscriptions()
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function saveUserSubscriptions( required string userId, required array topics )

Saves a users subscription preferences

Arguments
.........

======  ======  ========  ======================================================
Name    Type    Required  Description                                           
======  ======  ========  ======================================================
userId  string  Yes       ID of the user who's subscribed topics we want to save
topics  array   Yes       Array of topics to subscribe to                       
======  ======  ========  ======================================================
