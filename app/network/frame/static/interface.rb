module RuneRb::Net::Static
  # A frame sent to display the interface with the given id to a client
  class InterfaceFrame < RuneRb::Net::MetaFrame

    # Called when a new InterfaceFrame is created.
    def initialize(id)
      @id = id
      super(97)
      parse
    end

    private

    # Writes the interface id to the payload.
    def parse
      write_short(@id)
    end
  end
end