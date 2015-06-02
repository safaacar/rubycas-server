# Introduction #

RubyCAS-Server can retrieve user data from many different sources, including LDAP, ActiveDirectory, and a SQL database. These various data sources are each facilitated by "Authenticator" classes that implement their respective protocols. For a SQL data source, two different Authenticators are available: the plain SQL authenticator, and the more secure SQLEncrypted authenticator. This page explains how to use the latter.

# SQL vs SQLEncrypted #

**The plain SQL authenticator expects user passwords to be stored as plain text in your SQL database.** This makes deploying the SQL authenticator easy, but poses an obvious security risk (not necessarily for your CAS server, but certainly for your users should an intruder gain access to your user database).

If this is a concern for you, consider using SQLEncrypted. This authenticator allows you to hook in an arbitrary encryption function of your own.

# YAML Configuration #

To use SQLEncrypted authenticator you will need to modify your CAS server configuration (by default located in `/etc/rubycas-server/config.yml`).

Your configuration should look something like this:

```
authenticator:
  class: CASServer::Authenticators::SQLEncrypted
  database:
    adapter: mysql
    database: some_database_with_users_table
    username: root
    password: 
    server: localhost
  user_table: users
  username_column: email_address
  encrypt_function: 'user.crypted_password == Digest::SHA1.hexdigest("--#{user.salt}--#{@password}--")'
```

Note that this is more or less identical to the standard SQL authenticator configuration, with the exception of the `encrypt_function` parameter.

`encrypt_function` is eval'd in the server.  Three variables are visible in the function: `user`, `@password` and `@username`.   `@password` and `@username` are the values collected on the login screen, and `user` is an ActiveRecord instance of the row in your table.  Since it uses ActiveRecord, you can access any column in the row by name.

The output of `encrypt_function` should be a Boolean.   Do not use the return statement!

The default values for the configuration are:

```
  user_table: users
  username_column: username
  encrypt_function:  'user.encrypted_password == Digest::SHA256.hexdigest("#{user.encryption_salt}::#{@password}")'
```

Note (July 7, 2009):  Current versions of rubycas-server do not have the encrypt\_function parameter.  To parametrize encrypt\_function, you must use the version of rubycas-server on [GitHub](http://github.com/gunark/rubycas-server/tree/master).

# Deploying the SQLEncrypted Authenticator using the Default encrypt\_function #

If you do not yet have encrypted passwords in you database, you can use the default encrypt\_function and the instructions here to add encrypted passwords to your application.

First you'll have to make some changes to your application's user model (that is, the ActiveRecord class that defines 'user' records in your CAS-protected applications).

These instructions are targeted at Ruby on Rails applications. You'll have to improvise if your target application uses some other framework.

First off, your users table must have the following columns:

  * `encrypted_password` -- a `varchar(255)`; the encrypted password will be stored here
  * `encryption_salt` -- also a `varchar(255)`; this is a random string populated when the user record is first created, used to encrypt the password for that user

Here is a migration that will take care of this for you:

```
class AddEncryptedPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :encrypted_password, :string
    add_column :users, :encryption_salt, :string
  end
  def self.down
    remove_column :users, :encryption_salt
    remove_column :users, :encrypted_password
  end
end
```

You will also need to include the `EncryptedPassword` module into user user model:

```
require 'casserver/authenticators/sql_encrypted'

class User < ActiveRecord::Base
  include CASServer::Authenticators::SQLEncrypted::EncryptedPassword

  # ...
end
```

Whenever a new user account is created, an `encryption_hash` will automatically be created (it will also be generated for existing accounts without an `encryption_hash`).

# Encrypting Existing Passwords #

If you have existing accounts with a plain text password, you'll have to encrypt them. Fire up your Rails console and run something like the following:

```
User.find(:all).each do |u|
  u.save!
  u.password = u.password
  u.save!
end
```

The first `save!` ensures that `encryption_hash` is generated. The `password=` method then automatically encrypts the user's existing password and stores it in the `encrypted_password` column.

# Using MD5 Encyrption Instead of SHA256 #

The SQLEncrypted authenticator uses the SHA256 algorithm to do its encryption. If you prefer to use the MD5 algorithm instead (for example because you're working with an existing user database where the passwords are already encrypted using MD5), have a look at the [SQLMd5 authenticator](http://code.google.com/p/rubycas-server/source/browse/trunk/lib/casserver/authenticators/sql_md5.rb). The instructions for using the MD5 authenticator are similar as for the standard SQLEncrypted authenticator described above. Note though that there is no 'encryption\_salt' for MD5, and be sure to use `sql_md5.rb` in place of `sql_encrypted.rb`.