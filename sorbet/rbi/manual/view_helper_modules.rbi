# typed: strict

# View-helper modules from gems that ship no RBIs, referenced by the
# generated helper RBIs. Empty declarations: the app only needs them to
# resolve, never to call them through these names.
module Turbo
  module StreamsHelper
  end

  module IncludesHelper
  end

  module FramesHelper
  end

  module DriveHelper
  end

  module Streams
    module ActionHelper
    end
  end
end

module Importmap
  module ImportmapTagsHelper
  end
end

module ChobbleForms
  module Helpers
  end
end

module ActionView
  class Base
  end

  module Helpers
    module CaptureHelper
    end

    module NumberHelper
    end

    module OutputSafetyHelper
    end

    module TagHelper
    end
  end
end

module ActionController
  class Base
    module HelperMethods
    end
  end
end
