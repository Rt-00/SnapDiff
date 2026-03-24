class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  layout :choose_layout

  private

  def choose_layout
    devise_controller? ? "auth" : "application"
  end

  # Pagy helper: paginate an ActiveRecord relation
  def paginate(collection, limit: 20)
    page = (params[:page] || 1).to_i
    pagy = Pagy::Offset.new(count: collection.count, page: page, limit: limit)
    [ pagy, pagy.records(collection) ]
  end
end
