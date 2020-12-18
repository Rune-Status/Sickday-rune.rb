module RuneRb::Network::FrameReader
  using RuneRb::System::Patches::IntegerOverrides
  using RuneRb::System::Patches::StringOverrides

  private

  # Decodes a frame using the Session#cipher.
  # @param frame [RuneRb::Networkwork::Frame] the frame to decode.
  def decode_frame(frame)
    raise 'Invalid cipher for Session!' unless @cipher

    frame.header[:op_code] -= @cipher[:decryptor].next_value & 0xFF
    frame.header[:op_code] = frame.header[:op_code] & 0xFF
    frame.header[:length] = RuneRb::Network::FRAME_SIZES[frame.header[:op_code]]
    log "Decoding frame: #{frame.inspect}" if RuneRb::GLOBAL[:RRB_DEBUG]
    frame
  end

  # Reads the next parseable frame from Session#in, then attempts to handle the frame accordingly.
  def next_frame
      @current = RuneRb::Network::Frame.new(@socket.read_nonblock(1).next_byte)
      @current = decode_frame(@current)
      @current.header[:length] = @socket.read_nonblock(1).next_byte if @current.header[:length] == -1
      @current.read(@socket, @current.header[:length])
      parse_frame(@current)
  rescue IO::EAGAINWaitReadable
    nil
  rescue EOFError
    err 'Reached EOF!' if RuneRb::GLOBAL[:RRB_DEBUG]
    disconnect
  end

  # Processes the frame parameter
  # @param frame [RuneRb::Networkwork::StaticFrame] the frame to handle
  def parse_frame(frame)
    case frame.header[:op_code]
    when 0
      log 'Received Heartbeat!' if RuneRb::GLOBAL[:RRB_DEBUG]
    when 45 # MouseMovement
      log 'Received Mouse Movement' if RuneRb::GLOBAL[:RRB_DEBUG]
    when 3 # Window Focus
      focused = frame.read_byte(false)
      log RuneRb::COL.blue("Client Focus: #{RuneRb::COL.cyan(focused.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::GLOBAL[:RRB_DEBUG]
    when 4 # Chat.
      @context.update(:message, message: RuneRb::Game::Entity::Message.from_frame(frame))
    when 122 # First Item Option.
      @context.parse_option(:first_option, frame)
    when 41 # Second Item option.
      @context.parse_option(:second_option, frame)
    when 16 # Third Item Option.
      @context.parse_option(:third_option, frame)
    when 75 # Forth Item Option.
      @context.parse_option(:fourth_option, frame)
    when 87 # Fifth Item Option.
      @context.parse_option(:fifth_option, frame)
    when 145 # First Item Action.
      @context.parse_action(:first_action, frame)
    when 214 # Switch Item
      @context.parse_action(:switch_item,  frame)
    when 241 # Mouse Click
      @context.parse_action(:mouse_click, frame)
    when 77, 78, 165, 189, 210, 226, 121 # Ping frame
      log "Got ping frame #{frame.header[:op_code]}" if RuneRb::GLOBAL[:RRB_DEBUG]
    when 86
      roll = frame.read_short(false, :STD, :LITTLE)
      yaw = frame.read_short(false, :STD, :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::GLOBAL[:RRB_DEBUG]
    when 101 # Character Design
      @context.appearance.from_frame(frame)
      @context.update(:state)
    when 103
      @context.parse_command(frame)
    when 185 # Button Click
      @context.parse_button(frame)
    when 202
      log 'Received Idle Frame!' if RuneRb::GLOBAL[:RRB_DEBUG]
    when 248, 164, 98 # Movement
      @context.parse_movement(frame)
    else err "Unhandled frame: #{frame.inspect}"
    end
    # Parse the next frame
    next_frame
  rescue StandardError => e
    err 'An error occurred while parsing frame!', e
    err frame.inspect
    puts e.backtrace
  end
end