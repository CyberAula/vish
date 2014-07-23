DetectLanguage.configure do |config|
	config.api_key = Vish::Application.config.APP_CONFIG["languageDetectionAPIKEY"]
end