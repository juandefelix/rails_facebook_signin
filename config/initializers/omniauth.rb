Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '474596766020435', '053350cb1ca0424b4a711dfbb9819291'
end