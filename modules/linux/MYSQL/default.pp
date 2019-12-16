include stdlib

class { 'mysql::server':
  root_password           => 'password',
  remove_default_accounts => true,
  restart                 => true,
  override_options        => $override_options
}

mysql::db { 'mydb':
  user     => 'myuser',
  password => 'mypass',
  host     => 'localhost',
  grant    => ['SELECT', 'UPDATE'],
}

class { 'mysql::client':}
