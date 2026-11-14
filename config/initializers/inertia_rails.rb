InertiaRails.configure do |config|
  # Always send an `errors` hash so pages can read `errors.field` without nil checks.
  config.always_include_errors_hash = true

  # @inertiajs/react v3 reads the initial page from a <script type="application/json">
  # element; the gem's default (a data-page attribute) is the v2 client's format.
  config.use_script_element_for_initial_page = true
end
