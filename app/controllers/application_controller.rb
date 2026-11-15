class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Props available to every Inertia page (typed as SharedProps in app/frontend/types.ts).
  inertia_share auth: -> { { user: Current.user && { email_address: Current.user.email_address } } },
    flash: -> { flash.to_hash.slice("notice", "alert") }
end
