module HttpApiTools
  class HttpApiToolsRailtie < Rails::Railtie
    config.after_initialize do
      HttpApiTools::SerializerLoader.preload
    end
  end
end