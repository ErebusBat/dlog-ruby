module Dsl
  class Loader
    def load_file(path)
      path = Pathname.new(path)
      path = APP_PATH.join(path) if path.relative?
      raise "Could not find #{path} or it is empty" unless path.size?

      dsl = path.read
      cfg = Config.new
      cfg.instance_eval dsl, path.to_s, 1
      cfg
    end
  end
end
