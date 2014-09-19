require File.expand_path('../helper', __FILE__)

class TestRemoteSyslogLogger < Test::Unit::TestCase
  def setup
    @server_port = rand(50000) + 1024
  end

  def teardown
    if @socket
      @socket.close
    elsif $server
      $server.close
    end
  end

  def syslog_logger_of_type(type, options={})
    RemoteSyslogLogger.new('127.0.0.1', @server_port, options.merge(protocol: type))
  end

  def test_default_is_udp_logger
    assert RemoteSyslogLogger.new('127.0.0.1', 1234).instance_variable_get(:@logdev).instance_variable_get(:@dev).class == RemoteSyslogLogger::UdpSender
  end

  def test_udp_logger
    setup_udp_listener
    test_logging_single_line syslog_logger_of_type :udp
  end

  def test_udp_logger_multiline
    setup_udp_listener
    test_logging_multi_line syslog_logger_of_type :udp
  end

  def test_tcp_logger
    setup_tcp_listener
    test_logging_single_line syslog_logger_of_type :tcp
  end

  def test_tcp_logger_multiline
    setup_tcp_listener
    test_logging_multi_line syslog_logger_of_type :tcp
  end

  def test_tcp_ssl_logger
    setup_tcp_listener_ssl
            p 'test'
    test_logging_single_line syslog_logger_of_type(:tcp_ssl, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    p 'done'
  end

  def test_tcp_ssl_logger_multiline
    setup_tcp_listener_ssl
    test_logging_multi_line syslog_logger_of_type(:tcp_ssl, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  end

  private

  def setup_udp_listener
    @socket = UDPSocket.new
    @socket.bind('127.0.0.1', @server_port)
  end

  def setup_tcp_listener(ssl=false)
    $received_data = []

    Thread.new do
      $server = TCPServer.new '127.0.0.1', @server_port

      if ssl
        context = OpenSSL::SSL::SSLContext.new
        context.cert = OpenSSL::X509::Certificate.new(File.read(File.expand_path('../test.crt', __FILE__)))
        context.key = OpenSSL::PKey::RSA.new(File.read(File.expand_path('../test.key', __FILE__)))

        $server = OpenSSL::SSL::SSLServer.new($server, context)
      end

      p "Starting TCP server #{$server.inspect}"
      Thread.start($server.accept) do |client|
        $received_data = client.readlines
        puts "Received messages [#{$received_data}]"
        client.close
      end
    end
    # let the server start up
    sleep 0.2
  end

  def setup_tcp_listener_ssl
    setup_tcp_listener true
  end

  def test_logging_single_line(logger)
    logger.info "This is a test"
    # close the logger so any tcp sends are flushed
    logger.close

    message, addr = *receive_data
    assert_match /This is a test/, message
  end

  def test_logging_multi_line(logger)
    logger.info "This is a test\nThis is the second line"
    # close the logger so any tcp sends are flushed
    logger.close

    message, addr = *receive_data
    assert_match /This is a test/, message

    message, addr = *receive_data
    assert_match /This is the second line/, message
  end

  # get a message of data from the socket
  def receive_data
    if @socket
      # udp receive
      @socket.recvfrom(1024)
    else
      # tcp receive
      sleep 0.1
      if $received_data
        $received_data.shift
      else
        fail 'no data'
      end
    end
  end
end