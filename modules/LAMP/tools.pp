class tools
  {
    package
      {
        "curl":
          ensure  => present,
          require => Exec['apt-get update']
      }
  }