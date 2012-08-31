lsmp
====

List Mobileprovision Profile, with optional checking for correct bundle id and none expired.

http://www.memention.com/blog/2012/08/30/Provision-this.html

    profile=profile.mobileprovision
    
    # Test Bundle ID
    if ! lsmp -b com.memention.kwizlr -q $profile
    then
      echo Profile has incorrect bundle id
    fi 

    # Test expiration date
    if ! lsmp -e -q $profile
    then
      echo Profile has expired
    fi
    
    # Test Push Notification
    if ! lsmp -p -q $profile
    then
      echo Profile lacks Push Notification config
    fi 

    # Test for Enterprise profiles
    if ! lsmp -E -q $profile
    then
      echo Profile is no Enterprise profile
    fi 
