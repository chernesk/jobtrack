class HomeController < ApplicationController
  def index
    render inertia: "Home/Index", props: {
      user: { email_address: Current.user.email_address }
    }
  end
end
