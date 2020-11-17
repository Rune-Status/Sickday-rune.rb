module RuneRb::Database::Connection
  LEGACY = Sequel.postgres('runerb_legacy',
                           user: 'pat',
                           pass: 'maxwell1031',
                           host: 'localhost')
end