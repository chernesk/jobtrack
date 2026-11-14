InertiaRails.configure do |config|
  # Always send an `errors` hash so pages can read `errors.field` without nil checks.
  config.always_include_errors_hash = true
end
