# Active Record encryption (used for the saved ntfy token) needs keys. Rails would read
# them from encrypted credentials, but this app keeps no credentials file: it generates
# its own signing secret on first start and stores it in the data volume (see
# config/environments/production.rb). So the encryption keys are derived from that
# same secret, which means there is nothing extra to configure or back up.
#
# If the secret is ever lost, a saved token can no longer be read. `Setting` treats
# that as "no token saved", and you enter it again.
encryption = Rails.application.config.active_record.encryption
generator = Rails.application.key_generator

encryption.primary_key = generator.generate_key("active_record_encryption.primary_key", 32).unpack1("H*")
encryption.deterministic_key = generator.generate_key("active_record_encryption.deterministic_key", 32).unpack1("H*")
encryption.key_derivation_salt = generator.generate_key("active_record_encryption.key_derivation_salt", 32).unpack1("H*")
