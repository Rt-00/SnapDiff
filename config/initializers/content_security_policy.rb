# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    # TailwindCSS 4.x applies inline styles — unsafe-inline required until
    # a nonce-based approach is configured for the CSS engine.
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
